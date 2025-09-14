<?php
require_once '../../koneksi.php';
$nis = $_POST['nis'] ?? '';
$keterangan = $_POST['keterangan'] ?? '';
$tanggal = $_POST['tanggal'] ?? '';
$sql = "UPDATE ketidakhadiran SET keterangan=? WHERE nis=? AND tanggal=?";
$stmt = $conn->prepare($sql);
$stmt->bind_param("sss", $keterangan, $nis, $tanggal);
echo json_encode(["success" => $stmt->execute()]);
?>