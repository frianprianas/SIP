<?php
// Tampilkan semua laporan error untuk debugging di awal
error_reporting(E_ALL);
ini_set('display_errors', 1);

header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Origin: *");
// Sekarang hanya menerima POST karena logika UPDATE dan INSERT digabung
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

// Helper function untuk memberikan respon JSON yang konsisten
function respondWithJson($success, $message, $data = null, $http_code = 200) {
    http_response_code($http_code);
    echo json_encode([
        "success" => $success,
        "message" => $message,
        "data" => $data
    ]);
    exit();
}

// Tangani permintaan OPTIONS preflight
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Koneksi ke database
$koneksi_path = '../../koneksi.php';

if (!file_exists($koneksi_path)) {
    respondWithJson(false, "File koneksi database tidak ditemukan: " . $koneksi_path, null, 500);
}

require_once($koneksi_path);

if (!isset($conn) || !$conn) {
    respondWithJson(false, "Variabel koneksi (\$conn) tidak ada atau gagal dibuat. Cek file koneksi.php Anda.", null, 500);
}

// Ambil body permintaan (raw JSON)
$json_data = file_get_contents('php://input');

if (empty($json_data)) {
    respondWithJson(false, "Body permintaan kosong.", null, 400);
}

$data = json_decode($json_data, true);

if ($data === null) {
    respondWithJson(false, "Format JSON tidak valid.", null, 400);
}

// Pastikan metode permintaan adalah POST
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    respondWithJson(false, "Metode permintaan tidak valid. Gunakan POST.", null, 405);
}

// Ambil data dari body JSON
$nis = $data['nis'] ?? '';
$catatan_text = $data['catatan_text'] ?? '';
$tanggal_catatan = $data['tanggal_catatan'] ?? '';

// Validasi input
if (empty($nis) || empty($catatan_text) || empty($tanggal_catatan)) {
    respondWithJson(false, "Parameter 'nis', 'catatan_text', dan 'tanggal_catatan' harus diisi.", null, 400);
}

// --- Logika untuk memeriksa dan melakukan INSERT atau UPDATE ---

// 1. Cek apakah catatan sudah ada untuk NIS dan tanggal ini
$sql_check = "SELECT id FROM catatan WHERE nis = ? AND tanggal_catatan = ?";
$stmt_check = $conn->prepare($sql_check);
if (!$stmt_check) {
    $error = $conn->error;
    $conn->close();
    respondWithJson(false, "Gagal menyiapkan statement cek: " . $error, null, 500);
}
$stmt_check->bind_param("ss", $nis, $tanggal_catatan);
$stmt_check->execute();
$result = $stmt_check->get_result();

if ($result->num_rows > 0) {
    // 2. Jika catatan sudah ada, lakukan UPDATE
    $row = $result->fetch_assoc();
    $id_catatan = $row['id'];
    
    $sql_update = "UPDATE catatan SET catatan_text = ? WHERE id = ?";
    $stmt_update = $conn->prepare($sql_update);
    if (!$stmt_update) {
        $error = $conn->error;
        $conn->close();
        respondWithJson(false, "Gagal menyiapkan statement update: " . $error, null, 500);
    }
    
    $stmt_update->bind_param("si", $catatan_text, $id_catatan);

    if ($stmt_update->execute()) {
        if ($stmt_update->affected_rows > 0) {
            respondWithJson(true, "Catatan berhasil diperbarui.");
        } else {
            respondWithJson(true, "Tidak ada perubahan pada catatan.");
        }
    } else {
        $error = $stmt_update->error;
        $stmt_update->close();
        $conn->close();
        respondWithJson(false, "Gagal memperbarui catatan: " . $error, null, 500);
    }
    $stmt_update->close();
} else {
    // 3. Jika catatan belum ada, lakukan INSERT
    $sql_insert = "INSERT INTO catatan (nis, catatan_text, tanggal_catatan) VALUES (?, ?, ?)";
    $stmt_insert = $conn->prepare($sql_insert);
    
    if (!$stmt_insert) {
        $error = $conn->error;
        $conn->close();
        respondWithJson(false, "Gagal menyiapkan statement insert: " . $error, null, 500);
    }

    $stmt_insert->bind_param("sss", $nis, $catatan_text, $tanggal_catatan);

    if ($stmt_insert->execute()) {
        respondWithJson(true, "Catatan berhasil ditambahkan.");
    } else {
        $error = $stmt_insert->error;
        $stmt_insert->close();
        $conn->close();
        respondWithJson(false, "Gagal menambahkan catatan: " . $error, null, 500);
    }
    $stmt_insert->close();
}

$stmt_check->close();
$conn->close();
