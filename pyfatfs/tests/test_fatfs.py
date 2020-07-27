#!/usr/bin/python3

from fatfs import *

from pyfatfs.diskio import RamDisk

#def test_fatfs_check():
#    __diskio_wrapper_disks[0] = RamDisk(bytearray(512*256))
#    ret = diskiocheck()
#    del __diskio_wrapper_disks[0]

def test_fatfs_open():
    disk = RamDisk(bytearray(512*256))
    partition = FatFSPartition(disk)
    partition.mkfs()
    partition.mount()
    handle = partition.open("tf.txt", "wb")
    handle.close()
    partition.unmount()

    with open("/tmp/fatfs.img", "wb") as fh:
        fh.write(disk.storage)
