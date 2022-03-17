# Mimas Spartan 6 FPGA - New firmware, driver and PC-FPGA interface
The [Numato Lab Mimas Spartan 6 FPGA development board](https://numato.com/product/mimas-spartan-6-fpga-development-board/) is a simple FPGA development board with a Xilinx Spartan 6 (xc6slx9) on it with a usb interface for programming the on-board flash. The flash is a 16 Mb SPI flash connected to both the FPGA an a Microchip PIC (18f14k50). The PIC runs firmware which presents itself as serial port to the connected PC and uses a python script to upload the generated bit-file. 

Since the original firmware used a 9600 baud serial connection, the uploading of the bitfile it takes quite some time to upload. And next to that communication between the FPGA and the USB port is not implemented even though the PIC has connections to the FPGA. This was the reason to develop new firmware which could program the SPI flash faster and has an FPGA-USB interface for serial communication and/or datalogging purposes (like a logic analyzer).

This repository contains the firmware for the PIC (in the firmware folder), the driver for programming and comunicating with the PIC (in the driver folder) and some usefull VHDL blocks for communication between the PIC and the FPGA. Information specific for the firmware, driver of hardware are located in their folders.

Information about the FPGA-PIC interface and the USB message layout is shown on the [project page](https://joppeb.nl/projects/mimas-firmware).

### Licence
The provided firmware, driver and VHDL IP are published under the BSD-2 clause licence which is slightly modified to entail hardware as well (as shown in [the licence file](/LICENCE)). 
The firmware contains USB code from the Microchip apps lib (version 2018/11/26) containing examples which is licenced under the Apache licence version 2.0. No changes are made to this source code and is directly as-is used in the firmware.
The hardware is synthesized with the Xilinx ISE-WEBPACK software (xst, netgen, ngdbuild, map, par, bitgen and trce) but does not contain any IP from other sources except my own.