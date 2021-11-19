#ifndef __H_PINS
#define __H_PINS

#include <xc.h>

#define INPUT   1
#define OUTPUT  0
#define HIGH    1
#define LOW     0
#define ANALOG      1
#define DIGITAL     0
#define PULL_UP_ENABLED      1
#define PULL_UP_DISABLED     0

// SPI INTERFACE
// -------------

#define SCK_TRIS                 TRISBbits.TRISB6
#define SCK_LAT                  LATBbits.LATB6
#define SCK_PORT                 PORTBbits.RB6
#define SCK_WPU                  WPUBbits.WPUB6

#define SDI_TRIS                 TRISBbits.TRISB4
#define SDI_LAT                  LATBbits.LATB4
#define SDI_PORT                 PORTBbits.RB4
#define SDI_WPU                  WPUBbits.WPUB4
#define SDI_ANS                  ANSELHbits.ANS10

#define SDO_TRIS                 TRISCbits.TRISC7
#define SDO_LAT                  LATCbits.LATC7
#define SDO_PORT                 PORTCbits.RC7
#define SDO_ANS                  ANSELHbits.ANS9

// FLASH INTERFACE
// ---------------

#define SS_FLASH_TRIS            TRISBbits.TRISB5
#define SS_FLASH_LAT             LATBbits.LATB5
#define SS_FLASH_PORT            PORTBbits.RB5
#define SS_FLASH_WPU             WPUBbits.WPUB5
#define SS_FLASH_ANS             ANSELHbits.ANS11

// FPGA INTERFACE
// --------------

#define PROGB_TRIS               TRISCbits.TRISC1
#define PROGB_LAT                LATCbits.LATC1
#define PROGB_PORT               PORTCbits.RC1
#define PROGB_ANS                ANSELbits.ANS5

// HF INTERFACE
// ------------
#define HFCLK_TRIS              TRISCbits.TRISC0
#define HFCLK_LAT               LATCbits.LATC0
#define HFCLK_PORT              PORTCbits.RC0
#define HFCLK_ANS               ANSELbits.ANS4

#define HFSDO_TRIS              TRISBbits.TRISB7
#define HFSDO_LAT               LATBbits.LATB7
#define HFSDO_PORT              PORTBbits.RB7
#define HFSDO_WPU               WPUBbits.WPUB7

#define HFSDI_TRIS              TRISCbits.TRISC2
#define HFSDI_LAT               LATCbits.LATC2
#define HFSDI_PORT              PORTCbits.RC2
#define HFSDI_ANS               ANSELbits.ANS6

#endif