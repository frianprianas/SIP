

<?php
// sip/catatan/delete_catatan.php
// Endpoint untuk menghapus catatan siswa

// Aktifkan pelaporan error untuk debugging di lingkungan pengembangan
// Untuk produksi, setel error_reporting(0) dan display_errors = '0'
error_reporting(E_ALL);
ini_set('display_errors', '1');

header('Content-Type: application/json');

// Pastikan tidak ada spasi atau karakter di luar tag PHP
require_once '../../koneksi.php';

// Gunakan mysqli_report untuk menangani error secara ketat
mysqli_report(MYSQLI_REPORT_ERROR | MYSQLI_REPORT_STRICT);

// Fungsi untuk mengirimkan respons JSON dan menghentikan eksekusi
function respondWithJson($status, $message, $data = []) {
    $response = ["success" => ($status === "SUCCESS"), "message" => $message];
    if (!empty($data)) {
        $response["data"] = $data;
    }
    echo json_encode($response);
    exit();
}

try {
    // Koneksi ke database
    $conn = new mysqli($servername, $username, $password, $dbname);
    if ($conn->connect_error) {
        // Jika koneksi gagal, lemparkan Exception
        throw new Exception("Koneksi database gagal: " . $conn->connect_error);
    }

    // Pastikan metode permintaan adalah POST
    if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
        throw new Exception("Metode permintaan tidak valid. Gunakan POST.");
    }

    // Ambil body permintaan dan decode JSON
    $input = file_get_contents('php://input');
    $data = json_decode($input, true);

    if (json_last_error() !== JSON_ERROR_NONE) {
        throw new Exception("Body permintaan POST kosong atau format JSON tidak valid.");
    }

    // Validasi parameter yang diperlukan
    $nis = $data['nis'] ?? '';
    $tanggal_catatan = $data['tanggal_catatan'] ?? ''; // Format YYYY-MM-DD

    if (empty($nis) || empty($tanggal_catatan)) {
        throw new Exception("Parameter 'nis' dan 'tanggal_catatan' diperlukan.");
    }

    // Siapkan statement SQL untuk penghapusan
    $stmt = $conn->prepare("DELETE FROM catatan WHERE nis = ? AND tanggal_catatan = ?");
    if ($stmt === FALSE) {
        throw new Exception("Gagal menyiapkan statement: " . $conn->error);
    }

    // Bind parameter dan eksekusi statement
    $stmt->bind_param("ss", $nis, $tanggal_catatan);
    $stmt->execute();

    // Periksa jumlah baris yang terpengaruh
    if ($stmt->affected_rows > 0) {
        respondWithJson("SUCCESS", "Catatan berhasil dihapus.");
    } else {
        respondWithJson("NOT_FOUND", "Catatan tidak ditemukan untuk NIS dan tanggal tersebut.");
    }

} catch (Exception $e) {
    // Tangani semua Exception yang terjadi
    respondWithJson("ERROR", $e->getMessage());
} finally {
    // Pastikan semua sumber daya ditutup
    if (isset($stmt)) {
        $stmt->close();
    }
    if (isset($conn) && $conn->ping()) {
        $conn->close();
    }
}
?>
