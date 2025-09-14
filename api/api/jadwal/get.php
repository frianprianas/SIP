<?php
// api/jadwal/get.php
header('Content-Type: application/json');
require_once '../../koneksi.php'; // Sesuaikan path ini

// Izinkan CORS
if (isset($_SERVER['HTTP_ORIGIN'])) {
    header("Access-Control-Allow-Origin: {$_SERVER['HTTP_ORIGIN']}");
    header('Access-Control-Allow-Credentials: true');
    header('Access-Control-Max-Age: 86400');
}
if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    if (isset($_SERVER['HTTP_ACCESS_CONTROL_REQUEST_METHOD']))
        header("Access-Control-Allow-Methods: GET, POST, OPTIONS");         
    if (isset($_SERVER['HTTP_ACCESS_CONTROL_REQUEST_HEADERS']))
        header("Access-Control-Allow-Headers: {$_SERVER['HTTP_ACCESS_CONTROL_REQUEST_HEADERS']}");
    exit(0);
}

// Hanya izinkan metode GET
if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    echo json_encode(["success" => false, "message" => "Metode request tidak diizinkan."]);
    $conn->close();
    exit();
}

$sql = "SELECT hari_ke, nama_hari, jam_masuk, jam_pulang FROM jadwal ORDER BY hari_ke ASC";
$result = $conn->query($sql);

$jadwal = [];
if ($result) {
    while ($row = $result->fetch_assoc()) {
        $jadwal[] = $row;
    }
    echo json_encode(["success" => true, "message" => "Data jadwal berhasil diambil.", "data" => $jadwal]);
} else {
    echo json_encode(["success" => false, "message" => "Gagal mengambil data jadwal: " . $conn->error]);
}

$conn->close();
?>