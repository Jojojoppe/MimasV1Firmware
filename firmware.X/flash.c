#include "flash.h"
#include "pins.h"
#include "spi.h"
#include "bulkEP0.h"
#include "usb_config.h"
#include "deviceconfig.h"

enum{
    FLASH_COMMANDS_NOP = 0,
    FLASH_COMMANDS_PROGRAM,
    FLASH_COMMANDS_READ,
    FLASH_COMMANDS_GETID,
} FLASH_COMMANDS;

enum{
    SPI_FLASH_COMMANDS_READ_IDENTIFICATION = 0x9f,
    SPI_FLASH_COMMANDS_READ_STATUS = 0x05,
    SPI_FLASH_COMMANDS_READ_DATA = 0x03,
    SPI_FLASH_COMMANDS_WRITE_ENABLE = 0x06,
    SPI_FLASH_COMMANDS_WRITE_DISABLE = 0x04,
    SPI_FLASH_COMMANDS_SECTOR_ERASE = 0xd8,
    SPI_FLASH_COMMANDS_BULK_ERASE = 0xc7,
    SPI_FLASH_COMMANDS_PAGE_PROGRAM = 0x02,
} SPI_FLASH_COMMANDS;

uint8_t flash_get_status(){
    spi_select_flash();
    spi_transfer(SPI_FLASH_COMMANDS_READ_STATUS);
    uint8_t s = spi_transfer(0);
    spi_deselect_flash();
    return s;
}

void flash_wait_wip(){
    spi_deselect_flash();
    while(1){
        __delay_us(1);
        uint8_t s = flash_get_status();
        if(!(s&1)) break;
    };
}

int32_t flash_length;
uint32_t flash_address;
uint8_t flash_action;

void flash_init(){
    PROGB_ANS = DIGITAL;
    PROGB_LAT = 1;
    PROGB_TRIS = OUTPUT;
    spi_highz();
    
    flash_length = 0;
    flash_address = 0;
    flash_action = 0;
}

// Flash main task
// Writing to USB EP0 must be done from this function
// Check for bulkEP0_should_write==0 to check if queue is empty
void flash_task(){
    switch(flash_action){
        
        case FLASH_COMMANDS_GETID:{
            // Check if USB writing is free
            if(bulkEP0_should_write==0){
                PROGB_LAT = 0;
                spi_init();
                spi_select_flash();
                spi_transfer(SPI_FLASH_COMMANDS_READ_IDENTIFICATION);
                for(uint8_t i=0; i<4; i++){
                    INPacket[i] = spi_transfer(0);
                }
                spi_deselect_flash();
                spi_highz();
                PROGB_LAT = 1;

                bulkEP0_writeINPacket();
                
                flash_action = FLASH_COMMANDS_NOP;
            }
        }break;
        
        case FLASH_COMMANDS_READ:{
            // Check if USB writing is free
            if(bulkEP0_should_write==0){
                for(uint8_t i=0; i<USBGEN_EP_SIZE; i++){
                    INPacket[i] = spi_transfer(0);
                }
                
                bulkEP0_writeINPacket();
                
                flash_address += USBGEN_EP_SIZE;
                flash_length -= USBGEN_EP_SIZE;

                if(flash_length<=0){
                    spi_deselect_flash();
                    flash_wait_wip();
                    
                    spi_highz();
                    PROGB_LAT = 1;
                    flash_action = FLASH_COMMANDS_NOP;
                }
            }
        }break;
        
        default:
            break;
    }
}

// When bulkEP0_flash_nextOUTPacket is marked this function is called when
// a new USB packet is received
void flash_packet_handle(){
    switch(flash_action){
        
        case FLASH_COMMANDS_PROGRAM:{            
            // Enable write
            spi_select_flash();
            spi_transfer(SPI_FLASH_COMMANDS_WRITE_ENABLE);
            spi_deselect_flash();
            
            // Write page
            spi_select_flash();
            spi_transfer(SPI_FLASH_COMMANDS_PAGE_PROGRAM);
            spi_transfer(flash_address>>16);
            spi_transfer(flash_address>>8);
            spi_transfer(flash_address);
            for(uint8_t i=0; i<USBGEN_EP_SIZE; i++){
                spi_transfer(OUTPacket[i]);
            }
            spi_deselect_flash();
            flash_wait_wip();
            
            flash_address += USBGEN_EP_SIZE;
            flash_length -= USBGEN_EP_SIZE;
            
            if(flash_length<=0){
                spi_highz();
                PROGB_LAT = 1;
                flash_action = FLASH_COMMANDS_NOP;
            }else{
                bulkEP0_flash_nextOUTPacket = 1;
            }
        }break;
        
        default:
            break;
    }
}

// When no packet_handle()'s are marked this function is executed when the first
// byte of the packet is MIMAS_COMMANDS_FLASH
void flash_cmd_handle(){
    switch(OUTPacket[1]){
        
        case FLASH_COMMANDS_GETID:{
            flash_action = FLASH_COMMANDS_GETID;
        }break;
        
        case FLASH_COMMANDS_READ:{
            flash_length = (int32_t)( (uint32_t)OUTPacket[3]<<16 | (uint32_t)OUTPacket[4]<<8 | (uint32_t)OUTPacket[5] );
            flash_address = (uint32_t)OUTPacket[7]<<16 | (uint32_t)OUTPacket[8]<<8 | (uint32_t)OUTPacket[9];
            
            PROGB_LAT = 0;            
            spi_init();
            
            // Read data
            spi_select_flash();
            spi_transfer(SPI_FLASH_COMMANDS_READ_DATA);
            spi_transfer(flash_address>>16);
            spi_transfer(flash_address>>8);
            spi_transfer(flash_address);
            
            flash_action = FLASH_COMMANDS_READ;
        }break;
        
        case FLASH_COMMANDS_PROGRAM:{
            flash_length = (int32_t)( (uint32_t)OUTPacket[3]<<16 | (uint32_t)OUTPacket[4]<<8 | (uint32_t)OUTPacket[5] );
            flash_address = (uint32_t)OUTPacket[7]<<16 | (uint32_t)OUTPacket[8]<<8 | (uint32_t)OUTPacket[9];
            
            PROGB_LAT = 0;            
            spi_init();
            
            // Enable write
            spi_select_flash();
            spi_transfer(SPI_FLASH_COMMANDS_WRITE_ENABLE);
            spi_deselect_flash();
            
            // Erase sector
            spi_select_flash();
            spi_transfer(SPI_FLASH_COMMANDS_SECTOR_ERASE);
            spi_transfer(flash_address>>16);
            spi_transfer(flash_address>>8);
            spi_transfer(flash_address);
            spi_deselect_flash();
            flash_wait_wip();
            
            flash_action = FLASH_COMMANDS_PROGRAM;
            bulkEP0_flash_nextOUTPacket = 1;
        }break;        
        
        default:
            break;
    }
}