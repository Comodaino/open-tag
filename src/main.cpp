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

BLEUart bleuart(10*1024);

uint16_t imageWidth = 0;
uint16_t imageHeight = 0;
uint8_t  imageColorBit = 0;

uint32_t totalPixel = 0; // received pixel

// pixel line buffer, should be large enough to hold an image width
unsigned char pixel_buf_b[512];
unsigned char pixel_buf_y[512];
unsigned char pixel_buf_r[512];

// Statistics for speed testing
uint32_t rxStartTime = 0;
uint32_t rxLastTime = 0;

void startAdv(void);
void bleuart_rx_callback(uint16_t conn_hdl);
void connect_callback(uint16_t conn_handle);
void print_summary(uint32_t count, uint32_t ms);
void bleuart_overflow_callback(uint16_t conn_hdl, uint16_t leftover);
void disconnect_callback(uint16_t conn_handle, uint8_t reason);


void setup()
{
  Serial.begin(115200);
  display.init();
  display.setFullWindow();
  display.firstPage();
  memset(pixel_buf_b, 0, sizeof(pixel_buf_b));
  memset(pixel_buf_y, 0, sizeof(pixel_buf_y));
  memset(pixel_buf_r, 0, sizeof(pixel_buf_r));

  // Config the peripheral connection with maximum bandwidth
  // more SRAM required by SoftDevice
  // Note: All config***() function must be called before begin()
  Bluefruit.configPrphBandwidth(BANDWIDTH_MAX);
  Bluefruit.setName("WOW-FUNZIONA");


  Bluefruit.begin();
  Bluefruit.setTxPower(4);    // Check bluefruit.h for supported values

  Bluefruit.Periph.setConnectCallback(connect_callback);
  Bluefruit.Periph.setDisconnectCallback(disconnect_callback);
  Bluefruit.Periph.setConnInterval(6, 12); // 7.5 - 15 ms

  // Configure and Start BLE Uart Service
  bleuart.begin();

  // Due to huge amount of image data
  // NRF52832 doesn't have enough SRAM to queue up received packets using deferred callbacks.
  // Therefore it must process data as soon as it comes, this can be done by
  // changing the default "deferred" option to false to invoke callback immediately.
  // However, the transfer speed will be affected since immediate callback will block BLE task
  // to process data especially when tft.drawRGBBitmap() is calling.

  // 2nd argument is false to invoke callbacks immediately (thus blocking other ble events)
  bleuart.setRxCallback(bleuart_rx_callback, false);

  bleuart.setRxOverflowCallback(bleuart_overflow_callback);

  // Set up and start advertising
  startAdv();

  Serial.println("Advertising ... ");
}

void loop() {

}

void startAdv(void)
{
  // Advertising packet
  Bluefruit.Advertising.addFlags(BLE_GAP_ADV_FLAGS_LE_ONLY_GENERAL_DISC_MODE);
  Bluefruit.Advertising.addTxPower();
  Bluefruit.Advertising.addAppearance(BLE_APPEARANCE_GENERIC_CLOCK);

  // Include bleuart 128-bit uuid
  Bluefruit.Advertising.addService(bleuart);

  // There is no room for Name in Advertising packet
  // Use Scan response for Name
  Bluefruit.ScanResponse.addName();
  
  /* Start Advertising
   * - Enable auto advertising if disconnected
   * - Interval:  fast mode = 20 ms, slow mode = 152.5 ms
   * - Timeout for fast mode is 30 seconds
   * - Start(timeout) with timeout = 0 will advertise forever (until connected)
   * 
   * For recommended advertising interval
   * https://developer.apple.com/library/content/qa/qa1931/_index.html   
   */
  Bluefruit.Advertising.restartOnDisconnect(true);
  Bluefruit.Advertising.setInterval(32, 244);    // in unit of 0.625 ms
  Bluefruit.Advertising.setFastTimeout(30);      // number of seconds in fast mode
  Bluefruit.Advertising.start(0);                // 0 = Don't stop advertising after n seconds
}


// void setup() {
//   display.init();
//   display.setFullWindow();
//   display.firstPage();

//   display.fillScreen(GxEPD_WHITE);
//   display.drawBitmap(0, 0, epd_bitmap_black,  200, 200, GxEPD_BLACK);
//   display.drawBitmap(0, 0, epd_bitmap_red,    200, 200, GxEPD_RED);
//   display.drawBitmap(0, 0, epd_bitmap_yellow, 200, 200, GxEPD_YELLOW);
//   display.nextPage();

//   display.hibernate();
// }


