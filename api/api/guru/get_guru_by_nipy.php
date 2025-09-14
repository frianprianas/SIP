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

$nipy = isset($_GET['nipy']) ? $_GET['nipy'] : '';
if (empty($nipy)) {
    echo json_encode(["success" => false, "message" => "NIPY harus diisi."]);
    if (isset($conn)) $conn->close();
    exit();
}

$stmt = $conn->prepare("SELECT nipy, nama, email, ket FROM guru WHERE nipy = ?");
if ($stmt === false) {
    echo json_encode(["success" => false, "message" => "Kesalahan database."]);
    $conn->close();
    exit();
}
$stmt->bind_param("s", $nipy);
$stmt->execute();
$result = $stmt->get_result();

if ($result->num_rows === 0) {
    echo json_encode(["success" => false, "message" => "Guru tidak ditemukan."]);
} else {
    $guru = $result->fetch_assoc();
    echo json_encode([
        "success" => true,
        "data" => $guru
    ]);
}

$stmt->close();
$conn->close();
?>