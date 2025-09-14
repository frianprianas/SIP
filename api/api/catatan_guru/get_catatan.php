<?php
// Tampilkan semua laporan error untuk debugging
error_reporting(E_ALL);
ini_set('display_errors', 1);

header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

// Helper function untuk memberikan respons JSON yang konsisten
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

// Hanya proses permintaan GET
if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    respondWithJson(false, "Metode permintaan tidak valid. Gunakan GET.", null, 405);
}

// Memeriksa apakah parameter 'nipy' ada
if (empty($_GET['nipy'])) {
    respondWithJson(false, "Parameter 'nipy' tidak ditemukan.", null, 400); // Pesan error diperbaiki
}

$nipy = $_GET['nipy'];
$tanggal_catatan = $_GET['tanggal'] ?? null;

// Koneksi ke database
$koneksi_path = '../../koneksi.php';

if (!file_exists($koneksi_path)) {
    respondWithJson(false, "File koneksi database tidak ditemukan: " . $koneksi_path, null, 500);
}

require_once($koneksi_path);

if (!isset($conn) || !$conn) {
    respondWithJson(false, "Gagal terhubung ke database. Cek file koneksi.php Anda.", null, 500);
}

// Siapkan query SQL
$sql = "SELECT id, nipy, catatan_text, tanggal_catatan FROM catatan_guru WHERE nipy = ?";
$types = "s"; // Tipe untuk nipy
$params = [$nipy];

// Tambahkan filter tanggal jika parameter 'tanggal_catatan' ada
if ($tanggal_catatan) {
    $sql .= " AND tanggal_catatan = ?";
    $types .= "s"; // Tambahkan tipe untuk tanggal
    $params[] = $tanggal_catatan; // Tambahkan tanggal ke array parameter
}

// Selalu urutkan berdasarkan tanggal, yang terbaru di atas
$sql .= " ORDER BY tanggal_catatan DESC";

// Persiapkan statement
$stmt = $conn->prepare($sql);

if (!$stmt) {
    $error = $conn->error;
    $conn->close();
    respondWithJson(false, "Gagal menyiapkan statement: " . $error, null, 500);
}

// Bind parameter secara dinamis menggunakan call_user_func_array
$stmt->bind_param($types, ...$params);

// Eksekusi statement
$stmt->execute();
$result = $stmt->get_result();

$catatan_array = [];
if ($result->num_rows > 0) {
    while ($row = $result->fetch_assoc()) {
        $catatan_array[] = $row;
    }
    // Kirim respons sukses dengan array catatan
    respondWithJson(true, "Data catatan berhasil diambil.", $catatan_array);
} else {
    // Kirim respons sukses dengan data kosong jika tidak ada catatan
    respondWithJson(true, "Tidak ada catatan ditemukan.", []);
}

$stmt->close();
$conn->close();
?>