// Invoked when receiving data from bleuart
// Pull data from bleuart fifo & draw image as soon as possible,
// Otherwise bleuart fifo can be overflowed
void bleuart_rx_callback(uint16_t conn_hdl)
{
  (void) conn_hdl;

  rxLastTime = millis();

  // Received new Image
  if ( (imageWidth == 0) && (imageHeight == 0) )
  {
    // take note of time of first packet
    rxStartTime = millis();

    // Skip all data until '!I' is found
    while( bleuart.available() && bleuart.read() != '!' )  { }
    if (bleuart.read() != 'I') return; // TODO could use for different commands

    if ( !bleuart.available() ) return;

    imageColorBit = bleuart.read8();
    imageWidth  = bleuart.read16();
    imageHeight = bleuart.read16();

    totalPixel = 0;
    memset(pixel_buf_b, 0, sizeof(pixel_buf_b));
    memset(pixel_buf_y, 0, sizeof(pixel_buf_y));
    memset(pixel_buf_r, 0, sizeof(pixel_buf_r));

    display.fillScreen(GxEPD_WHITE);
    display.setRotation(2);

    // Print out the current connection info
    BLEConnection* conn = Bluefruit.Connection(conn_hdl);
    Serial.printf("Connection Info: PHY = %d Mbps, Conn Interval = %.2f ms, Data Length = %d, MTU = %d\n",
                  conn->getPHY(), conn->getConnectionInterval()*1.25f, conn->getDataLength(), conn->getMtu());
    Serial.printf("Receving an %dx%d Image with %d bit color\n", imageWidth, imageHeight, imageColorBit);
  }

  // Extract pixel data to buffer and draw image line by line
  while ( bleuart.available() >= 3 )
  {
    uint8_t red, green, blue;

    if ( imageColorBit == 24 )
    {
      // Application send 24-bit color
      red = bleuart.read();
      green = bleuart.read();
      blue = bleuart.read();
    }
    else
    {
      Serial.println("Error: incorrect color bits ");
      while(1) yield();
    }

    // Convert RGB into Eink Color
    uint8_t c = 0;
    if ((red < 0x80) && (green < 0x80) && (blue < 0x80)) {
      pixel_buf_b[totalPixel % imageWidth] = 0xFF;
      pixel_buf_y[totalPixel % imageWidth] = 0x00;
      pixel_buf_r[totalPixel % imageWidth] = 0x00;
    } else if ((red >= 0x80) && (green >= 0x80) && (blue >= 0x80)) {
      pixel_buf_b[totalPixel % imageWidth] = 0x00;
      pixel_buf_y[totalPixel % imageWidth] = 0xFF;
      pixel_buf_r[totalPixel % imageWidth] = 0x00;
    } else if (red >= 0x80) {
      pixel_buf_b[totalPixel % imageWidth] = 0x00;
      pixel_buf_y[totalPixel % imageWidth] = 0x00;
      pixel_buf_r[totalPixel % imageWidth] = 0xFF;
    }

    totalPixel++;
  }

  // all pixel data is received
  if ( totalPixel == imageWidth*imageHeight )
  {
    uint8_t crc = bleuart.read();
    (void) crc;
    // do checksum later

    // print speed summary
    print_summary(totalPixel*(imageColorBit/8) + 8, rxLastTime-rxStartTime);

    // Display on Eink, will probably take dozens of seconds
    Serial.println("Displaying image (~20 seconds) .....");

    display.drawBitmap(0, 0, pixel_buf_b,  200, 200, GxEPD_BLACK);
    display.drawBitmap(0, 0, pixel_buf_r,  200, 200, GxEPD_RED);
    display.drawBitmap(0, 0, pixel_buf_y,  200, 200, GxEPD_YELLOW);
    display.nextPage();

    display.hibernate();


    // reset and waiting for new image
    imageColorBit = 0;
    imageWidth = imageHeight = 0;
    totalPixel = 0;

    Serial.println("Ready to receive new image");
  }
}


void connect_callback(uint16_t conn_handle)
{
  Serial.println("Connected");
  Serial.println("Ready to receive new image");
}

void print_summary(uint32_t count, uint32_t ms)
{
  float sec = ms / 1000.0F;

  Serial.printf("Received %d bytes in %.2f seconds\n", count, sec);
  Serial.printf("Speed: %.2f KB/s\n\n", (count / 1024.0F) / sec);
}

void bleuart_overflow_callback(uint16_t conn_hdl, uint16_t leftover)
{
  (void) conn_hdl;
  (void) leftover;
  
  Serial.println("BLEUART rx buffer OVERFLOWED!");
  Serial.println("Please increase buffer size for bleuart");
}

/**
 * invoked when a connection is dropped
 * @param conn_handle connection where this event happens
 * @param reason is a BLE_HCI_STATUS_CODE which can be found in ble_hci.h
 */
void disconnect_callback(uint16_t conn_handle, uint8_t reason)
{
  (void) conn_handle;
  (void) reason;

  imageColorBit = 0;
  imageWidth = imageHeight = 0;
  totalPixel = 0;

  bleuart.flush();
}