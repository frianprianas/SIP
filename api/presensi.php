<?php
// Catat_presensi.php
// Endpoint untuk pencatatan kehadiran dari ESP32 (menerima JSON POST) dan mengirim notifikasi

// --- PERBAIKAN: Tekan semua pesan kesalahan PHP untuk memastikan output JSON murni ---
error_reporting(E_ALL);
ini_set('display_errors', '1'); // Aktifkan ini untuk debugging, nonaktifkan saat produksi

// Set zona waktu ke Asia/Jakarta (WIB)
date_default_timezone_set('Asia/Jakarta');

// Include file koneksi database
require_once 'koneksi.php';

// Include Composer Autoload untuk PHPMailer, Google Client Library
require_once __DIR__ . '/vendor/autoload.php';

use PHPMailer\PHPMailer\PHPMailer;
use PHPMailer\PHPMailer\SMTP;
use PHPMailer\PHPMailer\Exception as PHPMailerException;

// Atur header untuk respons JSON
header('Content-Type: application/json');

// Izinkan CORS (penting untuk pengembangan dari berbagai sumber)
if (isset($_SERVER['HTTP_ORIGIN'])) {
    header("Access-Control-Allow-Origin: {$_SERVER['HTTP_ORIGIN']}");
    header('Access-Control-Allow-Credentials: true');
    header('Access-Control-Max-Age: 86400');
}
if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    if (isset($_SERVER['HTTP_ACCESS_CONTROL_REQUEST_METHOD']))
        header("Access-Control-Allow-Methods: POST, OPTIONS");
    if (isset($_SERVER['HTTP_ACCESS_CONTROL_REQUEST_HEADERS']))
        header("Access-Control-Allow-Headers: {$_SERVER['HTTP_ACCESS_CONTROL_REQUEST_HEADERS']}");
    exit(0);
}

// --- FUNGSI BARU: Untuk menghasilkan respons JSON yang konsisten ---
function respondWithJson($status, $message, $data = []) {
    global $conn;
    $response = ["status" => $status, "message" => $message];
    if (!empty($data)) {
        $response["data"] = $data;
    }
    echo json_encode($response);
    if ($conn && $conn->ping()) {
        $conn->close();
    }
    exit();
}

// --- Konfigurasi Fonnte API ---
$fonnteToken = 'qqPvSZwfEaApnVPykaGX'; // Ganti dengan TOKEN FONNTE Anda yang sebenarnya!
$fonnteApiUrl = 'https://api.fonnte.com/send';

// --- Konfigurasi Email SMTP (Titan Mail) ---
$mailHost = 'mail.smk.baktinusantara666.sch.id';
$mailPort = 465;
$mailUsername = 'no-replay@smk.baktinusantara666.sch.id';
$mailPassword = 'on5laught';
$mailFromEmail = 'no-replay@smk.baktinusantara666.sch.id';
$mailFromName = 'Sistem Informasi Presensi SMK BN 666';


// --- Tangkap data POST JSON dan validasi dengan benar ---
$input = file_get_contents('php://input');

if (empty($input)) {
    respondWithJson("ERROR", "Body permintaan POST kosong. Silakan kirim data JSON.");
}

$data_json = json_decode($input, true);

if (json_last_error() !== JSON_ERROR_NONE) {
    error_log("JSON Decode Error: " . json_last_error_msg() . " | Input: " . $input);
    respondWithJson("ERROR", "Input JSON tidak valid. " . json_last_error_msg());
}


$rfid_uid = isset($data_json['rfid_uid']) ? $data_json['rfid_uid'] : (isset($_POST['rfid_uid']) ? $_POST['rfid_uid'] : '');
$status_presensi_req = isset($data_json['status']) ? $data_json['status'] : (isset($_POST['status']) ? $_POST['status'] : '');

if (empty($rfid_uid)) {
    respondWithJson("ERROR", "Parameter 'rfid_uid' tidak ditemukan atau kosong.");
}
if (empty($status_presensi_req) || ($status_presensi_req != 'MASUK' && $status_presensi_req != 'PULANG')) {
    respondWithJson("ERROR", "Parameter 'status' tidak valid. Harus 'MASUK' atau 'PULANG'.");
}

$rfid_uid_sanitized = $rfid_uid;
$status_sanitized = $status_presensi_req;

