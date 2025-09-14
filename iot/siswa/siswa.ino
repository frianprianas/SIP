#include <SPI.h>
#include <MFRC522.h>
#include <Wire.h>
#include <LiquidCrystal_I2C.h> // Library untuk LCD 20x4
#include <WiFi.h>
#include <HTTPClient.h>
#include <ArduinoJson.h>    
#include <PubSubClient.h>   

// --- Konfigurasi Hardware ---
#define SS_PIN      5       // Pin SS/SDA untuk modul RFID MFRC522 (GPIO5)
#define RST_PIN     4       // Pin RST untuk modul RFID MFRC522 (GPIO4)
MFRC522 mfrc522(SS_PIN, RST_PIN);   

// 🔥 Konfigurasi LCD 20x4 (Bukan OLED) 🔥
#define LCD_ADDR 0x27       // Alamat I2C untuk LCD 20x4, sesuaikan jika berbeda
LiquidCrystal_I2C lcd(LCD_ADDR, 20, 4); // Inisialisasi objek LCD

#define BUZZER_PIN 16        
#define BUTTON_PIN 13       

// --- Konfigurasi Wi-Fi Anda ---
const char* ssid = "fh_04b1f8";        
const char* password = "wlanfb4e07"; 

// --- Konfigurasi URL Server PHP Anda ---
const char* serverNamePresensi = "http://3.104.65.144/sip/presensi.php"; 
const char* serverNameGetDate = "http://3.104.65.144/sip/get_date.php";

// --- Konfigurasi MQTT ---
const char* mqtt_server = "3.104.65.144"; 
const int mqtt_port = 1883;
const char* mqtt_client_id = "SISWA_01"; // Ganti ID unik untuk siswa
const char* mqtt_topic_camera_trigger = "sip/camera/trigger"; 

WiFiClient espClient;
PubSubClient client(espClient);

// --- Variabel Global untuk Status dan Waktu ---
String selectedAbsenMode = "MASUK"; 

unsigned long lastButtonPressTime = 0;
const long debounceDelay = 200;

unsigned long lastLcdUpdateTime = 0; // Ganti dari lastDisplayUpdateTime
const long lcdUpdateInterval = 1000;

unsigned long lastDateUpdateTime = 0;
const long dateUpdateInterval = 30000;

String currentDateDisplay = "Loading Date...";
String currentTimeDisplay = "Loading Time...";

// --- Variabel untuk Pencegahan Absensi Ganda ---
unsigned long lastAbsenTime = 0;
const long absenCooldown = 5000;
String lastAbsenCardUID = "";

unsigned long lastDisplayChangeTime = 0;
const long displayDuration = 7000;

// 🔥 Hapus variabel dan fungsi yang tidak relevan untuk LCD 🔥
// Variabel Animasi SIP tidak diperlukan di LCD
// Variabel Running Text tidak diperlukan di LCD

// --- Fungsi Kustom untuk Mengontrol Buzzer ---
void tone(int pin, int freq, int duration) {
  digitalWrite(pin, HIGH);
  if(duration > 0) {
    delay(duration);
    noTone(pin);
  }
}
void noTone(int pin) {
  digitalWrite(pin, LOW);
}

// --- Fungsi Bantu: Mengkonversi String Waktu "HH:MM:SS" ke Total Detik ---
int timeToSeconds(String timeStr) {
  if (timeStr.length() != 8 || timeStr.charAt(2) != ':' || timeStr.charAt(5) != ':') {
    return 0;
  }
  int hours = timeStr.substring(0, 2).toInt();
  int minutes = timeStr.substring(3, 5).toInt();
  int seconds = timeStr.substring(6, 8).toInt();
  return hours * 3600 + minutes * 60 + seconds;
}

// --- Fungsi untuk Membaca dan Mengkonversi UID Kartu RFID ---
String readCardUID(byte *buffer, byte bufferSize) {
  String uidString = "";
  for (byte i = 0; i < bufferSize; i++) {
    if (buffer[i] < 0x10) {
      uidString += "0";
    }
    uidString += String(buffer[i], HEX);
  }
  uidString.toUpperCase();
  return uidString;
}

// --- Fungsi Reconnect MQTT ---
void reconnectMqtt() {
  while (!client.connected()) {
    Serial.print("Mencoba koneksi MQTT...");
    if (client.connect(mqtt_client_id)) {
      Serial.println("terhubung!");
    } else {
      Serial.print("gagal, rc=");
      Serial.print(client.state());
      Serial.println(" coba lagi dalam 5 detik");
      delay(5000);
    }
  }
}

