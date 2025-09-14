<?php
// dashboard.php - Versi Diperbarui dengan Penyesuaian UI
session_start();

// Anda bisa tambahkan logika autentikasi di sini nanti
// if (!isset($_SESSION['user_id'])) {
//     header("Location: login.php"); // Ganti ke halaman login Anda
//     exit();
// }

// Set zona waktu ke Asia/Jakarta (WIB) untuk tanggal dan waktu yang akurat
date_default_timezone_set('Asia/Jakarta');

// Include file koneksi database yang sudah ada
require_once 'koneksi.php'; // Path ini sudah benar karena dashboard.php ada di root

// --- Ambil Data untuk Dashboard ---
// 1. Jumlah Siswa
$total_siswa = 0;
$result_siswa_count = $conn->query("SELECT COUNT(*) AS total FROM siswa");
if ($result_siswa_count) {
    $row = $result_siswa_count->fetch_assoc();
    $total_siswa = $row['total'];
} else {
    error_log("Error fetching total siswa: " . $conn->error);
}

// 2. Jumlah Presensi Hari Ini
$presensi_hari_ini = 0;
$today = date('Y-m-d');
$result_presensi_today = $conn->query("SELECT COUNT(*) AS total FROM kehadiran WHERE DATE(waktu_tap) = '$today'");
if ($result_presensi_today) {
    $row = $result_presensi_today->fetch_assoc();
    $presensi_hari_ini = $row['total'];
} else {
    error_log("Error fetching presensi hari ini: " . $conn->error);
}

// Tutup koneksi setelah selesai mengambil semua data
$conn->close();