// --- 1. Cari siswa berdasarkan RFID UID ---
$stmt_siswa = $conn->prepare("SELECT nis, nama, kelas, email FROM siswa WHERE rfid = ?");
$stmt_siswa->bind_param("s", $rfid_uid_sanitized);
$stmt_siswa->execute();
$result_siswa = $stmt_siswa->get_result();

if ($result_siswa === FALSE) {
    error_log("Kesalahan query siswa: " . $conn->error);
    respondWithJson("ERROR", "Kesalahan sistem saat mencari siswa.");
}

$row_siswa = $result_siswa->fetch_assoc();

if (!$row_siswa) {
    respondWithJson("ERROR", "RFID UID '" . $rfid_uid . "' tidak ditemukan di database siswa.");
}

$nis = $row_siswa['nis'];
$nama = $row_siswa['nama'];
$kelas = $row_siswa['kelas'];
$email_siswa = $row_siswa['email'];
$stmt_siswa->close();

// --- 2. Dapatkan Jadwal Hari Ini ---
$jadwal_masuk = '00:00:00';
$jadwal_pulang = '00:00:00';
$hari_sekarang_angka = date('N');

$stmt_jadwal = $conn->prepare("SELECT jam_masuk, jam_pulang FROM jadwal WHERE hari_ke = ? LIMIT 1");
$stmt_jadwal->bind_param("i", $hari_sekarang_angka);
$stmt_jadwal->execute();
$result_jadwal = $stmt_jadwal->get_result();

if ($result_jadwal === FALSE) {
    error_log("Kesalahan query jadwal: " . $conn->error);
} else if ($result_jadwal->num_rows > 0) {
    $row_jadwal = $result_jadwal->fetch_assoc();
    $jadwal_masuk = $row_jadwal['jam_masuk'];
    $jadwal_pulang = $row_jadwal['jam_pulang'];
} else {
    error_log("Jadwal untuk hari ke-" . $hari_sekarang_angka . " tidak ditemukan.");
}
$stmt_jadwal->close();

// --- 3. Logika Pencatatan & Validasi Presensi ---
$server_datetime = date('Y-m-d H:i:s');
$current_date = date('Y-m-d');
$current_time_only = date('H:i:s');
$keterangan = "Normal";

$pesan_error = "";
$pesan_sukses = "";
$status_final_dicatat = "";
$last_inserted_id = null;

$stmt_current_day_status = $conn->prepare("SELECT status, waktu_tap FROM kehadiran WHERE nis = ? AND DATE(waktu_tap) = ? ORDER BY waktu_tap DESC LIMIT 1");
$stmt_current_day_status->bind_param("ss", $nis, $current_date);
$stmt_current_day_status->execute();
$result_current_day_status = $stmt_current_day_status->get_result();

$last_recorded_status = null;
$last_recorded_time = null;
if ($result_current_day_status && $result_current_day_status->num_rows > 0) {
    $row_last = $result_current_day_status->fetch_assoc();
    $last_recorded_status = $row_last['status'];
    $last_recorded_time = $row_last['waktu_tap'];
}
$stmt_current_day_status->close();

