<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
require_once '../../koneksi.php';

$nis = $_GET['nis'] ?? '';
$tanggal = $_GET['tanggal'] ?? '';

if (empty($nis) || empty($tanggal)) {
    echo json_encode(["ada" => false]);
    exit();
}

$sql = "SELECT id FROM ketidakhadiran WHERE nis=? AND tanggal=?";
$stmt = $conn->prepare($sql);
$stmt->bind_param("ss", $nis, $tanggal);
$stmt->execute();
$result = $stmt->get_result();
$ada = $result->num_rows > 0;

echo json_encode(["ada" => $ada]);
?>