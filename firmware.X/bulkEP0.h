#ifndef __H_BULKEP0
#define __H_BULKEP0

#include <stdint.h>

extern uint8_t OUTPacket[];
extern uint8_t INPacket[];

extern uint8_t bulkEP0_flash_nextOUTPacket;
extern uint8_t bulkEP0_hfinterface_nextOUTPacket;
extern uint8_t bulkEP0_should_write;

void bulkEP0_init();
void bulkEP0_task();

void bulkEP0_writeINPacket();

#endif