# Mimas Spartan 6 FPGA - Firmware
The firmware can be build using the provided build method or by adding all the files to a MPLab project for the PIC18f14k50. To build the firmware using the provided build method one needs `tup` (take a look [here](https://gittup.org/tup/index.html)) and the xc8 compiler from Microchip. If the xc8 compiler is not directly in your executable path edit the `MP_PATH` line in `Tupfile`.

To build run `tup init` in this folder to initialize the build environment and run `tup` to build. The output files can be found in the out folder.

### Why tup you asked?
I used to work with Makefiles for quite some time and they could get ugly and massive quite quickly. One day, not long ago, I came accross tup and was very intrigued by it and it's capability to track dependencies automatically by watching which files are opened by the executed commands. I do use make from time to time since it is easy to add phony targets to make (to do `make run` or something like that) hence why I used it as the build method for the hardware. But since the firmware just had to be build I choose for tup.