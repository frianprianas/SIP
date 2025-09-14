<?php
// File: api/presensi/get_kelas_by_nipy.php

// --- Konfigurasi Headers dan CORS ---
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");
header("Content-Type: application/json; charset=UTF-8");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// --- Koneksi ke Database ---
// Sesuaikan path ke file koneksi Anda
require_once '../../koneksi.php';

if ($conn->connect_error) {
    http_response_code(500);
    echo json_encode(["success" => false, "message" => "Koneksi database gagal: " . $conn->connect_error]);
    exit();
}

// --- Mengambil dan Validasi Parameter ---
$nipy = isset($_GET['nipy']) ? $_GET['nipy'] : '';

if (empty($nipy)) {
    http_response_code(400); // Bad Request
    echo json_encode(["success" => false, "message" => "Parameter 'nipy' harus diisi."]);
    $conn->close();
    exit();
}

// --- Membangun Query SQL dengan Prepared Statement ---
// Mengambil data kelas dari tabel 'guru' berdasarkan NIPY
$sql = "SELECT kelas FROM kelas WHERE nipy = ?";

// --- Menyiapkan dan Menjalankan Query ---
$stmt = $conn->prepare($sql);
if ($stmt === false) {
    http_response_code(500);
    echo json_encode(["success" => false, "message" => "Terjadi kesalahan database: " . $conn->error]);
    $conn->close();
    exit();
}

$stmt->bind_param("s", $nipy);

if ($stmt->execute()) {
    $result = $stmt->get_result();
    if ($result->num_rows > 0) {
        $row = $result->fetch_assoc();
        http_response_code(200);
        echo json_encode(["success" => true, "data" => ["kelas" => $row['kelas']]]);
    } else {
        http_response_code(404); // Not Found
        echo json_encode(["success" => false, "message" => "NIPY tidak ditemukan."]);
    }
} else {
    http_response_code(500);
    echo json_encode(["success" => false, "message" => "Gagal mengambil data kelas: " . $stmt->error]);
}

// Tutup statement dan koneksi
$stmt->close();
$conn->close();
?>
