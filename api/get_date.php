<?php
// get_date.php - Endpoint untuk mendapatkan tanggal dan waktu server

// Set zona waktu ke Asia/Jakarta (WIB)
date_default_timezone_set('Asia/Jakarta');

// Atur header untuk respons JSON
header('Content-Type: application/json');

// Dapatkan tanggal dan waktu saat ini dari server
$current_date = date('Y-m-d');      // Contoh: 2025-07-20
$current_time = date('H:i:s');      // Contoh: 04:37:03
$current_day_name = date('l');      // Contoh: 'Sunday' (full textual representation of the day of the week)

// Konversi nama hari ke Bahasa Indonesia (opsional, tapi lebih baik untuk tampilan di LCD)
$hari_indonesia = [
    'Sunday'    => 'Minggu',
    'Monday'    => 'Senin',
    'Tuesday'   => 'Selasa',
    'Wednesday' => 'Rabu',
    'Thursday'  => 'Kamis',
    'Friday'    => 'Jumat',
    'Saturday'  => 'Sabtu'
];
$nama_hari_final = isset($hari_indonesia[$current_day_name]) ? $hari_indonesia[$current_day_name] : $current_day_name;


// Buat array data yang akan di-encode ke JSON
$response_data = [
    "date" => $current_date,       // Key 'date'
    "time" => $current_time,       // Key 'time'
    "day"  => $nama_hari_final     // Key 'day'
];

// Encode array menjadi JSON dan kirimkan ke output
echo json_encode($response_data);

// Pastikan tidak ada spasi, newline, atau karakter lain sebelum atau sesudah tag PHP
// dan setelah penutupan tag PHP (jika ada)

?>