#ifndef __H_FLASH
#define __H_FLASH

#include <stdint.h>

void flash_init();
void flash_task();
void flash_packet_handle();
void flash_cmd_handle();

#endif