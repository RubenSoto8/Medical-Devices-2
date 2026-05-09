#include <Wire.h>
#include "MAX30105.h"
#include "spo2_algorithm.h"

#define SDA_PIN    8
#define SCL_PIN    9
#define BT_RX_PIN  18   
#define BT_TX_PIN  17   

uint32_t irBuffer[100];
uint32_t redBuffer[100];
int32_t  spo2;
int8_t   validSPO2;
int32_t  heartRate;
int8_t   validHeartRate;

void setup() {
  Serial.begin(115200);
  Serial2.begin(9600, SERIAL_8N1, BT_RX_PIN, BT_TX_PIN);
  Wire.begin(SDA_PIN, SCL_PIN);

  if (!particleSensor.begin(Wire, I2C_SPEED_FAST)) {
    Serial.println("MAX30102 no encontrado.");
    while (true);
  }

  particleSensor.setup(30, 4, 2, 100, 411, 4096);

  Serial.println("Estabilizando sensor...");
  for (int i = 0; i < 500; i++) {
    while (!particleSensor.available()) particleSensor.check();
    particleSensor.nextSample();
  }

  for (byte i = 0; i < 100; i++) {
    while (!particleSensor.available()) particleSensor.check();
    redBuffer[i] = particleSensor.getRed();
    irBuffer[i]  = particleSensor.getIR();
    particleSensor.nextSample();
  }

  Serial.println("Listo.");
}

void loop() {
  maxim_heart_rate_and_oxygen_saturation(
    irBuffer, 100, redBuffer,
    &spo2, &validSPO2,
    &heartRate, &validHeartRate
  );

  String msg = "";
  msg += "HR:"   + String((validHeartRate && heartRate >= 50 && heartRate <= 180) ? heartRate : -1);
  msg += "|SPO2:" + String((validSPO2 && spo2 >= 80 && spo2 <= 100)               ? spo2      : -1);

  Serial2.println(msg);   
  Serial.println(msg);   
  
  for (byte i = 25; i < 100; i++) {
    redBuffer[i - 25] = redBuffer[i];
    irBuffer[i - 25]  = irBuffer[i];
  }
  for (byte i = 75; i < 100; i++) {
    while (!particleSensor.available()) particleSensor.check();
    redBuffer[i] = particleSensor.getRed();
    irBuffer[i]  = particleSensor.getIR();
    particleSensor.nextSample();
  }
}