if ($status_sanitized == 'MASUK') {
    if ($last_recorded_status == 'MASUK') {
        $pesan_error = "Anda sudah absen MASUK hari ini pada " . date('H:i', strtotime($last_recorded_time)) . ". Silakan absen PULANG.";
    } elseif ($last_recorded_status == 'PULANG') {
        $pesan_error = "Anda sudah absen MASUK dan PULANG hari ini. Tidak bisa absen MASUK lagi.";
    } else {
        $status_final_dicatat = "MASUK";
        if ($current_time_only > $jadwal_masuk) {
            $keterangan = "Terlambat";
        } else {
            $keterangan = "Tepat Waktu";
        }
        $pesan_sukses = "Absen Masuk Berhasil! Status: " . $keterangan;

        // Gunakan CONVERT_TZ agar konsisten dengan presensi_guru.php
        $stmt_insert = $conn->prepare("INSERT INTO kehadiran (nis, rfid_uid, waktu_tap, status, keterangan) VALUES (?, ?, CONVERT_TZ(NOW(), 'UTC', '+07:00'), ?, ?)");
        $stmt_insert->bind_param("ssss", $nis, $rfid_uid_sanitized, $status_final_dicatat, $keterangan);
        if (!$stmt_insert->execute()) {
            $pesan_error = "Gagal mencatat kehadiran Masuk: " . $stmt_insert->error;
            error_log($pesan_error);
        } else {
            $last_inserted_id = $conn->insert_id;
        }
        $stmt_insert->close();
    }
} elseif ($status_sanitized == 'PULANG') {
    if ($last_recorded_status == 'PULANG') {
        $pesan_error = "Anda sudah absen PULANG hari ini pada " . date('H:i', strtotime($last_recorded_time)) . ". Tidak bisa absen PULANG lagi.";
    } elseif ($last_recorded_status != 'MASUK') {
        $pesan_error = "Anda harus absen MASUK terlebih dahulu hari ini.";
    } else {
        $status_final_dicatat = "PULANG";
        if ($current_time_only < $jadwal_pulang) {
            $keterangan = "Pulang Cepat";
        } else {
            $keterangan = "Tepat Waktu";
        }
        $pesan_sukses = "Absen Pulang Berhasil! Status: " . $keterangan;

        // Gunakan CONVERT_TZ agar konsisten dengan presensi_guru.php
        $stmt_insert = $conn->prepare("INSERT INTO kehadiran (nis, rfid_uid, waktu_tap, status, keterangan) VALUES (?, ?, CONVERT_TZ(NOW(), 'UTC', '+07:00'), ?, ?)");
        $stmt_insert->bind_param("ssss", $nis, $rfid_uid_sanitized, $status_final_dicatat, $keterangan);
        if (!$stmt_insert->execute()) {
            $pesan_error = "Gagal mencatat kehadiran Pulang: " . $stmt_insert->error;
            error_log($pesan_error);
        } else {
            $last_inserted_id = $conn->insert_id;
        }
        $stmt_insert->close();
    }
}

