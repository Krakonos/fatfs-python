#!/usr/bin/python3

import fatfs
from fatfs import Partition, RamDisk

class NewPartition(Partition):
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
            Partition.__init__(self, self.disk)
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
    partition = Partition(disk)
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
        with partition.open("/tf2.txt", "wb") as handle:
            written = handle.write(s)
    partition.dump("/tmp/test_fatfs_write.img")
    assert len(s) == written

def test_fatfs_mkdir():
    partition = NewPartition()
    with partition:
        partition.mkdir("testdir1")
        partition.mkdir("testdir1/a")
    partition.dump("/tmp/test_fatfs_mkdir.img")

def test_diskio():
    disk = RamDisk(bytearray(512*256))
    fatfs.wrapper.check_diskio(disk)
