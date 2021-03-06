#!/usr/bin/env python3

import mimasdriver
import timeit
from typing import Tuple

def wbReset(mif:mimasdriver.MimasInterface)->None:
    gpio, ep0, ep1 = mif.hfinterface_transfer(0x04, b'', b'')
    gpio, ep0, ep1 = mif.hfinterface_transfer(0x00, b'', b'')

def wbWrite(addr:int, data:int, mif:mimasdriver.MimasInterface)->int:
    # Send command
    gpio, ep0, ep1 = mif.hfinterface_transfer(0, b'\x01', b'')
    # Send address
    a = addr.to_bytes(4, byteorder='big')
    gpio, ep0, ep1 = mif.hfinterface_transfer(0, bytes([a[0]]), b'')
    gpio, ep0, ep1 = mif.hfinterface_transfer(0, bytes([a[1]]), b'')
    gpio, ep0, ep1 = mif.hfinterface_transfer(0, bytes([a[2]]), b'')
    gpio, ep0, ep1 = mif.hfinterface_transfer(0, bytes([a[3]]), b'')
    # Send data
    a = data.to_bytes(4, byteorder='big')
    gpio, ep0, ep1 = mif.hfinterface_transfer(0, bytes([a[0]]), b'')
    gpio, ep0, ep1 = mif.hfinterface_transfer(0, bytes([a[1]]), b'')
    gpio, ep0, ep1 = mif.hfinterface_transfer(0, bytes([a[2]]), b'')
    gpio, ep0, ep1 = mif.hfinterface_transfer(0, bytes([a[3]]), b'')
    # Get response
    resp = b''
    cnt = 0
    while resp==b'':
        gpio, resp, ep1 = mif.hfinterface_transfer(0, b'', b'')
        cnt += 1
        if cnt==4096:
            print("ERROR: Timeout")
            exit(1)
    return int.from_bytes(resp, 'little')

def wbRead(addr:int, mif:mimasdriver.MimasInterface)->Tuple[int, int]:
    # Send command
    gpio, ep0, ep1 = mif.hfinterface_transfer(0, b'\x02', b'')
    # Send address
    a = addr.to_bytes(4, byteorder='big')
    gpio, ep0, ep1 = mif.hfinterface_transfer(0, bytes([a[0]]), b'')
    gpio, ep0, ep1 = mif.hfinterface_transfer(0, bytes([a[1]]), b'')
    gpio, ep0, ep1 = mif.hfinterface_transfer(0, bytes([a[2]]), b'')
    gpio, ep0, ep1 = mif.hfinterface_transfer(0, bytes([a[3]]), b'')
    # Get data
    d = b''
    for i in range(4):
        ep0 = b''
        cnt = 0
        while ep0==b'':
            gpio, ep0, ep1 = mif.hfinterface_transfer(0, b'', b'')
            cnt += 1
            if cnt==4096:
                print("ERROR: Timeout")
                exit(1)
        d += ep0
    # Get response
    resp = b''
    cnt = 0
    while resp==b'':
        gpio, resp, ep1 = mif.hfinterface_transfer(0, b'', b'')
        cnt += 1
        if cnt==4096:
            print("ERROR: Timeout")
            exit(1)
    return int.from_bytes(d, 'big'), int.from_bytes(resp, 'little')

def runtest(test_size):
    with mimasdriver.MimasInterface() as mif:
        wbReset(mif)
        for i in range(test_size):
            resp = wbWrite(0, i, mif)
            if resp != 0xa0:
                print("Response error... %08x"%resp)
                exit(1)
    return None


TEST_SIZE = 4096
t = timeit.timeit('runtest(TEST_SIZE)', 'from __main__ import runtest, TEST_SIZE', number=1)
bps = float(TEST_SIZE*4)/t
print(bps, 'Bps over wishbone')

bps = float(TEST_SIZE*10)/t
print(bps, 'Bps over EP0 (roughly)')

bps = float(TEST_SIZE*30)/t
print(bps, 'Bps over SPI (roughly)')

bps = float(TEST_SIZE)/t
print(bps, 'transactions per second over wishbone')