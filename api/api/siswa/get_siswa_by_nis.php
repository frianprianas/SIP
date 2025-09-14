<?php
header('Content-Type: application/json');
require_once '../../koneksi.php';
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

// CORS
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

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    echo json_encode(["success" => false, "message" => "Metode request tidak diizinkan."]);
    if (isset($conn)) $conn->close();
    exit();
}

$nis = isset($_GET['nis']) ? $_GET['nis'] : '';
if (empty($nis)) {
    echo json_encode(["success" => false, "message" => "NIS harus diisi."]);
    if (isset($conn)) $conn->close();
    exit();
}

$stmt = $conn->prepare("SELECT nis, nama, kelas, email FROM siswa WHERE nis = ?");
if ($stmt === false) {
    echo json_encode(["success" => false, "message" => "Kesalahan database."]);
    $conn->close();
    exit();
}
$stmt->bind_param("s", $nis);
$stmt->execute();
$result = $stmt->get_result();

if ($result->num_rows === 0) {
    echo json_encode(["success" => false, "message" => "Siswa tidak ditemukan."]);
} else {
    $siswa = $result->fetch_assoc();
    echo json_encode([
        "success" => true,
        "data" => $siswa
    ]);
}

$stmt->close();
$conn->close();
?>