<?php
// api/presensi/riwayat.php
header('Content-Type: application/json');
require_once '../../koneksi.php'; // Sesuaikan path ini sesuai struktur folder Anda

// Izinkan CORS (penting untuk development)
if (isset($_SERVER['HTTP_ORIGIN'])) {
    header("Access-Control-Allow-Origin: {$_SERVER['HTTP_ORIGIN']}");
    header('Access-Control-Allow-Credentials: true');
    header('Access-Control-Max-Age: 86400');
}
if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    if (isset($_SERVER['HTTP_ACCESS_CONTROL_REQUEST_METHOD']))
        header("Access-Control-Allow-Methods: GET, OPTIONS"); // Pastikan GET diizinkan
    if (isset($_SERVER['HTTP_ACCESS_CONTROL_REQUEST_HEADERS']))
        header("Access-Control-Allow-Headers: {$_SERVER['HTTP_ACCESS_CONTROL_REQUEST_HEADERS']}");
    exit(0);
}

// Pastikan metode request adalah GET
if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    echo json_encode(["success" => false, "message" => "Metode request tidak diizinkan. Gunakan GET."]);
    $conn->close();
    exit();
}

// Ambil parameter dari URL query string
$nipy = isset($_GET['nipy']) ? $_GET['nipy'] : '';
$bulan = isset($_GET['bulan']) ? (int)$_GET['bulan'] : null;
$tahun = isset($_GET['tahun']) ? (int)$_GET['tahun'] : null;
$limit = isset($_GET['limit']) ? (int)$_GET['limit'] : null;

if (empty($nipy)) {
    echo json_encode(["success" => false, "message" => "nipy harus diisi."]);
    $conn->close();
    exit();
}

$sql = "SELECT id, waktu_tap, status FROM kehadiran_guru WHERE nipy = ?";
$params = [$nipy];
$types = "s"; // Tipe data untuk nipy

if ($bulan !== null && $tahun !== null) {
    // Tambahkan kondisi untuk bulan dan tahun
    $sql .= " AND MONTH(waktu_tap) = ? AND YEAR(waktu_tap) = ?";
    $params[] = $bulan;
    $params[] = $tahun;
    $types .= "ii";
} else if ($bulan !== null) { // Jika hanya bulan yang diberikan
    $sql .= " AND MONTH(waktu_tap) = ?";
    $params[] = $bulan;
    $types .= "i";
} else if ($tahun !== null) { // Jika hanya tahun yang diberikan
    $sql .= " AND YEAR(waktu_tap) = ?";
    $params[] = $tahun;
    $types .= "i";
}

$sql .= " ORDER BY waktu_tap DESC";

// Jika limit diberikan dan lebih dari 0, tambahkan LIMIT
if ($limit !== null && $limit > 0) {
    $sql .= " LIMIT ?";
    $params[] = $limit;
    $types .= "i";
}

$stmt = $conn->prepare($sql);
if ($stmt === false) {
    echo json_encode(["success" => false, "message" => "Terjadi kesalahan database saat menyiapkan query: " . $conn->error]);
    $conn->close();
    exit();
}

// Bind parameter secara dinamis menggunakan call_user_func_array
// Ini diperlukan karena bind_param membutuhkan referensi
$a_params = [];
$a_params[] = $types;
for ($i = 0; $i < count($params); $i++) {
    $a_params[] = &$params[$i]; // Penting: pass by reference
}
call_user_func_array([$stmt, 'bind_param'], $a_params);


if ($stmt->execute()) {
    $result = $stmt->get_result();
    $presensi = [];
    while ($row = $result->fetch_assoc()) {
        $presensi[] = $row;
    }
    echo json_encode(["success" => true, "data" => $presensi]);
} else {
    echo json_encode(["success" => false, "message" => "Gagal mengambil riwayat presensi: " . $stmt->error]);
}

$stmt->close();
$conn->close();
?>