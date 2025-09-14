<?php
require_once '../../koneksi.php';
$nis = $_POST['nis'] ?? '';
$tanggal = $_POST['tanggal'] ?? '';
$sql = "DELETE FROM ketidakhadiran WHERE nis=? AND tanggal=?";
$stmt = $conn->prepare($sql);
$stmt->bind_param("ss", $nis, $tanggal);
echo json_encode(["success" => $stmt->execute()]);
?>