// --- Respon berdasarkan hasil operasi & Integrasi WA & Email & FCM ---
if (!empty($pesan_error)) {
    respondWithJson("ERROR", $pesan_error, [
        "nis" => isset($nis) ? $nis : null,
        "nama" => isset($nama) ? $nama : null,
        "kelas" => isset($kelas) ? $kelas : null,
        "status_kehadiran" => $status_sanitized,
        "server_time" => $server_datetime,
        "jadwal_masuk" => $jadwal_masuk,
        "jadwal_pulang" => $jadwal_pulang
    ]);
} else if ($last_inserted_id !== null) {
    
    // --- Kirim Notifikasi WA (Fonnte) ---
    $no_wa_ortu = '';
    $stmt_get_wa = $conn->prepare("SELECT no_wa FROM nomor_wa WHERE nis = ?");
    $stmt_get_wa->bind_param("s", $nis);
    $stmt_get_wa->execute();
    $result_get_wa = $stmt_get_wa->get_result();

    if ($result_get_wa->num_rows > 0) {
        $row_wa = $result_get_wa->fetch_assoc();
        $no_wa_ortu = $row_wa['no_wa'];

        if (substr($no_wa_ortu, 0, 1) === '0') {
            $no_wa_ortu = '62' . substr($no_wa_ortu, 1);
        } else if (substr($no_wa_ortu, 0, 2) !== '62' && strlen($no_wa_ortu) > 5) {
            $no_wa_ortu = '62' . $no_wa_ortu;
        }
        
        $status_indo = ($status_final_dicatat == 'MASUK') ? 'masuk' : 'pulang';
        $pesan_wa = "Halo, orang tua/wali dari ananda $nama ($nis). Kami memberitahukan bahwa ananda $nama telah melakukan presensi $status_indo pada pukul $current_time_only WIB. Status: $keterangan. Terima kasih.";

        // Payload data untuk API Fonnte
        $payload_fonnte = array(
            'target' => $no_wa_ortu,
            'message' => $pesan_wa, 
            'countryCode' => '62',
        );

        // Header yang diperlukan
        $headers_fonnte = [
            'Authorization: ' . $fonnteToken,
            'Content-Type: application/x-www-form-urlencoded'
        ];

        $curl = curl_init();
        curl_setopt_array($curl, array(
            CURLOPT_URL => $fonnteApiUrl,
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_ENCODING => '',
            CURLOPT_MAXREDIRS => 10,
            CURLOPT_TIMEOUT => 30,
            CURLOPT_FOLLOWLOCATION => true,
            CURLOPT_HTTP_VERSION => CURL_HTTP_VERSION_1_1,
            CURLOPT_CUSTOMREQUEST => 'POST',
            CURLOPT_POSTFIELDS => http_build_query($payload_fonnte),
            CURLOPT_HTTPHEADER => $headers_fonnte,
        ));

        $response_fonnte = curl_exec($curl);
        $error_fonnte = '';
        if (curl_errno($curl)) {
            $error_fonnte = curl_error($curl);
        }
        curl_close($curl);

        if (!empty($error_fonnte)) {
            error_log("Fonnte API Error for NIS $nis: " . $error_fonnte);
        } else {
            error_log("Fonnte API Response for NIS $nis: " . $response_fonnte);
        }

    } else {
        error_log("Nomor WA orang tua tidak ditemukan untuk NIS: " . $nis);
    }
    $stmt_get_wa->close();

    // --- Kirim Notifikasi Email ---
    if (!empty($email_siswa) && filter_var($email_siswa, FILTER_VALIDATE_EMAIL)) {
        $mail = new PHPMailer(true);

        try {
            $mail->isSMTP();                                            
            $mail->Host       = $mailHost;                              
            $mail->SMTPAuth   = true;                                   
            $mail->Username   = $mailUsername;                          
            $mail->Password   = $mailPassword;                          
            $mail->SMTPSecure = PHPMailer::ENCRYPTION_SMTPS;            
            $mail->Port       = $mailPort;                              

            $mail->setFrom($mailFromEmail, $mailFromName);
            $mail->addAddress($email_siswa, $nama);                     

            $mail->isHTML(true);                                        
            $mail->Subject = 'Notifikasi Presensi ' . $status_final_dicatat . ' Siswa: ' . $nama;
            
            $body_email = "
                <p>Yth. Saudara/i <strong>$nama</strong>,</p>
                <p>Kami memberitahukan bahwa Anda telah berhasil melakukan presensi <strong>" . strtoupper($status_final_dicatat) . "</strong> pada:</p>
                <ul>
                    <li><strong>Tanggal:</strong> " . date('d-m-Y', strtotime($server_datetime)) . "</li>
                    <li><strong>Waktu:</strong> " . $current_time_only . " WIB</li>
                    <li><strong>Status Presensi:</strong> " . strtoupper($status_final_dicatat) . "</li>
                    <li><strong>Keterangan:</strong> " . $keterangan . "</li>
                </ul>
                <p>Terima kasih atas kedisiplinan Anda.</p>
                <br>
                <p>Hormat kami,</p>
                <p><strong>Sistem Presensi SMK BN 666</strong></p>
                <p><small>Email ini dikirim secara otomatis, mohon tidak membalas.</small></p>
            ";
            $mail->Body    = $body_email;
            $mail->AltBody = "Yth. Saudara/i $nama, Anda telah berhasil melakukan presensi " . strtoupper($status_final_dicatat) . " pada Tanggal: " . date('d-m-Y', strtotime($server_datetime)) . " Waktu: " . $current_time_only . " WIB. Status: $keterangan. Terima kasih. Sistem Presensi SMK BN 666";

            $mail->send(); 
            error_log("Email notifikasi berhasil dikirim ke " . $email_siswa);
        } catch (PHPMailerException $e) {
            error_log("Gagal mengirim email notifikasi ke " . $email_siswa . ". Mailer Error: {$mail->ErrorInfo}");
        }
    } else {
    error_log("Email siswa tidak valid atau tidak ditemukan untuk NIS: " . $nis);
    }
    
    // --- Respons SUKSES FINAL ---
    respondWithJson("SUCCESS", $pesan_sukses, [
        "id_kehadiran" => $last_inserted_id,
        "nis" => $nis,
        "nama" => $nama,
        "kelas" => $kelas,
        "status_kehadiran" => $status_final_dicatat,
        "server_time" => $server_datetime,
        "jadwal_masuk" => $jadwal_masuk,
        "jadwal_pulang" => $jadwal_pulang,
        "keterangan" => $keterangan
    ]);
} else { 
     respondWithJson("ERROR", "Terjadi kesalahan tidak terduga dalam pencatatan atau validasi.");
}

// Tutup koneksi database
$conn->close();
