#include <xc.h>

#include "usb.h"
#include "usb_config.h"

#include "deviceconfig.h"
#include "spi.h"
#include "bulkEP0.h"
#include "flash.h"
#include "HF_interface.h"

// INTERRUPTS
// ----------
void high_priority interrupt InterruptHigh(){
    #ifdef USB_INTERRUPT
        USBDeviceTasks();
    #endif
}

void low_priority interrupt InterruptLow(){    
}

// MAIN LOOP
// ---------
void main(){
    OSCILLATOR_Initialize();
    spi_highz();
    flash_init();
    hfinterface_init();
    
    USBDeviceInit();
    USBDeviceAttach();
    
    while(1){
        #ifdef USB_POLLING
            USBDeviceTasks();
        #endif

        flash_task();
        hfinterface_task();
        bulkEP0_task();        
    }
}