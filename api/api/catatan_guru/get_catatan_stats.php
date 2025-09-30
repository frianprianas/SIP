<?php
// api/catatan_guru/get_catatan_stats.php

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
    // Validasi parameter NIPY
    if (!isset($_GET['nipy']) || empty($_GET['nipy'])) {
        respondWithJson("ERROR", "Parameter NIPY diperlukan.");
    }
    
    $nipy = $_GET['nipy'];
    
    // Dapatkan total catatan untuk guru ini
    $totalStmt = $conn->prepare("SELECT COUNT(*) AS total FROM catatan_guru WHERE nipy = ?");
    if ($totalStmt === FALSE) {
        throw new Exception("Gagal menyiapkan statement total: " . $conn->error);
    }
    $totalStmt->bind_param("s", $nipy);
    $totalStmt->execute();
    $totalResult = $totalStmt->get_result();
    $total = $totalResult->fetch_assoc()['total'];
    $totalStmt->close();

    // Dapatkan catatan bulan ini untuk guru ini
    $bulanIni = date('Y-m-01');
    $akhirBulanIni = date('Y-m-t');
    $stmtBulanIni = $conn->prepare("SELECT COUNT(*) AS bulan_ini FROM catatan_guru WHERE nipy = ? AND tanggal_catatan >= ? AND tanggal_catatan <= ?");
    if ($stmtBulanIni === FALSE) {
        throw new Exception("Gagal menyiapkan statement bulan ini: " . $conn->error);
    }
    $stmtBulanIni->bind_param("sss", $nipy, $bulanIni, $akhirBulanIni);
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
