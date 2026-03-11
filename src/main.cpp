#include <Arduino.h>
#include <GxEPD2_BW.h> // Base classes
#include <GxEPD2_3C.h> // Color classes
#include <GxEPD2_4C.h> // 4-Color classes (Required for the 1.54" G)
#include <Fonts/FreeSans9pt7b.h> // Example Adafruit font

#include "imagemap.h"
#include "ble.h"

// Define your SPI and control pins for the nice!nano (change these to match your wiring)
#define EPD_CS   10 // Chip Select
#define EPD_DC   9  // Data/Command
#define EPD_RST  8  // Reset
#define EPD_BUSY 6  // Busy
#define MAX_KEYS 20

// Initialize the display class for the 1.54" G (4-color, 200x200, JD79660 controller)
GxEPD2_4C<GxEPD2_154c_GDEM0154F51H, GxEPD2_154c_GDEM0154F51H::HEIGHT> display(
  GxEPD2_154c_GDEM0154F51H(/*CS=*/ EPD_CS, /*DC=*/ EPD_DC, /*RST=*/ EPD_RST, /*BUSY=*/ EPD_BUSY)
);

static char public_key[MAX_KEYS][28] = { 
    "OFFLINEFINDINGPUBLICKEYHERE",
};
int last_filled_index = -1;
int current_index = 0;
uint8_t *raw_data;

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
}

void key_change_timer_config(){

}

void setAndAdvertiseNextKey(){

}

void battery_status_update_timer_config(){

}