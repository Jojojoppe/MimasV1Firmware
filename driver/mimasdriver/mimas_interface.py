import usb1
import struct
from typing import Callable, Tuple
import time

# Constants
VENDOR_ID = 0x0000
PRODUCT_ID = 0x0001
INTERFACE = 0
ENDPOINT = 1
EPSIZE = 64

FLASH_SECTORSIZE = 0x10000

MIMAS_COMMANDS_NOP = 0
MIMAS_COMMANDS_FLASH = 1
MIMAS_COMMANDS_HFINTERFACE = 2

FLASH_COMMANDS_NOP = 0
FLASH_COMMANDS_PROGRAM = 1
FLASH_COMMANDS_READ = 2
FLASH_COMMANDS_GETID = 3

HFINTERFACE_COMMANDS_NOP = 0
HFINTERFACE_COMMANDS_TRANSFER = 1
HFINTERFACE_COMMANDS_HRST = 2
HFINTERFACE_COMMANDS_LRST = 3

class MimasInterface:
    """Class which is used for interfacing with Mimas

        Args:
            usbtimeout (int, optional): Amount of milliseconds for USB transfers. Defaults to 5000.
    """

    def __init__(self, usbtimeout:int=5000):
        self.usbtimeout = usbtimeout

    def __del__(self):
        pass

    def __enter__(self):
        return self.open()

    def __exit__(self, exc_type, exc_val, exc_tb):
        self.close()

    def open(self):
        """Open the Mimas interface

        Can be called on itself, but when using 'with MimasInterface() as mif:' the open
        and close functions are called automatically.

        Raises:
            Exception: Mimas not connected

        Returns:
            MimasInterface: 
        """
        self._ctx = usb1.USBContext()
        self._ctx.open()

        self._hdl = self._ctx.openByVendorIDAndProductID(
            VENDOR_ID, PRODUCT_ID,
            skip_on_error=True
        )
        if self._hdl is None:
            self.close()
            raise Exception("Mimas not connected")
        return self

    def close(self):
        """Close the Mimas interface

        Can be called on itself, but when using 'with MimasInterface() as mif:' the open
        and close functions are called automatically.
        """
        if self._hdl is not None:
            self._hdl.close()
        self._ctx.close()


    # FLASH FUNCTIONS
    # ---------------

    def flash_get_id(self) -> int:
        """Get SPI flash ID

        Returns:
            int: Flash ID
        """
        idnum = 0
        with self._hdl.claimInterface(INTERFACE):
            cmd = struct.pack(">BB", MIMAS_COMMANDS_FLASH, FLASH_COMMANDS_GETID)
            self._hdl.bulkWrite(ENDPOINT, cmd, timeout=self.usbtimeout)
            iddat = self._hdl.bulkRead(ENDPOINT, EPSIZE, timeout=self.usbtimeout)
            idnum = struct.unpack('>I', iddat[:4])
        return idnum

    def flash_write_sector(self, addr:int, data:int):
        """Write sector of SPI flash

        Args:
            addr ([type]): Start address
            data ([type]): Length to read
        """
        with self._hdl.claimInterface(INTERFACE):
            length = len(data)
            cmd = struct.pack(">BBII", MIMAS_COMMANDS_FLASH, FLASH_COMMANDS_PROGRAM, length, addr)
            self._hdl.bulkWrite(ENDPOINT, cmd, timeout=self.usbtimeout)

            i=0
            while(length>0):
                self._hdl.bulkWrite(ENDPOINT, data[i:i+EPSIZE], timeout=self.usbtimeout)
                length -= EPSIZE
                i += EPSIZE

    def flash_read_sector(self, addr:int, length:int) -> bytes:
        """Read sector of SPI flash

        Args:
            addr (int): Start address
            length (int): Length to read

        Returns:
            bytes: The data from the SPI flash
        """
        d = b''
        with self._hdl.claimInterface(INTERFACE):
            cmd = struct.pack(">BBII", MIMAS_COMMANDS_FLASH, FLASH_COMMANDS_READ, length, addr)
            self._hdl.bulkWrite(ENDPOINT, cmd, timeout=self.usbtimeout)

            i=0
            while(length>0):
                rdat = self._hdl.bulkRead(ENDPOINT, EPSIZE, timeout=self.usbtimeout)
                length -= EPSIZE
                i += EPSIZE
                d = d + bytes(rdat)
        return d

    def flash_read(self, file:str, pfunc:Callable=None, flen:int=0x80000, addr:int=0):
        """Read SPI flash

        Args:
            file (str): Path to safe binary bitstream
            pfunc (callable, optional): Function which is called after each sector. Defaults to None.
            flen (int, optional): Maximum amount of bytes to read. Defaults to 512KB.
            addr (int): Starting address
        """
        with open(file, 'wb') as f:
            addr = 0
            while True:
                data = self.flash_read_sector(addr, FLASH_SECTORSIZE)
                if pfunc is not None:
                    pfunc()
                f.write(data)
                addr += FLASH_SECTORSIZE
                if addr>=flen:
                    break

    def flash_program(self, file:str, pfunc:Callable=None, addr:int=0) -> int:
        """Program SPI flash

        Args:
            file (str): Path to binary file
            pfunc (callable, optional): Function which is called after each sector. Defaults to None.
            addr (int): Starting address

        Returns:
            int: Number of written bytes
        """
        with open(file, 'rb') as f:
            while True:
                data = f.read(FLASH_SECTORSIZE)
                if len(data)==0:
                    break
                if pfunc is not None:
                    pfunc()
                self.flash_write_sector(addr, data)
                addr += len(data)
        return addr

    # ENDPOINT FUNCTIONS
    # ------------------
    def hfinterface_transfer(self, gpio:int, ep0:bytes=b'', ep1:bytes=b'') -> Tuple[int, bytes, bytes]:
        """Transfer data through the HFINTERFACE

        Args:
            gpio (int): GPIO output (mask 0x3f)
            ep0 (bytes, optional): Data sent to EP0. Defaults to b''.
            ep1 (bytes, optional): Data sent to EP1. Defaults to b''.

        Returns:
            Tuple[int, bytes, bytes]: Tule containing GPIO input, data from EP0 and EP1
        """
        with self._hdl.claimInterface(INTERFACE):
            cmd = struct.pack(">BBBBB", MIMAS_COMMANDS_HFINTERFACE, HFINTERFACE_COMMANDS_TRANSFER,
                gpio&0x3f, len(ep0), len(ep1)
            )
            if len(ep0)>0:
                cmd += ep0
            if len(ep1)>0:
                cmd += ep1
            self._hdl.bulkWrite(ENDPOINT, cmd, timeout=self.usbtimeout)
            rdat = self._hdl.bulkRead(ENDPOINT, EPSIZE, timeout=self.usbtimeout)

            gpio = int(rdat[0])
            ep0len = int(rdat[1])
            ep1len = int(rdat[2])
            ep0 = rdat[3:3+ep0len]
            ep1 = rdat[3+ep0len:3+ep0len+ep1len]

            return gpio, ep0, ep1

    def hfinterface_reset(self) -> None:
        """ Reset the FPGA"""
        with self._hdl.claimInterface(INTERFACE):
            cmd = struct.pack(">BB", MIMAS_COMMANDS_HFINTERFACE, HFINTERFACE_COMMANDS_HRST)
            self._hdl.bulkWrite(ENDPOINT, cmd, timeout=self.usbtimeout)
            time.sleep(0.2)
            cmd = struct.pack(">BB", MIMAS_COMMANDS_HFINTERFACE, HFINTERFACE_COMMANDS_LRST)
            self._hdl.bulkWrite(ENDPOINT, cmd, timeout=self.usbtimeout)