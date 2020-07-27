
class Disk:
    def __init__(self):
        print("Initializing disk...")
    def ioctl_get_sector_count(self):
        assert(0, "Not implemented.")
    def ioctl_get_sector_size(self):
        assert(0, "Not implemented.")
    def ioctl_get_block_size(self):
        assert(0, "Not implemented.")
    def ioctl_sync(self):
        pass
    def ioctl_trim(self):
        pass
    def read(self, sector, count) -> bytes:
        assert(0, "Not implemented.")
    def write(self, sector, count, buff: bytes):
        assert(0, "Not implemented.")


class RamDisk(Disk):
    def __init__(self, storage: bytearray, sector_size: int = 512, block_size: int = 1, sector_count = 0):
        self.storage = storage
        self.sector_size = sector_size
        self.block_size = block_size
        if (sector_count == 0):
            self.sector_count = len(storage) / sector_size
        else:
            self.sector_count = sector_count
        assert (len(storage) == self.sector_count * sector_size, "Cannot create ramdisk with len(storage) != sector_count * sector_size.")
    def ioctl_get_sector_count(self):
        return self.sector_count
    def ioctl_get_sector_size(self):
        return self.sector_size
    def ioctl_get_block_size(self):
        return self.block_size
    def ioctl_sync(self):
        pass
    def ioctl_trim(self):
        pass

    def read(self, sector, count) -> bytes:
        offset = sector * self.sector_size
        return self.storage[offset:offset+count]
    def write(self, sector, count, buff: bytes):
        assert(len(buff) == count, "Write failed. Non-matching write buffer.")
        offset = sector * self.sector_size
        self.storage[offset:offset+count] = buff

