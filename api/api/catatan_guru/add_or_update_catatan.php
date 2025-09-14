<?php
// sip/catatan/add_or_update_catatan.php
// Endpoint untuk menambah atau memperbarui catatan siswa

error_reporting(0);
ini_set('display_errors', '0');

header('Content-Type: application/json');

require_once '../koneksi.php';

function respondWithJson($status, $message, $data = []) {
    global $conn;
    $response = ["success" => ($status == "SUCCESS"), "message" => $message];
    if (!empty($data)) {
        $response["data"] = $data;
    }
    echo json_encode($response);
    if ($conn) {
        $conn->close();
    }
    exit();
}

if ($conn->connect_error) {
    respondWithJson("ERROR", "Koneksi database gagal: " . $conn->connect_error);
}

// Ambil data dari body permintaan POST (JSON)
$input_json = file_get_contents('php://input');
$data = json_decode($input_json, true);

if (json_last_error() !== JSON_ERROR_NONE) {
    respondWithJson("ERROR", "Input JSON tidak valid. " . json_last_error_msg());
}

// Validasi input
$nipy = isset($data['nipy']) ? $data['nipy'] : '';
$tanggal_catatan = isset($data['tanggal_catatan']) ? $data['tanggal_catatan'] : '';
$isi_catatan = isset($data['catatan_text']) ? $data['catatan_text'] : ''; // Mengambil data dari 'isi_catatan'

if (empty($nipy) || empty($tanggal_catatan) || empty($isi_catatan)) {
    respondWithJson("ERROR", "Parameter 'nipy', 'tanggal_catatan', dan 'isi_catatan' diperlukan.");
}

// Cek apakah catatan sudah ada untuk nipy dan tanggal ini
$stmt_check = $conn->prepare("SELECT id FROM catatan_guru WHERE nipy = ? AND tanggal_catatan = ?");
if ($stmt_check === FALSE) {
    respondWithJson("ERROR", "Gagal menyiapkan statement cek: " . $conn->error);
}
$stmt_check->bind_param("ss", $nipy, $tanggal_catatan);
$stmt_check->execute();
$result_check = $stmt_check->get_result();

if ($result_check->num_rows > 0) {
    // Catatan sudah ada, lakukan UPDATE
    $stmt_update = $conn->prepare("UPDATE catatan_guru SET catatan_text = ? WHERE nipy = ? AND tanggal_catatan = ?"); // Perbaikan: menggunakan 'catatan_text'
    if ($stmt_update === FALSE) {
        respondWithJson("ERROR", "Gagal menyiapkan statement update: " . $conn->error);
    }
    $stmt_update->bind_param("sss", $isi_catatan, $nipy, $tanggal_catatan);
    if ($stmt_update->execute()) {
        respondWithJson("SUCCESS", "Catatan berhasil diperbarui.");
    } else {
        respondWithJson("ERROR", "Gagal memperbarui catatan: " . $stmt_update->error);
    }
    $stmt_update->close();
} else {
    // Catatan belum ada, lakukan INSERT
    $stmt_insert = $conn->prepare("INSERT INTO catatan_guru (nipy, tanggal_catatan, catatan_text) VALUES (?, ?, ?)"); // Perbaikan: menggunakan 'catatan_text'
    if ($stmt_insert === FALSE) {
        respondWithJson("ERROR", "Gagal menyiapkan statement insert: " . $conn->error);
    }
    $stmt_insert->bind_param("sss", $nipy, $tanggal_catatan, $isi_catatan);
    if ($stmt_insert->execute()) {
        respondWithJson("SUCCESS", "Catatan berhasil ditambahkan.");
    } else {
        respondWithJson("ERROR", "Gagal menambahkan catatan: " . $stmt_insert->error);
    }
    $stmt_insert->close();
}

$stmt_check->close();
$conn->close();