<?php
require_once '../../koneksi.php';

$kelas = $_GET['kelas'] ?? '';
$tanggal = $_GET['tanggal'] ?? '';

// Join ketidakhadiran dengan siswa untuk filter kelas
$sql = "SELECT keterangan, COUNT(*) as jumlah
        FROM ketidakhadiran
        INNER JOIN siswa ON ketidakhadiran.nis = siswa.nis
        WHERE siswa.kelas=? AND ketidakhadiran.tanggal=?
        GROUP BY keterangan";
$stmt = $conn->prepare($sql);
$stmt->bind_param("ss", $kelas, $tanggal);
$stmt->execute();
$result = $stmt->get_result();

$data = [
    "sakit" => 0,
    "izin" => 0,
    "tanpa_keterangan" => 0
];

while ($row = $result->fetch_assoc()) {
    if (strtolower($row['keterangan']) == 'sakit') $data['sakit'] = $row['jumlah'];
    else if (strtolower($row['keterangan']) == 'izin') $data['izin'] = $row['jumlah'];
    else $data['tanpa_keterangan'] += $row['jumlah'];
}

echo json_encode($data);
?>