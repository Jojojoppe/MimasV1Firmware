#include "HF_interface.h"
#include "bulkEP0.h"
#include "usb_config.h"
#include "spi.h"
#include "pins.h"
#include "deviceconfig.h"

#define MAX(x, y) (((x) > (y)) ? (x) : (y))
#define MIN(x, y) (((x) < (y)) ? (x) : (y))

enum{
    HFINTERFACE_TASK_NOP = 0,
    HFINTERFACE_TASK_TRANSFER = 1,
    HFINTERFACE_TASK_HRST = 2,
    HFINTERFACE_TASK_LRST = 3,
} HFINTERFACE_TASK;

uint8_t hfinterface_action;

uint8_t hfinterface_ep0_bufout[16];
uint8_t hfinterface_ep0_lenout;
uint8_t hfinterface_ep0_poutrd;
uint8_t hfinterface_ep0_poutwr;
uint8_t hfinterface_ep0_bufin[16];
uint8_t hfinterface_ep0_lenin;
uint8_t hfinterface_ep0_pinrd;
uint8_t hfinterface_ep0_pinwr;

uint8_t hfinterface_ep1_bufout[16];
uint8_t hfinterface_ep1_lenout;
uint8_t hfinterface_ep1_poutrd;
uint8_t hfinterface_ep1_poutwr;
uint8_t hfinterface_ep1_bufin[16];
uint8_t hfinterface_ep1_lenin;
uint8_t hfinterface_ep1_pinrd;
uint8_t hfinterface_ep1_pinwr;

uint8_t hfinterface_gpio_out;
uint8_t hfinterface_gpio_in;

uint8_t hfinterface_buffer_wr(uint8_t * buf, uint8_t * ip, uint8_t * cnt, uint8_t val){
    if(*cnt==16) return 0;
    (*cnt)++;
    *ip = (*ip+1)%16;
    buf[*ip] = val;    
    return 1;
}

uint8_t hfinterface_buffer_rd(uint8_t * buf, uint8_t * op, uint8_t * cnt, uint8_t * val){
    if(*cnt==0) return 0;
    (*cnt)--;
    *op = (*op+1)%16;
    *val = buf[*op];
    return 1;
}

uint8_t hfinterface_transfer_set(){
    uint8_t status = hfinterface_gpio_out<<2;
    uint8_t ep0 = 0;
    uint8_t ep1 = 0;
    if(hfinterface_buffer_rd(hfinterface_ep0_bufout, &hfinterface_ep0_poutrd,
            &hfinterface_ep0_lenout, &ep0)){
        status |= 1;
    }
    if(hfinterface_buffer_rd(hfinterface_ep1_bufout, &hfinterface_ep1_poutrd,
            &hfinterface_ep1_lenout, &ep1)){
        status |= 2;
    }

    spi_init_slow();
    spi_deselect_flash();

    status = spi_transfer(status);
    ep0 = spi_transfer(ep0);
    ep1 = spi_transfer(ep1);

    spi_highz();
    
    uint8_t retval = 0;
    hfinterface_gpio_in = status>>2;
    if(status&1){
        hfinterface_buffer_wr(hfinterface_ep0_bufin, &hfinterface_ep0_pinwr,
                &hfinterface_ep0_lenin, ep0);
        retval = 1;
    }
    if(status&2){
        hfinterface_buffer_wr(hfinterface_ep1_bufin, &hfinterface_ep1_pinwr,
                &hfinterface_ep1_lenin, ep1);
        retval = 1;
    }
    return retval;
}

void hfinterface_init(){
    hfinterface_action = 0;
    
    hfinterface_ep0_lenout = 0;
    hfinterface_ep0_poutrd = 0;
    hfinterface_ep0_poutwr = 0;
    hfinterface_ep0_lenin = 0;
    hfinterface_ep0_pinrd = 0;
    hfinterface_ep0_pinwr = 0;
    hfinterface_ep1_lenout = 0;
    hfinterface_ep1_poutrd = 0;
    hfinterface_ep1_poutwr = 0;
    hfinterface_ep1_lenin = 0;
    hfinterface_ep1_pinrd = 0;
    hfinterface_ep1_pinwr = 0;
    
    hfinterface_gpio_out = 0;
    hfinterface_gpio_in = 0xaa;
    
    HFRST_ANS = DIGITAL;
    HFRST_LAT = 0;
    HFRST_TRIS = OUTPUT;
}

void hfinterface_task(){
    // Do nothing if in programming mode
    if(PROGB_PORT==0) return;
    
    switch(hfinterface_action){
        
        case HFINTERFACE_TASK_TRANSFER:{
            // If transfer task is in progress send current data to USB
            // Output buffers and gpio_out already set at cmd_handler
            // This is done first before SPI transfer itself to make sure
            // the in buffers are empty
            INPacket[0] = hfinterface_gpio_in;
            INPacket[1] = hfinterface_ep0_lenin;
            INPacket[2] = hfinterface_ep1_lenin;
            uint8_t i=3;
            while(hfinterface_buffer_rd(hfinterface_ep0_bufin, &hfinterface_ep0_pinrd,
                        &hfinterface_ep0_lenin, INPacket+i)){             
                i++;
            }
            while(hfinterface_buffer_rd(hfinterface_ep1_bufin, &hfinterface_ep1_pinrd,
                        &hfinterface_ep1_lenin, INPacket+i)){             
                i++;
            }
            bulkEP0_writeINPacket();
            
            // Do a transfer if space left in bufin's
            // Try 16 times
            for(uint8_t i=0; i<16; i++){
            // for(uint8_t i=0; i<4; i++){
                // When there is no space left stop trying
                uint8_t maxtransferlength = MIN(16-hfinterface_ep0_lenin, 16-hfinterface_ep1_lenin);
                if(maxtransferlength==0) break;

                // Transfer data and stop if nothing received of send buffers empty
                if(hfinterface_transfer_set()==0 || (hfinterface_ep0_lenout==0 && hfinterface_ep1_lenout==0)) break;
            }
            
            hfinterface_action = HFINTERFACE_TASK_NOP;
        }break;
        
        default:
            break;
    }
}

void hfinterface_packet_handle(){
    switch(hfinterface_action){      
        default:
            break;
    }
}

void hfinterface_cmd_handle(){
    switch(OUTPacket[1]){
        
        case HFINTERFACE_TASK_HRST:
            HFRST_LAT = 1;
            break;

        case HFINTERFACE_TASK_LRST:
            HFRST_LAT = 0;
            break;
        
        case HFINTERFACE_TASK_TRANSFER:{
            // Set gpio_out and write to out buffers
            // The out buffers are assumed to be empty since
            // after each transfer command the read buffers are
            // directly emptied so a write can occur immediately
            // after the transfer command
            hfinterface_gpio_out = OUTPacket[2];
            uint8_t l0 = OUTPacket[3];
            uint8_t l1 = OUTPacket[4];
            uint8_t i = 5;
            for(uint8_t j=0; j<l0; j++){
                hfinterface_buffer_wr(hfinterface_ep0_bufout, &hfinterface_ep0_poutwr, 
                        &hfinterface_ep0_lenout, OUTPacket[i++]);
            }
            for(uint8_t j=0; j<l1; j++){
                hfinterface_buffer_wr(hfinterface_ep1_bufout, &hfinterface_ep1_poutwr, 
                        &hfinterface_ep1_lenout, OUTPacket[i++]);
            }
            hfinterface_action = HFINTERFACE_TASK_TRANSFER;
        }break;
        
        default:
            break;
    }
}