<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

require_once '../../koneksi.php';

$kelas = isset($_GET['kelas']) ? $_GET['kelas'] : '';

if (empty($kelas)) {
    echo json_encode([
        "success" => false,
        "message" => "Parameter 'kelas' harus diisi."
    ]);
    exit();
}

$sql = "SELECT nis, nama FROM siswa WHERE kelas = ? ORDER BY nama ASC";
$stmt = $conn->prepare($sql);
$stmt->bind_param("s", $kelas);

if ($stmt->execute()) {
    $result = $stmt->get_result();
    $siswa = [];
    while ($row = $result->fetch_assoc()) {
        $siswa[] = [
            "nis" => $row['nis'],
            "nama" => $row['nama']
        ];
    }
    echo json_encode([
        "success" => true,
        "data" => $siswa
    ]);
} else {
    echo json_encode([
        "success" => false,
        "message" => "Gagal mengambil data siswa: " . $stmt->error
    ]);
}

$stmt->close();
$conn->close();
?>