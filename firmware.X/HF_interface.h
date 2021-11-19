#ifndef __H_HFINTERFACE
#define __H_HFINTERFACE

#include <stdint.h>

void hfinterface_init();
void hfinterface_task();
void hfinterface_packet_handle();
void hfinterface_cmd_handle();

#endif