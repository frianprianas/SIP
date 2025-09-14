<?php
// upload_foto.php - Endpoint untuk menerima dan menyimpan foto dari ESP32

// Set header untuk respons JSON
header('Content-Type: application/json');

// Tentukan folder penyimpanan foto
// PASTIKAN FOLDER 'foto/' ADA DAN MEMILIKI IZIN TULIS (CHMOD 777)
$upload_dir = 'foto_guru/'; 

// Cek apakah folder upload sudah ada, jika belum, buat.
// Dengan 0777, ini memberikan izin penuh. Pastikan ini aman di lingkungan produksi Anda.
if (!is_dir($upload_dir)) {
    if (!mkdir($upload_dir, 0777, true)) {
        echo json_encode(['status' => 'ERROR', 'message' => 'Gagal membuat folder upload: ' . $upload_dir]);
        exit;
    }
}

// Periksa apakah permintaan adalah POST dan memiliki tipe konten image/jpeg
// ESP32 mengirim data gambar langsung sebagai body POST request dengan Content-Type: image/jpeg
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_SERVER['CONTENT_TYPE']) && strpos($_SERVER['CONTENT_TYPE'], 'image/jpeg') !== false) {
    
    // Dapatkan ID unik (misalnya ID kehadiran) dari parameter query URL
    // ESP32 akan mengirimkan URL seperti: upload_foto.php?id=123
    $kehadiran_id = isset($_GET['id']) ? $_GET['id'] : null;

    if ($kehadiran_id === null || !ctype_digit($kehadiran_id)) {
        echo json_encode(['status' => 'ERROR', 'message' => 'Parameter "id" tidak valid atau tidak ditemukan.']);
        exit;
    }

    // Nama file akan menjadi ID_kehadiran.jpg
    $file_name = $kehadiran_id . '.jpg'; 
    $file_path = $upload_dir . $file_name; // Path lengkap ke file yang akan disimpan

    // Baca data gambar dari body permintaan POST
    $image_data = file_get_contents("php://input");

    // Periksa apakah data gambar berhasil dibaca
    if ($image_data === false) {
        echo json_encode(['status' => 'ERROR', 'message' => 'Gagal membaca data gambar dari permintaan.']);
        exit;
    }

    // Simpan data gambar ke file di server
    if (file_put_contents($file_path, $image_data)) {
        // Berhasil menyimpan
        echo json_encode([
            'status' => 'SUCCESS', 
            'message' => 'Foto berhasil diunggah.', 
            'file_name' => $file_name,
            'url' => 'http://' . $_SERVER['HTTP_HOST'] . '/' . $upload_dir . $file_name // URL lengkap foto
        ]);
    } else {
        // Gagal menyimpan (kemungkinan masalah izin folder atau ruang disk)
        echo json_encode(['status' => 'ERROR', 'message' => 'Gagal menyimpan foto di server. Periksa izin folder atau ruang disk.']);
    }

} else {
    // Jika bukan metode POST atau Content-Type bukan image/jpeg
    echo json_encode(['status' => 'ERROR', 'message' => 'Metode permintaan tidak valid atau Content-Type bukan image/jpeg.']);
}

?>