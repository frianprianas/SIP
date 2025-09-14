<?php
// koneksi.php

// Konfigurasi Database
// Ganti nilai-nilai berikut sesuai dengan pengaturan database MySQL Anda.
$servername = "sip.ctwiiuqo2wpi.ap-southeast-2.rds.amazonaws.com"; // Umumnya 'localhost' jika database berada di server yang sama dengan PHP.
$username = "admin";      // Username untuk mengakses database MySQL Anda.
$password = "On5laught?!666";          // Password untuk username MySQL Anda. (Kosongkan jika tidak ada password).
$dbname = "sip";         // Nama database yang telah Anda buat, yaitu 'sip'.

// Buat objek koneksi MySQLi
$conn = new mysqli($servername, $username, $password, $dbname);

// Periksa apakah koneksi berhasil atau ada error
if ($conn->connect_error) {
    // Jika koneksi gagal, hentikan eksekusi skrip dan tampilkan pesan error yang jelas.
    // Ini penting agar Anda tahu jika ada masalah koneksi.
    die("Koneksi database gagal: " . $conn->connect_error);
}

// Opsional: Atur charset (character set) untuk koneksi.
// Ini membantu mencegah masalah encoding karakter (misalnya jika ada karakter khusus).
$conn->set_charset("utf8mb4"); // Menggunakan utf8mb4 direkomendasikan untuk dukungan emoji dan karakter yang lebih luas.

// Pada titik ini, variabel $conn berisi objek koneksi yang sudah siap digunakan
// oleh file PHP lain yang meng-include (menyertakan) file koneksi.php ini.