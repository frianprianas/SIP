<?php
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

header('Content-Type: application/json');
// --- PERBAIKAN: Tekan semua pesan kesalahan PHP untuk memastikan output JSON murni ---
error_reporting(E_ALL);
ini_set('display_errors', '1'); // Aktifkan ini untuk debugging, nonaktifkan saat produksi

// Set zona waktu ke Asia/Jakarta (WIB)
date_default_timezone_set('Asia/Jakarta');

// Include file koneksi database
require_once 'koneksi.php';

// Include Composer Autoload untuk PHPMailer
require_once __DIR__ . '/vendor/autoload.php';

use PHPMailer\PHPMailer\PHPMailer;
use PHPMailer\PHPMailer\Exception;

// --- Konfigurasi Fonnte API ---
$fonnteToken = 'qqPvSZwfEaApnVPykaGX';
$fonnteApiUrl = 'https://api.fonnte.com/send';

// --- Konfigurasi Email SMTP (Titan Mail) ---
// --- Konfigurasi Email SMTP (Titan Mail) ---
$mailHost = 'mail.smk.baktinusantara666.sch.id';
$mailPort = 465;
$mailUsername = 'no-replay@smk.baktinusantara666.sch.id';
$mailPassword = 'on5laught';
$mailFromEmail = 'no-replay@smk.baktinusantara666.sch.id';
$mailFromName = 'Sistem Informasi Presensi SMK BN 666';

// ==== FUNGSI KIRIM WA ====
function kirimWA($nomor, $pesan){
    global $fonnteApiUrl, $fonnteToken;

    $data = [
        "target" => $nomor,
        "message" => $pesan
    ];

    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, $fonnteApiUrl);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);
    curl_setopt($ch, CURLOPT_POST, 1);
    curl_setopt($ch, CURLOPT_POSTFIELDS, $data);
    curl_setopt($ch, CURLOPT_HTTPHEADER, [
        "Authorization: $fonnteToken"
    ]);
    $result = curl_exec($ch);
    curl_close($ch);

    return $result;
}

// ==== FUNGSI KIRIM EMAIL ====
function kirimEmail($to, $subject, $message){
    global $mailHost, $mailPort, $mailUsername, $mailPassword, $mailFromEmail, $mailFromName;

    $mail = new PHPMailer(true);
    try {
        $mail->isSMTP();
        $mail->Host       = $mailHost;
        $mail->SMTPAuth   = true;
        $mail->Username   = $mailUsername;
        $mail->Password   = $mailPassword;
        $mail->SMTPSecure = 'ssl';
        $mail->Port       = $mailPort;

        $mail->setFrom($mailFromEmail, $mailFromName);
        $mail->addAddress($to);

        $mail->isHTML(true);
        $mail->Subject = $subject;
        $mail->Body    = nl2br($message);

        $mail->send();
        return true;
    } catch (Exception $e) {
        return false;
    }
}

// ==== INPUT DARI ESP32 ====
$role     = $_POST['role'] ?? '';
$nis      = $_POST['nis'] ?? '';
$nipy     = $_POST['nipy'] ?? '';
$password = $_POST['password'] ?? '';
$mode     = strtoupper($_POST['mode'] ?? 'MASUK'); 
$tgl      = date("Y-m-d");
$jam      = date("H:i:s");
$hari     = date("N"); // 1=Senin, dst

$response = ["status" => "error", "msg" => "Data tidak valid"];

