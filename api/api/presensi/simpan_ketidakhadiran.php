<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
require_once '../../koneksi.php';

$nis = $_POST['nis'] ?? '';
$keterangan = $_POST['keterangan'] ?? '';
$tanggal = $_POST['tanggal'] ?? '';

if (empty($nis) || empty($keterangan) || empty($tanggal)) {
    echo json_encode(["success" => false, "message" => "Data tidak lengkap"]);
    exit();
}

// Cek duplikat
$sqlCek = "SELECT id FROM ketidakhadiran WHERE nis=? AND tanggal=?";
$stmtCek = $conn->prepare($sqlCek);
$stmtCek->bind_param("ss", $nis, $tanggal);
$stmtCek->execute();
$resCek = $stmtCek->get_result();
if ($resCek->num_rows > 0) {
    echo json_encode(["success" => false, "message" => "Sudah diinput"]);
    exit();
}

$sql = "INSERT INTO ketidakhadiran (nis, keterangan, tanggal) VALUES (?, ?, ?)";
$stmt = $conn->prepare($sql);
$stmt->bind_param("sss", $nis, $keterangan, $tanggal);

if ($stmt->execute()) {
    echo json_encode(["success" => true]);
} else {
    echo json_encode(["success" => false, "message" => $stmt->error]);
}
?>