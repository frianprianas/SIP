<?php
// api/auth/login_siswa.php
header('Content-Type: application/json');
require_once '../../koneksi.php'; // Sesuaikan path ini sesuai lokasi koneksi.php Anda

// Izinkan CORS jika aplikasi Flutter berjalan dari domain/host yang berbeda
if (isset($_SERVER['HTTP_ORIGIN'])) {
    header("Access-Control-Allow-Origin: {$_SERVER['HTTP_ORIGIN']}");
    header('Access-Control-Allow-Credentials: true');
    header('Access-Control-Max-Age: 86400');    // cache for 1 day
}

// Access-Control headers for preflight request (khusus untuk method OPTIONS)
if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    if (isset($_SERVER['HTTP_ACCESS_CONTROL_REQUEST_METHOD']))
        header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
    if (isset($_SERVER['HTTP_ACCESS_CONTROL_REQUEST_HEADERS']))
        header("Access-Control-Allow-Headers: {$_SERVER['HTTP_ACCESS_CONTROL_REQUEST_HEADERS']}");
    exit(0);
}

// Hanya izinkan metode POST
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    echo json_encode(["success" => false, "message" => "Metode request tidak diizinkan."]);
    // Pastikan $conn ditutup meskipun ada error
    if (isset($conn)) {
        $conn->close();
    }
    exit();
}

// Ambil data JSON dari body request
$input = file_get_contents('php://input');
$data = json_decode($input, true);

$email = isset($data['email']) ? $data['email'] : '';
$password = isset($data['password']) ? $data['password'] : '';

if (empty($email) || empty($password)) {
    echo json_encode(["success" => false, "message" => "Email dan password harus diisi."]);
    if (isset($conn)) {
        $conn->close();
    }
    exit();
}

// Menggunakan kolom 'nipy' dan 'ket'
$stmt = $conn->prepare("SELECT nis, nama, kelas, email, password FROM siswa WHERE email = ?");
if ($stmt === false) {
    echo json_encode(["success" => false, "message" => "Terjadi kesalahan database saat menyiapkan query."]);
    $conn->close();
    exit();
}

$stmt->bind_param("s", $email);
$stmt->execute();
$result = $stmt->get_result();

if ($result->num_rows === 0) {
    echo json_encode(["success" => false, "message" => "Email atau password salah."]);
} else {
    $siswa = $result->fetch_assoc();

    $password_from_db = $siswa['password'];
    $is_password_valid = false;

    // Cek apakah password yang tersimpan sudah di-hash
    if (str_starts_with($password_from_db, '$2y$') || str_starts_with($password_from_db, '$2a$') || str_starts_with($password_from_db, '$argon2id$')) {
        // Password sudah di-hash, verifikasi menggunakan password_verify()
        $is_password_valid = password_verify($password, $password_from_db);
    } else {
        // Password masih plain text, verifikasi plain text
        $is_password_valid = ($password === $password_from_db);

        // Jika valid, hash password dan update di database
        if ($is_password_valid) {
            $hashed_password = password_hash($password, PASSWORD_BCRYPT);
            // Update password di tabel 'siswa' menggunakan 'nipy'
            $stmt_update = $conn->prepare("UPDATE siswa SET password = ? WHERE nis = ?");
            if ($stmt_update) {
                $stmt_update->bind_param("ss", $hashed_password, $siswa['nis']);
                $stmt_update->execute();
                $stmt_update->close();
                error_log("Password siswa NIS {$siswa['nis']} berhasil di-hash saat login.");
            } else {
                error_log("Gagal menyiapkan update password hash untuk nis NIS {$siswa['nis']}: " . $conn->error);
            }
        }
    }

    if ($is_password_valid) {
        echo json_encode([
            "success" => true,
            "message" => "Login berhasil!",
            "data" => [
                "nis" => $siswa['nis'],
                "nama" => $siswa['nama'],
                "kelas" => $siswa['kelas'],
                "email" => $siswa['email']
            ]
        ]);
    } else {
        echo json_encode(["success" => false, "message" => "Email atau password salah."]);
    }
}

$stmt->close();
$conn->close();
?>