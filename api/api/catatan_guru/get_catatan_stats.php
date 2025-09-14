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
    // Dapatkan total catatan
    $totalStmt = $conn->prepare("SELECT COUNT(*) AS total FROM catatan_guru");
    if ($totalStmt === FALSE) {
        throw new Exception("Gagal menyiapkan statement total: " . $conn->error);
    }
    $totalStmt->execute();
    $totalResult = $totalStmt->get_result();
    $total = $totalResult->fetch_assoc()['total'];
    $totalStmt->close();

    // Dapatkan catatan bulan ini
    $bulanIni = date('Y-m-01');
    $stmtBulanIni = $conn->prepare("SELECT COUNT(*) AS bulan_ini FROM catatan_guru WHERE tanggal_catatan >= ?");
    if ($stmtBulanIni === FALSE) {
        throw new Exception("Gagal menyiapkan statement bulan ini: " . $conn->error);
    }
    $stmtBulanIni->bind_param("s", $bulanIni);
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
