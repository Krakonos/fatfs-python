#!/usr/bin/python3

import fatfs
from fatfs import FatFSPartition

from pyfatfs.diskio import RamDisk

class NewPartition(FatFSPartition):
    """
    A helper class that handles partition mounts and initialization if necessary.
    """
    def __init__(self, disk = None):
        """
        Registers new partition on a disk (must have filesystem on it already),
        or creates a new disk image with empty filesystem.
        """
        if disk is not None:
            self.disk = disk
        else:
            self.disk = RamDisk(bytearray(512*256))
            FatFSPartition.__init__(self, self.disk)
            self.mkfs()

    def __enter__(self):
        self.mount()

    def __exit__(self, except_type, except_value, except_traceback):
        self.unmount()

    def storage(self):
        return self.disk.storage

    def dump(self, fname):
        with open(fname, "wb") as fh:
            fh.write(self.storage())



def test_fatfs_open():
    disk = RamDisk(bytearray(512*256))
    partition = FatFSPartition(disk)
    partition.mkfs()
    partition.mount()
    handle = partition.open("tf.txt", "wb")
    handle.close()
    partition.unmount()

def test_fatfs_write():
    partition = NewPartition()
    s = "HelloWorld!"
    written = 0
    with partition:
        handle = partition.open("tf2.txt", "wb")
        written = handle.write(s)
        handle.close()
    partition.dump("/tmp/testpart.img")
    assert len(s) == written

def test_diskio():
    disk = RamDisk(bytearray(512*256))
    fatfs.check_diskio(disk)
