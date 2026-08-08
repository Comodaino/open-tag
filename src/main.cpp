#include <Arduino.h>
#include <bluefruit.h>
#include <GxEPD2_BW.h> // Base classes
#include <GxEPD2_3C.h> // Color classes
#include <GxEPD2_4C.h> // 4-Color classes (Required for the 1.54" G)
#include <Fonts/FreeSans9pt7b.h> // Example Adafruit font
#include "imagemap.h"
// Define your SPI and control pins for the nice!nano (change these to match your wiring)
#define EPD_CS   PIN_113  // Chip Select //113
#define EPD_DC   PIN_009  // Data/Command //9
#define EPD_RST  PIN_104  // Reset
#define EPD_BUSY PIN_106  // Busy

#define LED PIN_015 //Set a definiton on pin P0.15 called "LED".

GxEPD2_4C<GxEPD2_154c_GDEM0154F51H, GxEPD2_154c_GDEM0154F51H::HEIGHT> display(
  GxEPD2_154c_GDEM0154F51H(/*CS=*/ EPD_CS, /*DC=*/ EPD_DC, /*RST=*/ EPD_RST, /*BUSY=*/ EPD_BUSY)
);


void setup() {
  display.init();
  display.setFullWindow();
  display.firstPage();

  display.fillScreen(GxEPD_WHITE);
  display.drawBitmap(0, 0, epd_bitmap_black,  200, 200, GxEPD_BLACK);
  display.drawBitmap(0, 0, epd_bitmap_red,    200, 200, GxEPD_RED);
  display.drawBitmap(0, 0, epd_bitmap_yellow, 200, 200, GxEPD_YELLOW);
  display.nextPage();

  display.hibernate();
}

void loop() {

}