// 🔥 Fungsi displayWelcomeScreen diubah untuk LCD 🔥
void displayWelcomeScreen(bool forceUpdate) {
  if (!forceUpdate && millis() - lastLcdUpdateTime < lcdUpdateInterval && lastDisplayChangeTime == 0) {
    return;
  }
  if (lastDisplayChangeTime != 0 && !forceUpdate) {
      return;
  }
  
  if (forceUpdate || millis() - lastLcdUpdateTime >= lcdUpdateInterval) {
    lcd.clear();
    lastLcdUpdateTime = millis();
  }

  lcd.setCursor(0, 0);
  String line0 = "SIP SMK Baknus 666";
  lcd.print(line0);
  
  lcd.setCursor(0, 1);
  String line1 = "Mode : " + selectedAbsenMode;
  lcd.print(line1);
  
  lcd.setCursor(0, 2);
  String line2 = currentDateDisplay;
  lcd.print(line2);

  lcd.setCursor(0, 3);
  String line3 = "Waktu: " + currentTimeDisplay;
  lcd.print(line3);
}

// --- Fungsi untuk Mengambil Tanggal dan Waktu dari Server PHP (get_date.php) ---
void updateDateTimeFromPHP() {
  if (WiFi.status() == WL_CONNECTED) {
    HTTPClient http;
    http.begin(serverNameGetDate);
    http.setTimeout(10000); // 10 detik
    int httpResponseCode = http.GET();
    if (httpResponseCode > 0) {
      String payload = http.getString();
      payload.trim();
      StaticJsonDocument<100> dateDoc;
      DeserializationError error = deserializeJson(dateDoc, payload);
      if (error) {
        currentDateDisplay = "JSON Err!";
        currentTimeDisplay = "Err!";
      } else {
        String datePart = dateDoc["date"].as<String>();
        String timePart = dateDoc["time"].as<String>();
        String dayPart = dateDoc["day"].as<String>();
        String year = datePart.substring(0, 4);
        String month = datePart.substring(5, 7);
        String day = datePart.substring(8, 10);
        currentDateDisplay = dayPart + ", " + day + "-" + month + "-" + year;
        currentTimeDisplay = timePart;
      }
    } else {
      currentDateDisplay = "Server Err!";
      currentTimeDisplay = "Err!";
    }
    http.end();
  } else {
    currentDateDisplay = "WiFi Off!";
    currentTimeDisplay = "Err!";
  }
}

