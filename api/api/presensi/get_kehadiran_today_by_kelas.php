<?php
// File: api/presensi/get_kehadiran_by_kelas_tanggal.php

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
$kelas = isset($_GET['kelas']) ? $_GET['kelas'] : '';
$tanggal = isset($_GET['tanggal']) ? $_GET['tanggal'] : date('Y-m-d');

if (empty($kelas)) {
    http_response_code(400); // Bad Request
    echo json_encode(["success" => false, "message" => "Parameter 'kelas' harus diisi."]);
    $conn->close();
    exit();
}

// --- Membangun Query SQL ---
// Mengambil semua siswa yang terdaftar di kelas pada tanggal yang dipilih dari tabel 'kehadiran' dan 'siswa'
$sql = "SELECT s.nis, s.nama, k.waktu_tap, k.status
        FROM siswa s
        LEFT JOIN kehadiran k ON s.nis = k.nis
        AND DATE(k.waktu_tap) = ?
        WHERE s.kelas = ?
        ORDER BY s.nama ASC";

// --- Menyiapkan dan Menjalankan Query ---
$stmt = $conn->prepare($sql);
if ($stmt === false) {
    http_response_code(500);
    echo json_encode(["success" => false, "message" => "Terjadi kesalahan database: " . $conn->error]);
    $conn->close();
    exit();
}

$stmt->bind_param("ss", $tanggal, $kelas);

if ($stmt->execute()) {
    $result = $stmt->get_result();
    $kehadiran = [];
    while ($row = $result->fetch_assoc()) {
        $kehadiran[] = [
            "nis" => $row['nis'],
            "nama" => $row['nama'],
            // Menentukan status kehadiran, jika waktu_tap null berarti tidak hadir
            "status_kehadiran" => $row['waktu_tap'] !== null ? $row['status'] : "Tidak Hadir",
            "waktu_tap" => $row['waktu_tap']
        ];
    }
    http_response_code(200);
    echo json_encode(["success" => true, "data" => $kehadiran]);
} else {
    http_response_code(500);
    echo json_encode(["success" => false, "message" => "Gagal mengambil data kehadiran: " . $stmt->error]);
}

// Tutup statement dan koneksi
$stmt->close();
$conn->close();
?>
