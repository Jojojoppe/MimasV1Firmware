#ifndef __H_SPI
#define __H_SPI

#include <stdint.h>

void spi_highz();
void spi_init();
void spi_init_slow();
uint8_t spi_transfer(uint8_t b);

void spi_select_flash();
void spi_deselect_flash();

#endif