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

uint8_t hfinterface_transfer(uint8_t dout){
    uint8_t din;
    for(uint8_t i=0; i<8; i++){
        HFSDO_LAT = (dout>>7)&1;
        dout = dout<<1;
        HFCLK_LAT = 1;
        din = din<<1;
        din |= HFSDI_PORT;
        HFCLK_LAT = 0;
    }
    HFSDO_LAT = 0;
    HFCLK_LAT = 0;
    return din;
}

void hfinterface_transfer_set(){
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
    
    status = hfinterface_transfer(status);
    ep0 = hfinterface_transfer(ep0);
    ep1 = hfinterface_transfer(ep1);
    
    hfinterface_gpio_in = status>>2;
    if(status&1){
        hfinterface_buffer_wr(hfinterface_ep0_bufin, &hfinterface_ep0_pinwr,
                &hfinterface_ep0_lenin, ep0);
    }
    if(status&2){
        hfinterface_buffer_wr(hfinterface_ep1_bufin, &hfinterface_ep1_pinwr,
                &hfinterface_ep1_lenin, ep1);
    }
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
    
    HFCLK_ANS = DIGITAL;
    HFCLK_LAT = 0;
    HFCLK_TRIS = OUTPUT;
    
    HFSDI_ANS = DIGITAL;
    HFSDI_TRIS = INPUT;
    
    HFSDO_LAT = 0;
    HFSDO_TRIS = OUTPUT;
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
                // When there is no space left stop trying
                uint8_t maxtransferlength = MIN(16-hfinterface_ep0_lenin, 16-hfinterface_ep1_lenin);
                if(maxtransferlength==0) break;

                hfinterface_transfer_set();
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