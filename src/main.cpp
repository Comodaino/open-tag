#include <Arduino.h>
#include <bluefruit.h>
#include <GxEPD2_BW.h> // Base classes
#include <GxEPD2_3C.h> // Color classes
#include <GxEPD2_4C.h> // 4-Color classes (Required for the 1.54" G)
#include <Fonts/FreeSans9pt7b.h> // Example Adafruit font
#include "imagemap.h"
// Define your SPI and control pins for the nice!nano (change these to match your wiring)
#define EPD_CS   10 // Chip Select
#define EPD_DC   9  // Data/Command
#define EPD_RST  8  // Reset
#define EPD_BUSY 6  // Busy
#define MAX_KEYS 20
#define MANUFACTURER_ID   0x004c
static uint8_t addr[6] = {0xFF, 0xBB, 0xCC, 0xDD, 0xEE, 0xFF};

static uint8_t offline_finding_adv_template[] = {
	0x1e,		/* Length (30) */
	0xff,		/* Manufacturer Specific Data (type 0xff) */
	0x4c, 0x00, /* Company ID (Apple) */
	0x12, 0x19, /* Offline Finding type and length */
	0x00,		/* State */
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x00, /* First two bits */
	0x00, /* Hint (0x00) */
};

uint8_t beaconUuid[16] = {
  0x01, 0x12, 0x23, 0x34, 0x45, 0x56, 0x67, 0x78,
  0x89, 0x9a, 0xab, 0xbc, 0xcd, 0xde, 0xef, 0xf0
};
BLEBeacon beacon(beaconUuid, 1, 2, -54);
int last_filled_index = -1;
int current_index = 0;
static char public_key[MAX_KEYS][28] = { 
    "OFFLINEFINDINGPUBLICKEYHERE",
};
uint8_t *raw_data;
// Initialize the display class for the 1.54" G (4-color, 200x200, JD79660 controller)
GxEPD2_4C<GxEPD2_154c_GDEM0154F51H, GxEPD2_154c_GDEM0154F51H::HEIGHT> display(
  GxEPD2_154c_GDEM0154F51H(/*CS=*/ EPD_CS, /*DC=*/ EPD_DC, /*RST=*/ EPD_RST, /*BUSY=*/ EPD_BUSY)
);

void init_ble(){
  Bluefruit.begin();
  Bluefruit.setName("AMO I PIEDI");

  // off Blue LED for lowest power consumption
  Bluefruit.autoConnLed(false);
  Bluefruit.setTxPower(0);    // Check bluefruit.h for supported values

  // Manufacturer ID is required for Manufacturer Specific Data
  beacon.setManufacturer(MANUFACTURER_ID);
}

void key_change_timer_config(){
  return;
}

void battery_status_update_timer_config() {

}


void startAdv()
{  
  // Advertising packet
  // Set the beacon payload using the BLEBeacon class populated
  // earlier in this example
  Bluefruit.Advertising.setBeacon(beacon);

  // Secondary Scan Response packet (optional)
  // Since there is no room for 'Name' in Advertising packet
  Bluefruit.ScanResponse.addName();

  Bluefruit.Advertising.setType(BLE_GAP_ADV_TYPE_NONCONNECTABLE_SCANNABLE_UNDIRECTED);
  Bluefruit.Advertising.restartOnDisconnect(true);
  Bluefruit.Advertising.setInterval(160, 160);    // in unit of 0.625 ms
  Bluefruit.Advertising.setFastTimeout(30);      // number of seconds in fast mode
  Bluefruit.Advertising.start(0);                // 0 = Don't stop advertising after n seconds  
}

void set_addr_from_key(const char *key)
{
	/* copy first 6 bytes */
	addr[5] = key[0] | 0b11000000;
	addr[4] = key[1];
	addr[3] = key[2];
	addr[2] = key[3];
	addr[1] = key[4];
	addr[0] = key[5];
}

/*
 * fill_adv_template_from_key will set the advertising data based on the remaining bytes from the advertised key
 */
