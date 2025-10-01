<?php
// api/catatan/get_stats.php

error_reporting(E_ALL);
ini_set('display_errors', '1');

header('Content-Type: application/json');

require_once '../../koneksi.php';

function respondWithJson($status, $message, $data = []) {
    $response = ["success" => ($status === "SUCCESS"), "message" => $message];
    if (!empty($data)) {
        $response["data"] = $data;
    }
    echo json_encode($response);
    exit();
}

try {
    // Validasi parameter NIS
    if (!isset($_GET['nis']) || empty($_GET['nis'])) {
        respondWithJson("ERROR", "Parameter NIS diperlukan.");
    }
    
    $nis = $_GET['nis'];
    
    // Dapatkan total catatan untuk siswa ini
    $totalStmt = $conn->prepare("SELECT COUNT(*) AS total FROM catatan WHERE nis = ?");
    if ($totalStmt === FALSE) {
        throw new Exception("Gagal menyiapkan statement total: " . $conn->error);
    }
    $totalStmt->bind_param("s", $nis);
    $totalStmt->execute();
    $totalResult = $totalStmt->get_result();
    $total = $totalResult->fetch_assoc()['total'];
    $totalStmt->close();

    // Dapatkan catatan bulan ini untuk siswa ini
    $bulanIni = date('Y-m-01');
    $akhirBulanIni = date('Y-m-t');
    $stmtBulanIni = $conn->prepare("SELECT COUNT(*) AS bulan_ini FROM catatan WHERE nis = ? AND tanggal_catatan >= ? AND tanggal_catatan <= ?");
    if ($stmtBulanIni === FALSE) {
        throw new Exception("Gagal menyiapkan statement bulan ini: " . $conn->error);
    }
    $stmtBulanIni->bind_param("sss", $nis, $bulanIni, $akhirBulanIni);
    $stmtBulanIni->execute();
    $bulanIniResult = $stmtBulanIni->get_result();
    $bulanIniCount = $bulanIniResult->fetch_assoc()['bulan_ini'];
    $stmtBulanIni->close();
    
    $stats = [
        "total" => (int)$total,
        "bulan_ini" => (int)$bulanIniCount
    ];
    
    respondWithJson("SUCCESS", "Statistik berhasil dimuat.", $stats);

} catch (Exception $e) {
    respondWithJson("ERROR", $e->getMessage());
} finally {
    if (isset($conn)) $conn->close();
}
?>
