#include <bluefruit.h>
#include <Arduino.h>

#define MANUFACTURER_ID   0x0059 // Nordic

uint8_t beaconUuid[16] = {
  0x01, 0x12, 0x23, 0x34, 0x45, 0x56, 0x67, 0x78,
  0x89, 0x9a, 0xab, 0xbc, 0xcd, 0xde, 0xef, 0xf0
};

// A valid Beacon packet consists of the following information:
// UUID, Major, Minor, RSSI @ 1M
BLEBeacon beacon(beaconUuid, 1, 2, -54);

void init_ble();
void startAdv();
uint8_t setAdvertisementKey(const char *key, uint8_t **bleAddr, uint8_t **data);