#include "spi.h"
#include "pins.h"
#include "deviceconfig.h"

void spi_highz(){
    // Disable SPI
    SSPCON1bits.SSPEN = 0;
    
    // SPI ports as input
    SDO_TRIS = INPUT;
    SDI_TRIS = INPUT;
    SCK_TRIS = INPUT;
    
    // Disable chip selects
    SS_FLASH_TRIS = INPUT;
}

void spi_init(){
    // Set SPI pins
    SDI_ANS = DIGITAL;
    SDO_ANS = DIGITAL;
    SDI_TRIS = INPUT;
    SDO_TRIS = OUTPUT;
    SCK_TRIS = OUTPUT;
    
    // Set chip selects
    SS_FLASH_ANS = DIGITAL;
    SS_FLASH_LAT = 1;
    SS_FLASH_TRIS = OUTPUT;
    
    // Disable SPI interrupts
    PIE1bits.SSPIE = 0;
    // Clock idle at low
    SSPCON1bits.CKP = 0;
    // SPI in master mode Fosc/16
    SSPCON1bits.SSPM = 1;
    // SPI sampled at middle of data output time
    SSPSTATbits.SMP = 0;
    // SPI transmission at clock active to idle
    SSPSTATbits.CKE = 1;
    // Enable SPI
    SSPCON1bits.SSPEN = 1;
}

void spi_init_slow(){
    // Set SPI pins
    SDI_ANS = DIGITAL;
    SDO_ANS = DIGITAL;
    SDI_TRIS = INPUT;
    SDO_TRIS = OUTPUT;
    SCK_TRIS = OUTPUT;
    
    // Set chip selects
    SS_FLASH_ANS = DIGITAL;
    SS_FLASH_LAT = 1;
    SS_FLASH_TRIS = OUTPUT;
    
    // Disable SPI interrupts
    PIE1bits.SSPIE = 0;
    // Clock idle at low
    SSPCON1bits.CKP = 0;
    // SPI in master mode Fosc/16
    SSPCON1bits.SSPM = 2;
    // SPI sampled at middle of data output time
    SSPSTATbits.SMP = 0;
    // SPI transmission at clock active to idle
    SSPSTATbits.CKE = 1;
    // Enable SPI
    SSPCON1bits.SSPEN = 1;
}

uint8_t spi_transfer(uint8_t b){
    // Start sending byte
    SSPBUF = b;
    // Wait for SPI to be ready
    //while(PIR1bits.SSPIF==0);
    //PIR1bits.SSPIF = 0;
    // OR:
    while(SSPSTATbits.BF==0);
    // Get data and return
    return SSPBUF;
}

void spi_select_flash(){
    SS_FLASH_LAT = 0;
    __delay_us(1);
}
void spi_deselect_flash(){
    SS_FLASH_LAT = 1;
    __delay_us(1);
}