// 🔥 Fungsi sendDataToServer diubah untuk LCD & data siswa 🔥
void sendDataToServer(String rfid_uid, String selectedMode) {
  if (WiFi.status() == WL_CONNECTED) {
    HTTPClient http;
    http.begin(serverNamePresensi);
    http.addHeader("Content-Type", "application/json");
    http.setTimeout(20000); // 20 detik
    DynamicJsonDocument doc(128);
    doc["rfid_uid"] = rfid_uid;
    doc["status"] = selectedMode;
    String requestBody;
    serializeJson(doc, requestBody);
    
    int httpResponseCode = http.POST(requestBody.c_str());
    
    if (httpResponseCode == HTTP_CODE_OK) {
      String response = http.getString();
      StaticJsonDocument<1024> responseDoc;
      DeserializationError error = deserializeJson(responseDoc, response);
      if (error) {
        lcd.clear();
        lcd.setCursor(0,0);
        lcd.print("Server Invalid!");
        lcd.setCursor(0,1);
        lcd.print("Cek presensi.php!");
        lcd.setCursor(0,2);
        lcd.print(String(error.c_str()).substring(0, 20));
        lcd.setCursor(0,3);
        lcd.print("                    ");
        tone(BUZZER_PIN, 500, 500);
        lastDisplayChangeTime = millis();
      } else {
        String statusResponse = responseDoc["status"];
        String message = responseDoc["message"];
        
        if (statusResponse == "SUCCESS") {
          String nis = responseDoc["data"]["nis"].as<String>(); // Ganti nipy jadi nis
          String nama = responseDoc["data"]["nama"].as<String>();
          String kelas = responseDoc["data"]["kelas"].as<String>(); // Tambahkan kelas
          String statusKehadiranDB = responseDoc["data"]["status_kehadiran"].as<String>();
          String serverTimeStr = responseDoc["data"]["server_time"].as<String>();
          String jadwalMasukStr = responseDoc["data"]["jadwal_masuk"].as<String>();
          String jadwalPulangStr = responseDoc["data"]["jadwal_pulang"].as<String>();
          String id_kehadiran = responseDoc["data"]["id_kehadiran"].as<String>();
          
          currentDateDisplay = serverTimeStr.substring(8, 10) + "-" + serverTimeStr.substring(5, 7) + "-" + serverTimeStr.substring(0, 4);
          currentTimeDisplay = serverTimeStr.substring(11, 19);
          
          lcd.clear();
          lcd.setCursor(0,0);
          lcd.print("Kehadiran Tercatat!");
          lcd.setCursor(0,1);
          String line1Success = "Nama: " + nama;
          lcd.print(line1Success.substring(0, 20)); // Batasi 20 karakter
          lcd.setCursor(0,2);
          String line2Success = "Kelas: " + kelas; // Tampilkan kelas
          lcd.print(line2Success.substring(0, 20)); 

          String feedbackMessage = "";
          String presensiTimeStr = serverTimeStr.substring(11, 19);
          int presensiTimeInSeconds = timeToSeconds(presensiTimeStr);
          int jadwalMasukInSeconds = timeToSeconds(jadwalMasukStr);
          int jadwalPulangInSeconds = timeToSeconds(jadwalPulangStr);
          
          if (statusKehadiranDB == "MASUK") {
            if (presensiTimeInSeconds > jadwalMasukInSeconds) {
              long diffSeconds = presensiTimeInSeconds - jadwalMasukInSeconds;
              long minutes = diffSeconds / 60;
              long seconds = diffSeconds % 60;
              feedbackMessage = "Terlambat " + String(minutes) + "m " + String(seconds) + "dtk";
            } else {
              feedbackMessage = "Tepat Waktu Masuk!";
            }
          }
          else if (statusKehadiranDB == "PULANG") {
            if (presensiTimeInSeconds < jadwalPulangInSeconds) {
              long diffSeconds = jadwalPulangInSeconds - presensiTimeInSeconds;
              long minutes = diffSeconds / 60;
              long seconds = diffSeconds % 60;
              feedbackMessage = "Pulang kurang " + String(minutes) + "m";
            } else {
              feedbackMessage = "Pulang Tepat Waktu!";
            }
          }
          lcd.setCursor(0,3);
          lcd.print(feedbackMessage.substring(0, 20)); // Batasi 20 karakter
          
          tone(BUZZER_PIN, 2000, 150); delay(200); noTone(BUZZER_PIN);
          tone(BUZZER_PIN, 2000, 150); delay(200); noTone(BUZZER_PIN);
          if (!id_kehadiran.isEmpty()) {
            String mqtt_payload = "{\"id_kehadiran\":\"" + id_kehadiran + "\", \"nis\":\"" + nis + "\", \"nama\":\"" + nama + "\"}"; // Ganti nipy jadi nis
            if (client.publish(mqtt_topic_camera_trigger, mqtt_payload.c_str())) {
              Serial.println("[KAMERA] Pesan MQTT untuk kamera berhasil dikirim!");
            } else {
              Serial.println("[KAMERA] ERROR: Gagal mengirim pesan MQTT. Periksa koneksi broker.");
            }
          } else {
              Serial.println("[KAMERA] ID Kehadiran kosong, tidak mengirim pesan MQTT.");
          }
          lastDisplayChangeTime = millis();
        } else if (statusResponse == "ERROR") {
          lcd.clear();
          lcd.setCursor(0,0);
          lcd.print("GAGAL Absen!");
          lcd.setCursor(0,1);
          String displayMessageLine1 = message.substring(0, 20);
          lcd.print(displayMessageLine1);
          lcd.setCursor(0,2);
          if (message.length() > 20) {
              String displayMessageLine2 = message.substring(20, min((int)message.length(), 40));
              lcd.print(displayMessageLine2);
          }
          lcd.setCursor(0,3);
          lcd.print("Coba Lagi!");
          tone(BUZZER_PIN, 500, 500);
          lastDisplayChangeTime = millis();
        }
      }
    } else {
      lcd.clear();
      lcd.setCursor(0,0);
      lcd.print("Server Error!       ");
      lcd.setCursor(0,1);
      lcd.print("Code: " + String(httpResponseCode));
      lcd.setCursor(0,2);
      lcd.print("Cek Koneksi Server! ");
      lcd.setCursor(0,3);
      lcd.print("                    ");
      tone(BUZZER_PIN, 500, 500);
      lastDisplayChangeTime = millis();
    }
    http.end();
  } else {
    lcd.clear();
    lcd.setCursor(0,0);
    lcd.print("Wi-Fi Disconnect!    ");
    lcd.setCursor(0,1);
    lcd.print("Cek Koneksi          ");
    lcd.setCursor(0,2);
    lcd.print("                    ");
    lcd.setCursor(0,3);
    lcd.print("                    ");
    tone(BUZZER_PIN, 500, 500);
    lastDisplayChangeTime = millis();
  }
}