void fill_adv_template_from_key(const char *key)
{

	size_t key_size = 28;
	char key_hex[28 * 5 + 1];

	// Ausgabe des key-Arrays als Hexadezimalwerte
	for (size_t i = 0; i < key_size; i++)
	{
		snprintf(&key_hex[i * 5], 6, "0x%02X,", (unsigned char)key[i]);
	}

	memcpy(&offline_finding_adv_template[7], &key[6], 22);
	/* append two bits of public key */

	size_t offline_finding_adv_template_size = sizeof(offline_finding_adv_template);

	// Erstellen eines String-Puffers, der groß genug ist, um das Array aufzunehmen
	char string_buffer[offline_finding_adv_template_size * 5 + 1]; // Jeder Wert benötigt bis zu 4 Zeichen und ein Nullterminator

	// Umwandeln des offline_finding_adv_template-Arrays in einen String
	for (size_t i = 0; i < offline_finding_adv_template_size; i++)
	{
		snprintf(&string_buffer[i * 5], 6, "0x%02X,", offline_finding_adv_template[i]);
	}

	printf("%s\n", string_buffer);
	offline_finding_adv_template[29] = key[0] >> 6;
}



uint8_t setAdvertisementKey(const char *key, uint8_t **bleAddr, uint8_t **data)
{
    set_addr_from_key(key);
	  fill_adv_template_from_key(key);

    *bleAddr = (uint8_t*)malloc(sizeof(addr));
    memcpy(*bleAddr, addr, sizeof(addr));

    *data = (uint8_t*)malloc(sizeof(offline_finding_adv_template));
    memcpy(*data, offline_finding_adv_template, sizeof(offline_finding_adv_template));

    return sizeof(offline_finding_adv_template);
}

void setAndAdvertiseNextKey(){
    // Variable to hold the data to advertise
    uint8_t *ble_address;
    uint8_t data_len;

    // Disable advertising
    Bluefruit.Advertising.stop();
    Bluefruit.Advertising.clearData();

    // Update key index for next advertisement...Back to zero if out of range
    current_index = (current_index + 1) % (last_filled_index + 1); 
    
    // Set key to be advertised
    data_len = setAdvertisementKey(public_key[current_index], &ble_address, &raw_data);

    // Set bluetooth address
    //setMacAddress(ble_address); TODO MODIFY

    // Update battery information
    //updateBatteryLevel(raw_data);

    // Set advertisement data
    Bluefruit.Advertising.setData(raw_data, data_len);

    // Start advertising
    startAdv(); //TODO add variable interval
}

void setup() {
  Serial.begin(115200);

  // Initialize the display
  display.init(115200);
  
  // Set orientation (0, 1, 2, or 3)
  display.setRotation(2);

  display.setFullWindow();
  display.firstPage();
  do {
    // 1. Clear the screen to white
    display.fillScreen(GxEPD_WHITE);
    
    // 2. Draw the black layer
    // Syntax: drawBitmap(x, y, bitmap_array, width, height, color)
    display.drawBitmap(0, 0, epd_bitmap_black, 200, 200, GxEPD_BLACK);
    // 3. Draw the red layer right on top of it
    display.drawBitmap(0, 0, epd_bitmap_red, 200, 200, GxEPD_RED);
    display.drawBitmap(0, 0, epd_bitmap_yellow, 200, 200, GxEPD_YELLOW);
  } while (display.nextPage());
  
  // Put display to sleep to save power
  display.hibernate();


     for (int i = MAX_KEYS - 1; i >= 0; i--)
    {
        if (strlen(public_key[i]) > 0)
        {
            last_filled_index = i;
            break;
        }
    }

    // Init BLE stack and softdevice
    init_ble();
    
    // Only use the app_timer to rotate keys if we need to
    if (last_filled_index > 0){
        key_change_timer_config();
    }
    
    if (last_filled_index >= 0) {
        setAndAdvertiseNextKey();
        battery_status_update_timer_config();
    }
    suspendLoop();
}

void loop() {

}