/* ---------------- S I S W A ---------------- */
if ($role == "siswa" && $nis != "" && $password != "") {
    $stmt = $conn->prepare("SELECT * FROM siswa WHERE nis=?");
    $stmt->bind_param("s", $nis);
    $stmt->execute();
    $res = $stmt->get_result();

    if ($res->num_rows > 0) {
        $row = $res->fetch_assoc();

        // cek password (hybrid: hash atau plaintext)
        if (password_verify($password, $row['password']) || $password === $row['password']) {
            // Validasi presensi siswa hanya bisa 1x MASUK dan 1x PULANG per hari
            $stmt = $conn->prepare("SELECT status FROM kehadiran WHERE nis=? AND DATE(waktu_tap)=?");
            $stmt->bind_param("ss", $nis, $tgl);
            $stmt->execute();
            $resPresensi = $stmt->get_result();
            $masuk = false;
            $pulang = false;
            while ($rowPresensi = $resPresensi->fetch_assoc()) {
                if ($rowPresensi['status'] == 'MASUK') $masuk = true;
                if ($rowPresensi['status'] == 'PULANG') $pulang = true;
            }
            $stmt->close();

            if ($mode == 'MASUK') {
                if ($masuk) {
                    $response = ["status"=>"fail","msg"=>"Sudah absen MASUK hari ini"];
                } else {
                    // ambil jadwal
                    $jadwal = $conn->query("SELECT * FROM jadwal WHERE hari_ke='$hari'")->fetch_assoc();
                    $keterangan = "";
                    if ($jam <= $jadwal['jam_masuk']) $keterangan = "Tepat Waktu";
                    else $keterangan = "Terlambat";
                    $waktu_tap = $tgl . " " . $jam;
                    $rfid_uid = "KEYPAD";
                    $keterangan = $keterangan ?: "KEYPAD";
                    $stmt2 = $conn->prepare("INSERT INTO kehadiran (nis, rfid_uid, waktu_tap, status, keterangan) VALUES (?,?,?,?,?)");
                    $stmt2->bind_param("sssss", $nis, $rfid_uid, $waktu_tap, $mode, $keterangan);
                    $stmt2->execute();
                    // notifikasi
                    $waRow = $conn->query("SELECT no_wa FROM nomor_wa WHERE nis='$nis'")->fetch_assoc();
                    $pesan = "📚 PRESENSI SISWA\n".
                             "Nama : ".$row['nama']."\n".
                             "NIS  : $nis\n".
                             "Tanggal : $tgl\n".
                             "Jam : $jam\n".
                             "Status : $mode\n".
                             "Keterangan : $keterangan";
                    if ($waRow) kirimWA($waRow['no_wa'], $pesan);
                    if (!empty($row['email'])) kirimEmail($row['email'], "Presensi Siswa - $tgl", $pesan);
                    $response = [
                        "status" => "ok",
                        "role" => "siswa",
                        "mode" => $mode,
                        "ket" => $keterangan,
                        "nis" => $nis,
                        "nama" => $row['nama']
                    ];
                }
            } elseif ($mode == 'PULANG') {
                if (!$masuk) {
                    $response = ["status"=>"fail","msg"=>"Belum absen MASUK hari ini"];
                } elseif ($pulang) {
                    $response = ["status"=>"fail","msg"=>"Sudah absen PULANG hari ini"];
                } else {
                    // ambil jadwal
                    $jadwal = $conn->query("SELECT * FROM jadwal WHERE hari_ke='$hari'")->fetch_assoc();
                    $keterangan = "";
                    if ($jam >= $jadwal['jam_pulang']) $keterangan = "Pulang Normal";
                    else $keterangan = "Pulang Cepat";
                    $waktu_tap = $tgl . " " . $jam;
                    $rfid_uid = "KEYPAD";
                    $keterangan = $keterangan ?: "KEYPAD";
                    $stmt2 = $conn->prepare("INSERT INTO kehadiran (nis, rfid_uid, waktu_tap, status, keterangan) VALUES (?,?,?,?,?)");
                    $stmt2->bind_param("sssss", $nis, $rfid_uid, $waktu_tap, $mode, $keterangan);
                    $stmt2->execute();
                    // notifikasi
                    $waRow = $conn->query("SELECT no_wa FROM nomor_wa WHERE nis='$nis'")->fetch_assoc();
                    $pesan = "📚 PRESENSI SISWA\n".
                             "Nama : ".$row['nama']."\n".
                             "NIS  : $nis\n".
                             "Tanggal : $tgl\n".
                             "Jam : $jam\n".
                             "Status : $mode\n".
                             "Keterangan : $keterangan";
                    if ($waRow) kirimWA($waRow['no_wa'], $pesan);
                    if (!empty($row['email'])) kirimEmail($row['email'], "Presensi Siswa - $tgl", $pesan);
                    $response = [
                        "status" => "ok",
                        "role" => "siswa",
                        "mode" => $mode,
                        "ket" => $keterangan,
                        "nis" => $nis,
                        "nama" => $row['nama']
                    ];
                }
            }
        } else {
            $response = ["status"=>"fail","msg"=>"Password salah"];
        }
    } else {
        $response = ["status"=>"fail","msg"=>"NIS tidak ditemukan"];
    }
}
/* ---------------- G U R U ---------------- */
elseif ($role == "guru" && $nipy != "" && $password != "") {
    $stmt = $conn->prepare("SELECT * FROM guru WHERE nipy=?");
    $stmt->bind_param("s", $nipy);
    $stmt->execute();
    $res = $stmt->get_result();

    if ($res->num_rows > 0) {
        $row = $res->fetch_assoc();

        // cek password (hybrid: hash atau plaintext)
        if (password_verify($password, $row['password']) || $password === $row['password']) {
            // Validasi presensi guru hanya bisa 1x MASUK dan 1x PULANG per hari
            $stmt = $conn->prepare("SELECT status FROM kehadiran_guru WHERE nipy=? AND DATE(waktu_tap)=?");
            $stmt->bind_param("ss", $nipy, $tgl);
            $stmt->execute();
            $resPresensi = $stmt->get_result();
            $masuk = false;
            $pulang = false;
            while ($rowPresensi = $resPresensi->fetch_assoc()) {
                if ($rowPresensi['status'] == 'MASUK') $masuk = true;
                if ($rowPresensi['status'] == 'PULANG') $pulang = true;
            }
            $stmt->close();

            if ($mode == 'MASUK') {
                if ($masuk) {
                    $response = ["status"=>"fail","msg"=>"Sudah absen MASUK hari ini"];
                } else {
                    $waktu_tap_guru = $tgl . " " . $jam;
                    $rfid_uid_guru = "KEYPAD";
                    $keterangan_guru = "KEYPAD";
                    $stmt2 = $conn->prepare("INSERT INTO kehadiran_guru (nipy, rfid_uid, waktu_tap, status, keterangan) VALUES (?,?,?,?,?)");
                    $stmt2->bind_param("sssss", $nipy, $rfid_uid_guru, $waktu_tap_guru, $mode, $keterangan_guru);
                    $stmt2->execute();
                    // notifikasi
                    $waRow = $conn->query("SELECT no_wa FROM nomor_wa_guru WHERE nipy='$nipy'")->fetch_assoc();
                    $pesan = "👨‍🏫 PRESENSI GURU\n".
                             "Nama : ".$row['nama']."\n".
                             "NIPY : $nipy\n".
                             "Tanggal : $tgl\n".
                             "Jam : $jam\n".
                             "Status : $mode";
                    if ($waRow) kirimWA($waRow['no_wa'], $pesan);
                    if (!empty($row['email'])) kirimEmail($row['email'], "Presensi Guru - $tgl", $pesan);
                    $response = [
                        "status" => "ok",
                        "role" => "guru",
                        "mode" => $mode,
                        "nipy" => $nipy,
                        "nama" => $row['nama']
                    ];
                }
            } elseif ($mode == 'PULANG') {
                if (!$masuk) {
                    $response = ["status"=>"fail","msg"=>"Belum absen MASUK hari ini"];
                } elseif ($pulang) {
                    $response = ["status"=>"fail","msg"=>"Sudah absen PULANG hari ini"];
                } else {
                    $waktu_tap_guru = $tgl . " " . $jam;
                    $rfid_uid_guru = "KEYPAD";
                    $keterangan_guru = "KEYPAD";
                    $stmt2 = $conn->prepare("INSERT INTO kehadiran_guru (nipy, rfid_uid, waktu_tap, status, keterangan) VALUES (?,?,?,?,?)");
                    $stmt2->bind_param("sssss", $nipy, $rfid_uid_guru, $waktu_tap_guru, $mode, $keterangan_guru);
                    $stmt2->execute();
                    // notifikasi
                    $waRow = $conn->query("SELECT no_wa FROM nomor_wa_guru WHERE nipy='$nipy'")->fetch_assoc();
                    $pesan = "👨‍🏫 PRESENSI GURU\n".
                             "Nama : ".$row['nama']."\n".
                             "NIPY : $nipy\n".
                             "Tanggal : $tgl\n".
                             "Jam : $jam\n".
                             "Status : $mode";
                    if ($waRow) kirimWA($waRow['no_wa'], $pesan);
                    if (!empty($row['email'])) kirimEmail($row['email'], "Presensi Guru - $tgl", $pesan);
                    $response = [
                        "status" => "ok",
                        "role" => "guru",
                        "mode" => $mode,
                        "nipy" => $nipy,
                        "nama" => $row['nama']
                    ];
                }
            }
        } else {
            $response = ["status"=>"fail","msg"=>"Password salah"];
        }
    } else {
        $response = ["status"=>"fail","msg"=>"NIPY tidak ditemukan"];
    }
}

echo json_encode($response);
?>