?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Dashboard - SISTEM INFORMASI PRESENSI (SIP)</title> <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet" integrity="sha384-QWTKZyjpPEjISv5WaRU9OFeRpok6YctnYmDr5pNlyT2bRjXh0JMhjY6hW+ALEwIH" crossorigin="anonymous">
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0-beta3/css/all.min.css" rel="stylesheet">
    <style>
        /* Gaya umum */
        body {
            background-color: #f0f2f5;
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
        }
        .wrapper {
            display: flex;
            min-height: 100vh;
        }

        /* Sidebar Styling */
        #sidebar {
            min-width: 280px;
            max-width: 280px;
            background: linear-gradient(to bottom right, #36D1DC, #5B86E5);
            color: #fff;
            transition: all 0.3s;
            padding: 20px;
            box-shadow: 2px 0 10px rgba(0,0,0,0.2);
            position: sticky;
            top: 0;
            left: 0;
            height: 100vh;
            overflow-y: auto;
            z-index: 1030; /* Pastikan sidebar di atas konten lain saat active */
        }
        #sidebar.active {
            margin-left: -280px;
        }
        #sidebar .sidebar-header {
            padding-bottom: 20px;
            border-bottom: 1px solid rgba(255,255,255,0.2);
            text-align: center;
            margin-bottom: 20px;
        }
        #sidebar .profile-img {
            width: 90px;
            height: 90px;
            border-radius: 50%;
            object-fit: cover;
            border: 4px solid #fff;
            box-shadow: 0 0 10px rgba(0,0,0,0.3);
            margin-bottom: 10px; /* Tambah margin bawah */
        }
        #sidebar h3 {
            color: white;
            font-weight: 600;
            line-height: 1.2;
            font-size: 1.3em; /* Sedikit lebih besar untuk nama aplikasi */
        }
        #sidebar p {
            color: rgba(255,255,255,0.8);
            font-size: 0.9em;
            margin-bottom: 0; /* Hapus margin bawah default */
        }
        #sidebar ul.components {
            padding: 0;
            list-style: none;
        }
        #sidebar ul li a {
            padding: 12px 15px;
            font-size: 1.05em;
            display: block;
            color: #fff;
            text-decoration: none;
            border-radius: 8px;
            margin-bottom: 8px;
            transition: all 0.3s ease-in-out;
            display: flex;
            align-items: center;
        }
        #sidebar ul li a i {
            margin-right: 10px;
            font-size: 1.2em;
        }
        #sidebar ul li a:hover {
            background: rgba(255,255,255,0.25);
            transform: translateX(5px);
        }
        #sidebar ul li.active > a, a[aria-expanded="true"] {
            color: #fff;
            background: rgba(255,255,255,0.35);
            font-weight: bold;
        }
        #sidebar .input-group .form-control {
            background: rgba(255,255,255,0.15);
            border: none;
            color: white;
            border-radius: 5px;
        }
        #sidebar .input-group .form-control::placeholder {
            color: rgba(255,255,255,0.7);
        }
        #sidebar .input-group .btn {
            background: rgba(255,255,255,0.15);
            border: none;
            color: white;
            border-radius: 5px;
        }
        #sidebar ul.components ul a { /* Submenu styles */
            font-size: 0.9em !important;
            padding-left: 30px !important;
            background: rgba(0,0,0,0.1);
        }
        #sidebar ul.components ul a:hover {
            background: rgba(0,0,0,0.2);
        }

        /* Content Area */
        #content {
            flex-grow: 1;
            padding: 20px 30px;
            transition: all 0.3s;
            position: relative;
        }

        /* Top Navbar */
        .navbar-top {
            background-color: #ffffff;
            border-radius: 12px;
            box-shadow: 0 4px 15px rgba(0,0,0,0.08);
            margin-bottom: 30px;
            padding: 15px 25px;
        }
        .navbar-top .navbar-brand {
            font-weight: bold;
            color: #333;
            font-size: 1.3em; /* Sedikit lebih besar untuk judul aplikasi */
            display: flex; /* Untuk rata tengah vertikal ikon */
            align-items: center;
        }
        .navbar-top .navbar-brand i {
            margin-right: 8px; /* Jarak antara ikon dan teks */
            color: #36D1DC; /* Warna ikon */
        }
        .navbar-top .nav-link {
            color: #555;
            font-size: 1.05em;
            padding: 8px 12px;
            border-radius: 8px;
            transition: all 0.2s;
        }
        .navbar-top .nav-link:hover {
            background-color: #f0f2f5;
            color: #36D1DC;
        }
        .navbar-top .nav-link i {
            margin-right: 5px;
        }

        /* Card Styling */
        .card {
            border-radius: 15px;
            box-shadow: 0 8px 25px rgba(0,0,0,0.1);
            margin-bottom: 25px;
            border: none;
            overflow: hidden;
        }
        .card-header {
            background-color: #ffffff; /* Ubah ke putih */
            border-bottom: 1px solid #e9ecef;
            font-weight: 600;
            color: #333;
            padding: 15px 20px;
            font-size: 1.1em; /* Sedikit lebih besar */
        }
        .info-card .card-body {
            text-align: center;
            padding: 25px 20px;
            color: white;
            min-height: 120px; /* Tambahkan min-height agar konsisten */
            display: flex;
            flex-direction: column;
            justify-content: center;
            align-items: center;
        }
        .info-card .card-title {
            font-size: 2.5em; /* Lebih besar */
            font-weight: bold;
            margin-bottom: 8px; /* Tambah margin */
            line-height: 1; /* Rapat untuk angka besar */
        }
        .info-card .card-text {
            font-size: 1.1em;
            opacity: 0.9;
        }
        .info-card.total-siswa { background: linear-gradient(to right, #36D1DC, #5B86E5); }
        .info-card.presensi-today { background: linear-gradient(to right, #5B86E5, #36D1DC); }
        .info-card.status-sistem { background: linear-gradient(to right, #36D1DC, #5B86E5); }
        .info-card .card-icon {
            font-size: 3em;
            margin-bottom: 10px;
        }

        /* Kalender Presensi */
        #calendar-container table {
            width: 100%;
            table-layout: fixed; /* Membuat sel tabel memiliki lebar yang sama */
        }
        #calendar-container th, #calendar-container td {
            padding: 8px 5px; /* Sesuaikan padding */
            font-size: 0.9em;
            border: 1px solid #dee2e6; /* Border yang lebih jelas */
        }
        #calendar-container th {
            background-color: #e9ecef;
            font-weight: 600;
            color: #555;
        }
        #calendar-container td {
            height: 40px; /* Tinggi sel untuk konsistensi */
            vertical-align: middle;
        }
        #calendar-container td:hover {
            background-color: #f5f5f5;
            cursor: pointer;
        }
        #calendar-container .btn-sm {
            padding: 0.35rem 0.7rem; /* Sesuaikan ukuran tombol navigasi kalender */
        }

        /* Lokasi Presensi */
        .card img {
            border-radius: 10px; /* Sudut lebih lembut untuk gambar */
        }

        /* Responsive adjustments */
        @media (max-width: 768px) {
            #sidebar {
                margin-left: -280px;
                position: fixed;
                top: 0;
                left: 0;
                height: 100vh;
                z-index: 1050; /* Z-index lebih tinggi untuk mobile overlay */
            }
            #sidebar.active {
                margin-left: 0;
            }
            #content {
                width: 100%;
                padding: 20px;
            }
            #sidebarCollapse {
                display: block;
                position: absolute; /* Posisikan tombol agar tidak mengganggu tata letak */
                top: 15px;
                left: 15px;
                z-index: 1040; /* Di atas konten tapi di bawah sidebar active */
            }
            .navbar-top .navbar-brand {
                margin-left: auto; /* Push brand to right on small screen */
                font-size: 1.1em;
            }
            .navbar-top .navbar-toggler {
                order: -1; /* Pindahkan tombol collapse ke kiri */
            }
            .info-card .card-title {
                font-size: 2em; /* Sesuaikan ukuran font untuk mobile */
            }
            .info-card .card-icon {
                font-size: 2.5em;
            }
        }
        
    </style>
