<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
require_once '../../koneksi.php';

$nis = isset($_GET['nis']) ? $_GET['nis'] : '';
$tahun_mulai = isset($_GET['tahun_mulai']) ? intval($_GET['tahun_mulai']) : intval(date('Y'));

if (empty($nis)) {
    echo json_encode(["success" => false, "message" => "Parameter NIS wajib"]);
    exit();
}

$bulanArr = [
    ['Juli', 7], ['Agustus', 8], ['September', 9], ['Oktober', 10], ['November', 11], ['Desember', 12],
    ['Januari', 1], ['Februari', 2], ['Maret', 3], ['April', 4], ['Mei', 5], ['Juni', 6]
];

function countWeekdays($month, $year) {
    $count = 0;
    $daysInMonth = cal_days_in_month(CAL_GREGORIAN, $month, $year);
    for ($day = 1; $day <= $daysInMonth; $day++) {
        $weekday = date('N', strtotime("$year-$month-$day"));
        if ($weekday >= 1 && $weekday <= 5) { // Senin-Jumat
            $count++;
        }
    }
    return $count;
}

$data = [];
for ($i = 0; $i < 12; $i++) {
    $bulanNama = $bulanArr[$i][0];
    $bulanNum = $bulanArr[$i][1];
    $tahun = $i < 6 ? $tahun_mulai : $tahun_mulai + 1;

    // Hitung hari aktif (Senin-Jumat)
    $hariAktif = countWeekdays($bulanNum, $tahun);

    // Hitung jumlah hadir siswa
    $sql = "SELECT COUNT(*) as hadir FROM kehadiran WHERE nis=? AND MONTH(waktu_tap)=? AND YEAR(waktu_tap)=?";
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("sii", $nis, $bulanNum, $tahun);
    $stmt->execute();
    $result = $stmt->get_result()->fetch_assoc();
    $jumlahHadir = $result['hadir'] ?? 0;

    $data[] = [
        "bulan" => "$bulanNama $tahun",
        "hari_aktif" => $hariAktif,
        "jumlah_hadir" => $jumlahHadir
    ];
}

echo json_encode(["success" => true, "data" => $data]);
?>