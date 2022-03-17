#include "bulkEP0.h"

#include "usb_ch9.h"
#include "usb_device.h"
#include "usb_device_generic.h"
#include "usb_config.h"

#include "system.h"
#include "flash.h"
#include "HF_interface.h"

uint8_t INPacket[USBGEN_EP_SIZE] USBGEN_INBUFFER_ADDRESS;
uint8_t OUTPacket[USBGEN_EP_SIZE] USBGEN_OUTBUFFER_ADDRESS;
static USB_HANDLE bulkEP0_INHandle;
static USB_HANDLE bulkEP0_OUTHandle;

uint8_t bulkEP0_flash_nextOUTPacket;
uint8_t bulkEP0_hfinterface_nextOUTPacket;
uint8_t bulkEP0_should_write;

enum{
    MIMAS_COMMANDS_NOP = 0,
    MIMAS_COMMANDS_FLASH = 1,
    MIMAS_COMMANDS_HFINTERFACE = 2,
} MIMAS_COMMANDS;

void bulkEP0_init(){
    bulkEP0_INHandle = 0;
    bulkEP0_OUTHandle = 0;
    
    USBEnableEndpoint(USBGEN_EP_NUM, USB_OUT_ENABLED | USB_IN_ENABLED | USB_HANDSHAKE_ENABLED | USB_DISALLOW_SETUP);
    bulkEP0_OUTHandle = USBGenRead(USBGEN_EP_NUM, (uint8_t*)&OUTPacket, USBGEN_EP_SIZE);
    
    bulkEP0_flash_nextOUTPacket = 0;
    bulkEP0_hfinterface_nextOUTPacket = 0;
    bulkEP0_should_write = 0;
}

void bulkEP0_writeINPacket(){
    bulkEP0_should_write = 1;
}

void bulkEP0_task(){
    if(USBGetDeviceState()<CONFIGURED_STATE) return;
    if(USBIsDeviceSuspended()== true) return;
        
    if(bulkEP0_should_write){
        if(USBHandleBusy(bulkEP0_INHandle)==0){
            bulkEP0_INHandle = USBGenWrite(USBGEN_EP_NUM, (uint8_t*)&INPacket, USBGEN_EP_SIZE);
            bulkEP0_should_write = 0;
        }
        return;
    }
    
    // USB Packet received
    if(USBHandleBusy(bulkEP0_OUTHandle)==0){            
        uint8_t plen = USBHandleGetLength(bulkEP0_OUTHandle);
        
        // If packet is for flash
        if(bulkEP0_flash_nextOUTPacket){
            bulkEP0_flash_nextOUTPacket = 0;
            flash_packet_handle();
            bulkEP0_OUTHandle = USBGenRead(USBGEN_EP_NUM, (uint8_t*)&OUTPacket, USBGEN_EP_SIZE);
            return;
        }
        
        // If packet is for HF_interface
        if(bulkEP0_hfinterface_nextOUTPacket){
            bulkEP0_hfinterface_nextOUTPacket = 0;
            hfinterface_packet_handle();
            bulkEP0_OUTHandle = USBGenRead(USBGEN_EP_NUM, (uint8_t*)&OUTPacket, USBGEN_EP_SIZE);
            return;            
        }
        
        // Packet is not for any subsystems -> command
        switch(OUTPacket[0]){
            case MIMAS_COMMANDS_FLASH:
                flash_cmd_handle();
                break;
                
            case MIMAS_COMMANDS_HFINTERFACE:
                hfinterface_cmd_handle();
                break;
            
            case MIMAS_COMMANDS_NOP:
            default:
                break;
        }
        
        bulkEP0_OUTHandle = USBGenRead(USBGEN_EP_NUM, (uint8_t*)&OUTPacket, USBGEN_EP_SIZE);
    }
}