</head>
<body>
    <div class="wrapper">
        <nav id="sidebar">
            <div class="sidebar-header">
                <img src="https://i.ibb.co/L5yY5hN/map-example.png" alt="Profile" class="profile-img">
                <h3>SISTEM INFORMASI PRESENSI (SIP)</h3> <p>SMK Bakti Nusantara 666</p> <p>Halo, Admin!</p> </div>

            <ul class="list-unstyled components">
                <li>
                    <div class="input-group mb-4">
                        <input type="text" class="form-control" placeholder="Cari..." aria-label="Cari">
                        <button class="btn btn-secondary" type="button"><i class="fas fa-search"></i></button>
                    </div>
                </li>
                <li class="active">
                    <a href="dashboard.php">
                        <i class="fas fa-chart-line"></i> Dashboard
                    </a>
                </li>
                <li>
                    <a href="#dataSubmenu" data-bs-toggle="collapse" aria-expanded="false" class="dropdown-toggle">
                        <i class="fas fa-database"></i> Data Master
                    </a>
                    <ul class="collapse list-unstyled" id="dataSubmenu">
                        <li><a href="data_master/data_siswa.php"><i class="fas fa-user-graduate"></i> Data Siswa</a></li>
                        <li><a href="data_master/kelola_rfid.php"><i class="fas fa-id-card"></i> Data RFID</a></li>
                        <li><a href="#"><i class="fas fa-school"></i> Data Kelas</a></li>
                        <li><a href="#"><i class="fas fa-calendar-alt"></i> Data Jadwal</a></li>
                    </ul>
                </li>
                <li>
                    <a href="#presensiSubmenu" data-bs-toggle="collapse" aria-expanded="false" class="dropdown-toggle">
                        <i class="fas fa-clipboard-check"></i> Data Presensi
                    </a>
                    <ul class="collapse list-unstyled" id="presensiSubmenu">
                        <li><a href="presensi/log_harian.php"><i class="fas fa-list-alt"></i> Log Presensi Harian</a></li>
                        <li><a href="#"><i class="fas fa-chart-bar"></i> Laporan Presensi</a></li>
                    </ul>
                </li>
                <li>
                    <a href="#pengaturanSubmenu" data-bs-toggle="collapse" aria-expanded="false" class="dropdown-toggle">
                        <i class="fas fa-cog"></i> Pengaturan
                    </a>
                    <ul class="collapse list-unstyled" id="pengaturanSubmenu">
                        <li><a href="#"><i class="fas fa-user-circle"></i> Pengaturan Akun</a></li>
                        <li><a href="#"><i class="fas fa-cogs"></i> Pengaturan Sistem</a></li>
                    </ul>
                </li>
                <li>
                    <a href="#">
                        <i class="fas fa-sign-out-alt"></i> Logout
                    </a>
                </li>
            </ul>
        </nav>

        <div id="content">
            <nav class="navbar navbar-expand-lg navbar-light navbar-top">
                <div class="container-fluid">
                    <button type="button" id="sidebarCollapse" class="btn btn-info d-block d-md-none">
                        <i class="fas fa-align-left"></i>
                    </button>
                    <a class="navbar-brand ms-auto me-2" href="#">
                        <i class="fas fa-fingerprint"></i> SISTEM INFORMASI PRESENSI
                    </a> 
                    <ul class="navbar-nav">
                        <li class="nav-item me-2">
                            <a class="nav-link" href="#"><i class="fas fa-envelope"></i></a>
                        </li>
                        <li class="nav-item me-2">
                            <a class="nav-link" href="#"><i class="fas fa-bell"></i></a>
                        </li>
                        <li class="nav-item">
                            <a class="nav-link" href="#"><i class="fas fa-user-circle"></i> Admin</a> </li>
                    </ul>
                </div>
            </nav>
            <h1 class="mb-4">Dashboard Utama</h1> <div class="row">
                <div class="col-md-4">
                    <div class="card info-card total-siswa">
                        <div class="card-body">
                            <i class="fas fa-users card-icon"></i> <h5 class="card-title"><?php echo $total_siswa; ?></h5>
                            <p class="card-text">Jumlah Siswa Terdaftar</p> </div>
                    </div>
                </div>
                <div class="col-md-4">
                    <div class="card info-card presensi-today">
                        <div class="card-body">
                            <i class="fas fa-check-circle card-icon"></i> <h5 class="card-title"><?php echo $presensi_hari_ini; ?></h5>
                            <p class="card-text">Total Presensi Hari Ini</p> </div>
                    </div>
                </div>
                <div class="col-md-4">
                    <div class="card info-card status-sistem">
                        <div class="card-body">
                            <i class="fas fa-power-off card-icon"></i> <h5 class="card-title">Sistem Aktif</h5> <p class="card-text">Status Operasional</p>
                        </div>
                    </div>
                </div>
            </div>

            <div class="row">
                <div class="col-lg-8">
                    <div class="card">
                        <div class="card-header">Grafik Presensi Harian</div>
                        <div class="card-body">
                            <canvas id="presensiChart"></canvas>
                        </div>
                    </div>
                </div>
                <div class="col-lg-4">
                    <div class="card">
                        <div class="card-header">Kalender Presensi</div>
                        <div class="card-body">
                            <div id="calendar-container">
                                <div class="d-flex justify-content-between align-items-center mb-3">
                                    <button class="btn btn-sm btn-outline-secondary" id="prevMonth"><i class="fas fa-chevron-left"></i></button>
                                    <h5 id="currentMonthYear"><?php echo date('F Y'); ?></h5>
                                    <button class="btn btn-sm btn-outline-secondary" id="nextMonth"><i class="fas fa-chevron-right"></i></button>
                                </div>
                                <table class="table table-bordered table-sm text-center mb-0"> <thead>
                                        <tr>
                                            <th>Min</th><th>Sen</th><th>Sel</th><th>Rab</th><th>Kam</th><th>Jum</th><th>Sab</th>
                                        </tr>
                                    </thead>
                                    <tbody id="calendarBody">
                                        </tbody>
                                </table>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            <div class="row">
                <div class="col-12">
                    <div class="card">
                        <div class="card-header">Peta Lokasi Presensi</div> <div class="card-body">
                            <p class="text-muted">Peta lokasi presensi sekolah dapat diintegrasikan di sini.</p> <img src="https://i.ibb.co/L5yY5hN/map-example.png" alt="Contoh Peta Lokasi" class="img-fluid rounded" style="max-height: 350px; width: 100%; object-fit: cover;">
                        </div>
                    </div>
                </div>
            </div>

        </div> </div> <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js" integrity="sha384-YvpcrYf0tY3lHB60NNkmXc5s9fDVZLESaAA55NDzOxhy9GkcIdslK1eN7N6jIeHz" crossorigin="anonymous"></script>
    <script src="https://cdn.jsdelivr.net/npm/chart.js@3.7.0/dist/chart.min.js"></script>
    <script>
        // JS untuk toggle sidebar (untuk mobile/tablet)
        document.addEventListener('DOMContentLoaded', function() {
            var sidebarCollapse = document.getElementById('sidebarCollapse');
            if (sidebarCollapse) {
                sidebarCollapse.addEventListener('click', function() {
                    document.getElementById('sidebar').classList.toggle('active');
                    document.getElementById('content').classList.toggle('active');
                });
            }

            // Data untuk Grafik Presensi Harian (Contoh Statis)
            var presensiData = {
                labels: ['07:00', '08:00', '09:00', '10:00', '11:00', '12:00', '13:00', '14:00', '15:00'],
                datasets: [{
                    label: 'Jumlah Presensi Masuk',
                    data: [15, 25, 10, 5, 2, 0, 0, 0, 0], // Contoh data
                    backgroundColor: 'rgba(54, 209, 220, 0.7)',
                    borderColor: 'rgba(54, 209, 220, 1)',
                    borderWidth: 1,
                    fill: true,
                    tension: 0.4
                },
                {
                    label: 'Jumlah Presensi Pulang',
                    data: [0, 0, 0, 0, 3, 8, 12, 20, 10], // Contoh data
                    backgroundColor: 'rgba(91, 134, 229, 0.7)',
                    borderColor: 'rgba(91, 134, 229, 1)',
                    borderWidth: 1,
                    fill: true,
                    tension: 0.4
                }]
            };

            var ctx = document.getElementById('presensiChart');
            if (ctx) { // Pastikan elemen canvas ada
                var presensiChart = new Chart(ctx, {
                    type: 'line', // Atau 'bar'
                    data: presensiData,
                    options: {
                        responsive: true,
                        maintainAspectRatio: false, // Penting untuk kontrol ukuran canvas
                        scales: {
                            y: {
                                beginAtZero: true,
                                title: {
                                    display: true,
                                    text: 'Jumlah Presensi'
                                }
                            },
                            x: {
                                title: {
                                    display: true,
                                    text: 'Waktu'
                                }
                            }
                        },
                        plugins: {
                            legend: {
                                display: true,
                                position: 'top',
                            },
                            title: {
                                display: true,
                                text: 'Distribusi Presensi per Jam Hari Ini'
                            }
                        }
                    }
                });
            }

            // JavaScript untuk Kalender Dinamis
            let currentCalendarDate = new Date();

            function generateCalendar(date) {
                const year = date.getFullYear();
                const month = date.getMonth(); // 0-indexed (Jan = 0)

                const firstDayOfMonth = new Date(year, month, 1);
                const daysInMonth = new Date(year, month + 1, 0).getDate(); // Get last day of month

                // Get day of the week for the first day (0=Sunday, 6=Saturday)
                // Adjust to start on Monday (1=Monday, ..., 0=Sunday)
                let startDay = firstDayOfMonth.getDay();
                if (startDay === 0) startDay = 7; // Convert Sunday (0) to 7 for Monday-based week

                let calendarHtml = '';
                let dayCounter = 1;

                // Create rows for weeks
                for (let i = 0; i < 6; i++) { // Max 6 weeks in a month view
                    let rowHtml = '<tr>';
                    let hasDaysInRow = false; // To check if row has any days

                    // Fill leading empty cells if month doesn't start on Monday
                    for (let j = 1; j <= 7; j++) {
                        if (i === 0 && j < startDay) {
                            rowHtml += '<td></td>';
                        } else if (dayCounter <= daysInMonth) {
                            const today = new Date();
                            const isToday = (dayCounter === today.getDate() && month === today.getMonth() && year === today.getFullYear());
                            rowHtml += `<td class="${isToday ? 'fw-bold bg-primary text-white rounded-circle' : ''}" style="width: 14.28%;">${dayCounter}</td>`;
                            dayCounter++;
                            hasDaysInRow = true;
                        } else {
                            rowHtml += '<td></td>';
                        }
                    }
                    rowHtml += '</tr>';
                    if (hasDaysInRow) { // Only add row if it contains days
                        calendarHtml += rowHtml;
                    } else if (i > 0 && dayCounter > daysInMonth) { // Break if no more days for subsequent rows
                        break;
                    }
                }

                document.getElementById('calendarBody').innerHTML = calendarHtml;
                document.getElementById('currentMonthYear').textContent = date.toLocaleString('id-ID', { month: 'long', year: 'numeric' });
            }

            document.getElementById('prevMonth').addEventListener('click', function() {
                currentCalendarDate.setMonth(currentCalendarDate.getMonth() - 1);
                generateCalendar(currentCalendarDate);
            });

            document.getElementById('nextMonth').addEventListener('click', function() {
                currentCalendarDate.setMonth(currentCalendarDate.getMonth() + 1);
                generateCalendar(currentCalendarDate);
            });

            // Initial calendar load
            generateCalendar(currentCalendarDate);
        });
    </script>
</body>
</html>