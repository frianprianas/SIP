#include <Keypad.h>
#include <Wire.h>
#include <LiquidCrystal_I2C.h>
#include <WiFi.h>
#include <HTTPClient.h>
#include <ArduinoJson.h>
#include <esp_system.h>

// --- PIN ---
#define BUZZER_PIN 18
#define RESET_PIN  19

// --- Konfigurasi WiFi ---
const char* ssid     = "SUPPORT IT";
const char* password = "itsupport2023";

// --- Endpoint backend baru ---
String url_api = "http://3.104.65.144/sip/presensi_tombol.php";

// --- Konfigurasi Keypad ---
const byte ROWS = 4;
const byte COLS = 4;
char keys[ROWS][COLS] = {
  {'1','2','3','A'},
  {'4','5','6','B'},
  {'7','8','9','C'},
  {'*','0','#','D'}
};
byte rowPins[ROWS] = {13, 12, 14, 27};
byte colPins[COLS] = {26, 25, 16, 17};
Keypad keypad = Keypad(makeKeymap(keys), rowPins, colPins, ROWS, COLS);

// --- LCD ---
LiquidCrystal_I2C lcd(0x27, 16, 2);

// --- Variabel ---
String nis_nipy = "";
String pass = "";
bool isSiswa = true;
int state = 0; // 0=menu awal, 1=input NIS/NIPY, 2=input Pass, 3=pilih mode
String presensiMode = "";

// --- Running text ---
String runText = "TEKAN A=Siswa, B=Guru/Tendik   ";
int scrollPos = 0;

// --- Forward declaration ---
void updateInput(bool hidden=false);

void setup() {
  Serial.begin(115200);
  lcd.init();
  lcd.backlight();
  pinMode(BUZZER_PIN, OUTPUT);
  pinMode(RESET_PIN, INPUT_PULLUP);

  // koneksi WiFi
  WiFi.begin(ssid, password);
  lcd.setCursor(0,0); lcd.print("Connecting WiFi");
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  lcd.clear();
  lcd.print("WiFi Connected");
  delay(1000);

  showMenu();
}

void loop() {
  if (digitalRead(RESET_PIN) == LOW) {
    resetSystem();
  }

  // jalankan running text di state 0
  if (state == 0) {
    showRunningText();
  }

  char key = keypad.getKey();
  if (key) {
    tone(BUZZER_PIN, 2000, 100);
    Serial.println(key);

    if (state == 0) { // menu utama
      if (key == 'A') { isSiswa = true; startInputNIS(); }
      if (key == 'B') { isSiswa = false; startInputNIS(); }
    }
    else if (state == 1) { // input NIS/NIPY
      if (key == '#') { startInputPass(); }
      else if (key == '*') { if (nis_nipy.length()>0) nis_nipy.remove(nis_nipy.length()-1); updateInput(); }
      else if (isdigit(key)) { nis_nipy += key; updateInput(); }
    }
    else if (state == 2) { // input password
      if (key == '#') { pilihModePresensi(); }
      else if (key == '*') { if (pass.length()>0) pass.remove(pass.length()-1); updateInput(true); }
      else { pass += key; updateInput(true); }
    }
    else if (state == 3) { // pilih mode presensi
      if (key == 'C') { presensiMode = "MASUK"; sendData(); }
      if (key == 'D') { presensiMode = "PULANG"; sendData(); }
    }
  }
}

// ====================== FUNCTION =========================
void showMenu() {
  state = 0;
  lcd.clear();
  lcd.setCursor(0,0);
  lcd.print("SIP SMKBaknus666");
}

void showRunningText() {
  lcd.setCursor(0,1);
  String viewText = runText.substring(scrollPos, scrollPos+16);
  lcd.print(viewText);
  scrollPos++;
  if (scrollPos > runText.length()-16) scrollPos = 0;
  delay(300);
}

void startInputNIS() {
  state = 1;
  nis_nipy = "";
  lcd.clear();
  lcd.print(isSiswa ? "NIS:" : "NIPY:");
}

void startInputPass() {
  state = 2;
  pass = "";
  lcd.clear();
  lcd.print("Password:");
}

void pilihModePresensi() {
  state = 3;
  lcd.clear();
  lcd.setCursor(0,0); lcd.print("Pilih Mode:");
  lcd.setCursor(0,1); lcd.print("C=Masuk D=Pulang");
}

void updateInput(bool hidden) {
  lcd.setCursor(0,1);
  lcd.print("                ");
  lcd.setCursor(0,1);
  if (state == 1) lcd.print(nis_nipy);
  else if (state == 2) {
    if (hidden) {
      for (int i=0; i<pass.length(); i++) lcd.print("*");
    } else {
      lcd.print(pass);
    }
  }
}

void sendData() {
  if (WiFi.status() == WL_CONNECTED) {
    HTTPClient http;
    http.begin(url_api);
    http.addHeader("Content-Type", "application/x-www-form-urlencoded");

    String postData = (isSiswa ? "role=siswa&nis=" + nis_nipy : "role=guru&nipy=" + nis_nipy);
    postData += "&password=" + pass;
    postData += "&mode=" + presensiMode;

    int httpCode = http.POST(postData);
    String payload = http.getString();

    Serial.println("HTTP Code: " + String(httpCode));
    Serial.println("Payload: " + payload);

    lcd.clear();
    if (httpCode == 200 && payload.indexOf("ok") >= 0) {
      StaticJsonDocument<256> doc;
      DeserializationError error = deserializeJson(doc, payload);
      if (!error) {
        String role = doc["role"] | "";
        String nama = doc["nama"] | "";
        String id = "";
        if (role == "siswa") {
          id = doc["nis"] | "";
        } else if (role == "guru") {
          id = doc["nipy"] | "";
        }
        lcd.print(id);
        lcd.setCursor(0,1);
        lcd.print(nama);
      } else {
        lcd.print("Presensi " + presensiMode);
        lcd.setCursor(0,1);
        lcd.print("Berhasil");
      }
      tone(BUZZER_PIN, 1500, 500); // beep panjang
    } else if (httpCode == -11) {
      lcd.print("Coba Cek WA/");
      lcd.setCursor(0,1);
      lcd.print("Jika gagal coba lagi");
      tone(BUZZER_PIN, 1500, 500); // beep panjang
    } else {
      lcd.print("Presensi Gagal");
      for(int i=0;i<3;i++){ tone(BUZZER_PIN, 800, 100); delay(200); } // beep 3x
    }

    http.end();
  } else {
    lcd.clear();
    lcd.print("WiFi Error");
  }

  delay(2000);
  showMenu();
}

void resetSystem() {
  tone(BUZZER_PIN, 1000, 200);
  delay(300);
  ESP.restart(); // restart ESP32
}



