<?php
// File: api/presensi/get_by_kelas.php
// Skrip ini mengambil data siswa berdasarkan nama kelas.

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

if (empty($kelas)) {
    http_response_code(400); // Bad Request
    echo json_encode(["success" => false, "message" => "Parameter 'kelas' harus diisi."]);
    $conn->close();
    exit();
}

// --- Membangun Query SQL dengan Prepared Statement ---
// Mengambil data nis dan nama siswa dari tabel 'siswa' berdasarkan nama kelas
$sql = "SELECT nis, nama FROM siswa WHERE kelas = ? ORDER BY nama ASC";

// --- Menyiapkan dan Menjalankan Query ---
$stmt = $conn->prepare($sql);
if ($stmt === false) {
    http_response_code(500);
    echo json_encode(["success" => false, "message" => "Terjadi kesalahan database: " . $conn->error]);
    $conn->close();
    exit();
}

$stmt->bind_param("s", $kelas);

if ($stmt->execute()) {
    $result = $stmt->get_result();
    $siswaList = [];
    while ($row = $result->fetch_assoc()) {
        $siswaList[] = $row;
    }

    if (!empty($siswaList)) {
        http_response_code(200);
        echo json_encode(["success" => true, "data" => $siswaList]);
    } else {
        http_response_code(404); // Not Found
        echo json_encode(["success" => false, "message" => "Tidak ada siswa di kelas ini."]);
    }
} else {
    http_response_code(500);
    echo json_encode(["success" => false, "message" => "Gagal mengambil data siswa: " . $stmt->error]);
}

// Tutup statement dan koneksi
$stmt->close();
$conn->close();
?>
