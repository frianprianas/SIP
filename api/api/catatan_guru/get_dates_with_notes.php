<?php
// api/catatan_guru/get_dates_with_notes.php

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
    // Validasi parameter
    if (!isset($_GET['nipy']) || empty($_GET['nipy'])) {
        respondWithJson("ERROR", "Parameter NIPY diperlukan.");
    }
    
    if (!isset($_GET['year']) || !isset($_GET['month'])) {
        respondWithJson("ERROR", "Parameter year dan month diperlukan.");
    }
    
    $nipy = $_GET['nipy'];
    $year = intval($_GET['year']);
    $month = intval($_GET['month']);
    
    // Validasi format year dan month
    if ($year < 2000 || $year > 3000 || $month < 1 || $month > 12) {
        respondWithJson("ERROR", "Format year atau month tidak valid.");
    }
    
    // Query untuk mendapatkan tanggal yang memiliki catatan guru
    $startDate = sprintf('%04d-%02d-01', $year, $month);
    $endDate = sprintf('%04d-%02d-%02d', $year, $month, cal_days_in_month(CAL_GREGORIAN, $month, $year));
    
    $stmt = $conn->prepare("
        SELECT DISTINCT tanggal_catatan 
        FROM catatan_guru 
        WHERE nipy = ? 
        AND tanggal_catatan >= ? 
        AND tanggal_catatan <= ?
        ORDER BY tanggal_catatan ASC
    ");
    
    if ($stmt === FALSE) {
        throw new Exception("Gagal menyiapkan statement: " . $conn->error);
    }
    
    $stmt->bind_param("sss", $nipy, $startDate, $endDate);
    $stmt->execute();
    $result = $stmt->get_result();
    
    $dates = [];
    while ($row = $result->fetch_assoc()) {
        $dates[] = $row['tanggal_catatan'];
    }
    
    $stmt->close();
    
    respondWithJson("SUCCESS", "Tanggal berhasil dimuat.", $dates);

} catch (Exception $e) {
    respondWithJson("ERROR", $e->getMessage());
} finally {
    if (isset($conn)) $conn->close();
}
?>