// --- SETUP ---
void setup() {
  Serial.begin(115200);
  SPI.begin();
  mfrc522.PCD_Init();
  
  pinMode(BUZZER_PIN, OUTPUT);
  digitalWrite(BUZZER_PIN, LOW);
  pinMode(BUTTON_PIN, INPUT_PULLUP);

  lcd.init();
  lcd.backlight();
  
  lcd.setCursor(0,0);
  lcd.print("SIP SMK Baknus 666");
  lcd.setCursor(0,1);
  lcd.print("Inisialisasi WiFi...");
  
  WiFi.begin(ssid, password);
  unsigned long wifiConnectStart = millis();
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    if (millis() - wifiConnectStart > 30000) {
        lcd.clear();
        lcd.setCursor(0,0);
        lcd.print("WiFi GAGAL!          ");
        lcd.setCursor(0,1);
        lcd.print("Cek Router/Pass!    ");
        tone(BUZZER_PIN, 500, 1000); delay(1100); noTone(BUZZER_PIN);
        while(true) delay(10);
    }
  }
  Serial.println("\nWiFi Terhubung!");
  lcd.clear();
  lcd.setCursor(0,0);
  lcd.print("WiFi Terhubung!      ");
  lcd.setCursor(0,1);
  lcd.print("IP: " + WiFi.localIP().toString());
  delay(2000);
  
  updateDateTimeFromPHP(); 
  displayWelcomeScreen(true);

  client.setServer(mqtt_server, mqtt_port);
  Serial.println("MQTT client initialized.");
}

// --- LOOP ---
void loop() {
  if (!client.connected()) {
    reconnectMqtt();
  }
  client.loop();

  if (millis() - lastDisplayChangeTime > displayDuration && lastDisplayChangeTime != 0) {
    displayWelcomeScreen(true);
    lastDisplayChangeTime = 0;
  }
  
  if (millis() - lastDateUpdateTime >= dateUpdateInterval) {
      updateDateTimeFromPHP();
      lastDateUpdateTime = millis();
      displayWelcomeScreen(true);
  }
  
  displayWelcomeScreen(false);

  checkButtonState();

  if (lastDisplayChangeTime != 0) {
    mfrc522.PICC_HaltA();
    mfrc522.PCD_StopCrypto1();
    return;
  }

  if ( ! mfrc522.PICC_IsNewCardPresent()) {
    return;
  }

  if ( ! mfrc522.PICC_ReadCardSerial()) {
    return;
  }

  String uid = readCardUID(mfrc522.uid.uidByte, mfrc522.uid.size);

  if (uid == lastAbsenCardUID && (millis() - lastAbsenTime < absenCooldown)) {
    lcd.clear();
    lcd.setCursor(0, 0);
    lcd.print("Cooldown Aktif!      ");
    lcd.setCursor(0, 1);
    lcd.print("Tunggu " + String((absenCooldown - (millis() - lastAbsenTime)) / 1000) + "s      ");
    lcd.setCursor(0,2);
    lcd.print("                    ");
    lcd.setCursor(0,3);
    lcd.print("                    ");
    tone(BUZZER_PIN, 500, 300);
    lastDisplayChangeTime = millis();
    mfrc522.PICC_HaltA();
    mfrc522.PCD_StopCrypto1();
    return;
  }

  lastAbsenCardUID = uid;
  lastAbsenTime = millis();

  lcd.clear();
  lcd.setCursor(0,0);
  lcd.print("Memproses...        ");
  lcd.setCursor(0,1);
  lcd.print("UID: " + uid.substring(0, min((int)uid.length(), 16)));
  lcd.setCursor(0,2);
  lcd.print("Mode: " + selectedAbsenMode);
  lastDisplayChangeTime = millis();

  sendDataToServer(uid, selectedAbsenMode);

  mfrc522.PICC_HaltA();
  mfrc522.PCD_StopCrypto1();
}

// --- Fungsi untuk Mengecek Status Tombol Fisik ---
void checkButtonState() {
  if (digitalRead(BUTTON_PIN) == LOW) {
    if (millis() - lastButtonPressTime > debounceDelay) {
      if (selectedAbsenMode == "MASUK") {
        selectedAbsenMode = "PULANG";
      } else {
        selectedAbsenMode = "MASUK";
      }
      displayWelcomeScreen(true);
      tone(BUZZER_PIN, 1000, 100); delay(150); noTone(BUZZER_PIN);
      lastButtonPressTime = millis();
    }
  }
}