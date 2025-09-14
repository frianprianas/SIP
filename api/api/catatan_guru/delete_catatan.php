<?php
// sip/catatan/delete_catatan.php
// Endpoint untuk menghapus catatan siswa

error_reporting(E_ALL);
ini_set('display_errors', '1');
header('Content-Type: application/json');

require_once '../koneksi.php'; // Sesuaikan path ke file koneksi.php Anda

function respondWithJson($status, $message, $data = []) {
    global $conn;
    $response = ["success" => ($status == "SUCCESS"), "message" => $message];
    if (!empty($data)) {
        $response["data"] = $data;
    }
    echo json_encode($response);
    if ($conn) {
        $conn->close();
    }
    exit();
}

if ($conn->connect_error) {
    respondWithJson("ERROR", "Koneksi database gagal: " . $conn->connect_error);
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    respondWithJson("ERROR", "Metode permintaan tidak valid. Gunakan POST.");
}

$input = file_get_contents('php://input');
$data = json_decode($input, true);

if (empty($data) || json_last_error() !== JSON_ERROR_NONE) {
    respondWithJson("ERROR", "Body permintaan POST kosong atau format JSON tidak valid.");
}

$nipy = isset($data['nipy']) ? $data['nipy'] : '';
$tanggal_catatan = isset($data['tanggal_catatan']) ? $data['tanggal_catatan'] : ''; // Format YYYY-MM-DD

if (empty($nipy) || empty($tanggal_catatan)) {
    respondWithJson("ERROR", "Parameter 'nipy' dan 'tanggal_catatan' diperlukan.");
}

$stmt = $conn->prepare("DELETE FROM catatan_guru WHERE nipy = ? AND tanggal_catatan = ?");
if ($stmt === FALSE) {
    respondWithJson("ERROR", "Gagal menyiapkan statement: " . $conn->error);
}

$stmt->bind_param("ss", $nipy, $tanggal_catatan);
if ($stmt->execute()) {
    if ($stmt->affected_rows > 0) {
        respondWithJson("SUCCESS", "Catatan berhasil dihapus.");
    } else {
        respondWithJson("NOT_FOUND", "Catatan tidak ditemukan untuk nipy dan tanggal tersebut.");
    }
} else {
    respondWithJson("ERROR", "Gagal menghapus catatan: " . $stmt->error);
}

$stmt->close();
$conn->close();
?>