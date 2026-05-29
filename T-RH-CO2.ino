#include <Wire.h>
#include <SPI.h>
#include <SD.h>

#include <Adafruit_SHT4x.h>
#include <SensirionI2cScd30.h>

// --------------------
// SD CARD
// --------------------
const int chipSelect = 10;

// --------------------
// SHT40 & SCD30 SENSORS
// --------------------
Adafruit_SHT4x sht4 = Adafruit_SHT4x();
SensirionI2cScd30 scd30;

// --------------------
// SETUP
// --------------------
void setup() {
  Serial.begin(9600);
  delay(2000);

  Serial.println(F("Starting Dual Sensor Monitor..."));

  Wire.begin();

  // SHT40 INIT
  if (!sht4.begin()) {
    Serial.println(F("SHT40 not found"));
    while (1);
  }
  Serial.println(F("SHT40 OK"));

  // SCD30 INIT
  scd30.begin(Wire, 0x61);
  scd30.startPeriodicMeasurement(0); 
  Serial.println(F("SCD30 OK"));

  // SD CARD INIT
  if (!SD.begin(chipSelect)) {
    Serial.println(F("SD fail"));
    while (1);
  }
  Serial.println(F("SD OK"));

  // CREATE CSV HEADER (Updated with both sensors)
  if (!SD.exists("data.csv")) {
    File dataFile = SD.open("data.csv", FILE_WRITE);
    if (dataFile) {
      // הכותרות החדשות משקפות איזה חיישן מדד מה
      dataFile.println(F("Time_ms,Temp_SHT40,RH_SHT40,Temp_SCD30,RH_SCD30,CO2_SCD30"));
      dataFile.close();
      Serial.println(F("Header created with dual sensor columns."));
    }
  }
  
  Serial.println(F("Setup done"));
}

// --------------------
// LOOP
// --------------------
void loop() {
  // 1. Read T/RH from the SHT40 sensor
  sensors_event_t humidity_sht40, temp_sht40;
  sht4.getEvent(&humidity_sht40, &temp_sht40);

  // 2. Wait and Read CO2/T/RH from the SCD30 sensor
  uint16_t dataReady = 0;
  while (!dataReady) {
    scd30.getDataReady(dataReady);
    delay(10); 
  }

  float co2_scd30 = 0;
  float temp_scd30 = 0;
  float humidity_scd30 = 0;
  scd30.readMeasurementData(co2_scd30, temp_scd30, humidity_scd30);

  // Capture timestamp
  unsigned long timestamp = millis();

  // 3. Serial.println to serial (for real-time tracking)
  Serial.print(F("[Time: ")); Serial.print(timestamp); Serial.println(F(" ms]"));
  Serial.print(F("SHT40 -> Temp: ")); Serial.print(temp_sht40.temperature); Serial.print(F(" C | RH: ")); Serial.print(humidity_sht40.relative_humidity); Serial.println(F(" %"));
  Serial.print(F("SCD30 -> Temp: ")); Serial.print(temp_scd30); Serial.print(F(" C | RH: ")); Serial.print(humidity_scd30); Serial.print(F(" % | CO2: ")); Serial.print(co2_scd30); Serial.println(F(" ppm"));
  Serial.println(F("---------------------------------------------"));

  // 4. Log all 5 parameters to SD card
  File dataFile = SD.open("data.csv", FILE_WRITE);
  if (dataFile) {
    dataFile.print(timestamp);
    dataFile.print(F(","));
    dataFile.print(temp_sht40.temperature);
    dataFile.print(F(","));
    dataFile.print(humidity_sht40.relative_humidity);
    dataFile.print(F(","));
    dataFile.print(temp_scd30);
    dataFile.print(F(","));
    dataFile.print(humidity_scd30);
    dataFile.print(F(","));
    dataFile.println(co2_scd30); // println ends the row
    
    dataFile.close(); 
  } else {
    Serial.println(F("Error opening data.csv"));
  }

  // 5. Delay 30 sec
  delay(30000);
}