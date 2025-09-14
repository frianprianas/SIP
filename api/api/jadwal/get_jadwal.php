<?php
// get_jadwal.php
// Endpoint untuk mengambil semua data jadwal

error_reporting(E_ALL);
ini_set('display_errors', '1');

header('Content-Type: application/json');

// Izinkan CORS
if (isset($_SERVER['HTTP_ORIGIN'])) {
    header("Access-Control-Allow-Origin: {$_SERVER['HTTP_ORIGIN']}");
    header('Access-Control-Allow-Credentials: true');
    header('Access-Control-Max-Age: 86400');
}
if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    if (isset($_SERVER['HTTP_ACCESS_CONTROL_REQUEST_METHOD']))
        header("Access-Control-Allow-Methods: GET, OPTIONS");
    if (isset($_SERVER['HTTP_ACCESS_CONTROL_REQUEST_HEADERS']))
        header("Access-Control-Allow-Headers: {$_SERVER['HTTP_ACCESS_CONTROL_REQUEST_HEADERS']}");
    exit(0);
}

// Include file koneksi database
require_once '../../koneksi.php'; // Sesuaikan path ini

function respondWithJson($status, $message, $data = []) {
    global $conn;
    $response = ["status" => $status, "message" => $message];
    if (!empty($data)) {
        $response["data"] = $data;
    }
    echo json_encode($response);
    if ($conn) {
        $conn->close();
    }
    exit();
}

// Pastikan koneksi database berhasil
if ($conn->connect_error) {
    respondWithJson("ERROR", "Koneksi database gagal: " . $conn->connect_error);
}

// Ambil semua data jadwal
$sql = "SELECT id, hari_ke, nama_hari, jam_masuk, jam_pulang FROM jadwal ORDER BY hari_ke ASC";
$result = $conn->query($sql);

if ($result === FALSE) {
    respondWithJson("ERROR", "Kesalahan query jadwal: " . $conn->error);
}

$jadwal_list = [];
if ($result->num_rows > 0) {
    while($row = $result->fetch_assoc()) {
        $jadwal_list[] = $row;
    }
}

respondWithJson("SUCCESS", "Data jadwal berhasil diambil.", $jadwal_list);

$conn->close();
?>
