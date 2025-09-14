<?php
// rekap_ketidakhadiran_bulanan.php
require_once '../../koneksi.php';
$nis = $_GET['nis'] ?? '';
$tahun = $_GET['tahun'] ?? '';

$bulanMulai = 7; // Juli
$data = [];
for ($i = 0; $i < 12; $i++) {
    $bulan = ($bulanMulai + $i - 1) % 12 + 1;
    $tahunBulan = $bulan >= $bulanMulai ? $tahun : $tahun + 1;
    $namaBulan = date('F', mktime(0, 0, 0, $bulan, 10));
    $sql = "SELECT keterangan, COUNT(*) as jumlah
            FROM ketidakhadiran
            WHERE nis=? AND YEAR(tanggal)=? AND MONTH(tanggal)=?
            GROUP BY keterangan";
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("sss", $nis, $tahunBulan, $bulan);
    $stmt->execute();
    $result = $stmt->get_result();
    $izin = $sakit = $absen = 0;
    while ($row = $result->fetch_assoc()) {
        if (strtolower($row['keterangan']) == 'izin') $izin = $row['jumlah'];
        else if (strtolower($row['keterangan']) == 'sakit') $sakit = $row['jumlah'];
        else $absen += $row['jumlah'];
    }
    $data[] = [
        "bulan" => "$namaBulan $tahunBulan",
        "izin" => $izin,
        "sakit" => $sakit,
        "absen" => $absen
    ];
}
echo json_encode($data);
?>