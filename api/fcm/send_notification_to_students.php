<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST');
header('Access-Control-Allow-Headers: Content-Type');

require_once __DIR__ . '/../koneksi.php';
require_once __DIR__ . '/fcm_config.php';

function sendFCMBroadcast($deviceTokens, $title, $body, $data = []) {
    global $fcm_server_key;
    
    $url = 'https://fcm.googleapis.com/fcm/send';
    
    $fields = [
        'registration_ids' => $deviceTokens, // Kirim ke multiple tokens sekaligus
        'notification' => [
            'title' => $title,
            'body' => $body,
            'sound' => 'default'
        ],
        'data' => array_merge([
            'title' => $title,
            'body' => $body,
            'screen' => 'presensi'
        ], $data),
        'priority' => 'high',
        'content_available' => true
    ];
    
    $headers = [
        'Authorization: key=' . $fcm_server_key,
        'Content-Type: application/json'
    ];

    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, $url);
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
    curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($fields));
    
    $result = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    
    $response = json_decode($result, true);
    
    if ($httpCode == 200 && isset($response['success'])) {
        return [
            'success' => true, 
            'response' => $response,
            'total_sent' => $response['success'] ?? 0,
            'total_failed' => $response['failure'] ?? 0
        ];
    } else {
        return [
            'success' => false, 
            'error' => $response['error'] ?? 'Unknown FCM error', 
            'http_code' => $httpCode,
            'full_response' => $response
        ];
    }
}

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $input = json_decode(file_get_contents('php://input'), true);
    
    if (!$input) {
        echo json_encode(['success' => false, 'message' => 'Invalid JSON input']);
        exit;
    }
    
    $nisList = $input['nis_list'] ?? [];
    $title = $input['title'] ?? 'Reminder Presensi';
    $message = $input['message'] ?? 'Silahkan untuk melakukan presensi';
    $kelas = $input['kelas'] ?? '';
    
    if (empty($nisList)) {
        echo json_encode(['success' => false, 'message' => 'NIS list is required']);
        exit;
    }
    
    $success = 0;
    $failed = 0;
    $results = [];
    
    try {
        // Ambil FCM token siswa berdasarkan NIS list
        $placeholders = str_repeat('?,', count($nisList) - 1) . '?';
        $stmt = $conn->prepare("SELECT nis, nama, fcm_token FROM siswa WHERE nis IN ($placeholders) AND fcm_token IS NOT NULL AND fcm_token != ''");
        $stmt->bind_param(str_repeat('s', count($nisList)), ...$nisList);
        $stmt->execute();
        $result = $stmt->get_result();
        
        $studentsWithTokens = [];
        $fcmTokens = [];
        while ($row = $result->fetch_assoc()) {
            $studentsWithTokens[] = $row;
            $fcmTokens[] = $row['fcm_token']; // Kumpulkan semua FCM tokens
        }
        
        if (empty($studentsWithTokens)) {
            echo json_encode([
                'success' => false, 
                'message' => 'No students found with FCM tokens',
                'total_targeted' => count($nisList),
                'total_with_tokens' => 0
            ]);
            exit;
        }
        
        // Kirim notifikasi broadcast ke semua siswa sekaligus
        $personalizedMessage = "$message (Kelas: $kelas)";
        $fcmResult = sendFCMBroadcast(
            $fcmTokens, // Array semua FCM tokens
            $title, 
            $personalizedMessage,
            [
                'kelas' => $kelas,
                'total_siswa' => count($studentsWithTokens)
            ]
        );
        
        if ($fcmResult['success']) {
            $success = $fcmResult['total_sent'];
            $failed = $fcmResult['total_failed'];
            
            echo json_encode([
                'success' => true,
                'message' => "Broadcast notification sent to $success students" . ($failed > 0 ? ", failed to $failed students" : ""),
                'total_targeted' => count($nisList),
                'total_with_tokens' => count($studentsWithTokens),
                'sent' => $success,
                'failed' => $failed,
                'broadcast_mode' => true,
                'students' => array_map(function($student) {
                    return [
                        'nis' => $student['nis'],
                        'nama' => $student['nama']
                    ];
                }, $studentsWithTokens)
            ]);
        } else {
            echo json_encode([
                'success' => false,
                'message' => 'Failed to send broadcast notification: ' . $fcmResult['error'],
                'total_targeted' => count($nisList),
                'total_with_tokens' => count($studentsWithTokens),
                'error_details' => $fcmResult
            ]);
        }
        
    } catch (Exception $e) {
        echo json_encode([
            'success' => false,
            'message' => 'Database error: ' . $e->getMessage()
        ]);
    }
} else {
    echo json_encode(['success' => false, 'message' => 'Only POST method allowed']);
}
?>