from ff cimport *
from diskio cimport *

#from pyfatfs.diskio import RamDisk

__diskio_wrapper_disks = {}

cdef DSTATUS disk_initialize (BYTE pdrv):
    if pdrv in __diskio_wrapper_disks:
        return DSTATUS_Values.STA_OK
    else:
        return DSTATUS_Values.STA_NODISK

cdef DSTATUS disk_status (BYTE pdrv):
    if pdrv in __diskio_wrapper_disks:
        return DSTATUS_Values.STA_OK
    else:
        return DSTATUS_Values.STA_NODISK

cdef DRESULT disk_read (BYTE pdrv, BYTE* buff, DWORD sector, UINT count):
    if not pdrv in __diskio_wrapper_disks:
        return DRESULT.RES_NOTRDY
    drive = __diskio_wrapper_disks[pdrv]

    # Count is actually in number of sectors. Convert to bytes now.
    count *= drive.ioctl_get_sector_size()
    data = drive.read(sector, count)
    for i in range(count):
        buff[i] = data[i]
    # TODO: This doesn't work: buff[:count] = data
    return DRESULT.RES_OK

cdef DRESULT disk_write (BYTE pdrv, const BYTE* buff, DWORD sector, UINT count):
    if not pdrv in __diskio_wrapper_disks:
        return DRESULT.RES_NOTRDY
    drive = __diskio_wrapper_disks[pdrv]

    # Count is actually in number of sectors. Convert to bytes now.
    count *= drive.ioctl_get_sector_size()
    drive.write(sector, count, buff[:count])
    return DRESULT.RES_OK

cdef DRESULT disk_ioctl (BYTE pdrv, BYTE cmd, void* buff):
    if not pdrv in __diskio_wrapper_disks:
        return DRESULT.RES_NOTRDY
    drive = __diskio_wrapper_disks[pdrv]

    if cmd == IOCTL_Commands.CTRL_SYNC:
        drive.ioctl_sync()
    elif cmd == IOCTL_Commands.GET_SECTOR_COUNT:
        (<DWORD*> buff)[0] = drive.ioctl_get_sector_count()
    elif cmd == IOCTL_Commands.GET_SECTOR_SIZE:
        (<WORD*> buff)[0] = drive.ioctl_get_sector_size()
    elif cmd == IOCTL_Commands.GET_BLOCK_SIZE:
        (<DWORD*> buff)[0] = drive.ioctl_get_block_size()
    else:
        print("Unknown ioctl command %d." % cmd)
        return DRESULT.RES_ERROR

cdef extern int diskiocheck()

import datetime

cdef extern from "diskio.h":
    DWORD get_fattime()

cdef DWORD get_fattime():
    t = datetime.datetime.now()
    return ((t.year - 1980) << 25) | (t.month << 21) | (t.day << 16) | (t.minute << 5) | int(t.second / 2)
    # Return Value
    # Currnet local time shall be returned as bit-fields packed into a DWORD value. The bit fields are as follows:
    # bit31:25
    #     Year origin from the 1980 (0..127, e.g. 37 for 2017)
    # bit24:21
    #     Month (1..12)
    # bit20:16
    #     Day of the month (1..31)
    # bit15:11
    #     Hour (0..23)
    # bit10:5
    #     Minute (0..59)
    # bit4:0
    #     Second / 2 (0..29, e.g. 25 for 50)



# TODO: Wrap or remove
# /* LFN support functions */
# #if FF_USE_LFN >= 1						/* Code conversion (defined in unicode.c) */
# WCHAR ff_oem2uni (WCHAR oem, WORD cp);	/* OEM code to Unicode conversion */
# WCHAR ff_uni2oem (DWORD uni, WORD cp);	/* Unicode to OEM code conversion */
# DWORD ff_wtoupper (DWORD uni);			/* Unicode upper-case conversion */
# #endif
# #if FF_USE_LFN == 3						/* Dynamic memory allocation */
# void* ff_memalloc (UINT msize);			/* Allocate memory block */
# void ff_memfree (void* mblock);			/* Free memory block */
# #endif
# 
# /* Sync functions */
# #if FF_FS_REENTRANT
# int ff_cre_syncobj (BYTE vol, FF_SYNC_t* sobj);	/* Create a sync object */
# int ff_req_grant (FF_SYNC_t sobj);		/* Lock sync object */
# void ff_rel_grant (FF_SYNC_t sobj);		/* Unlock sync object */
# int ff_del_syncobj (FF_SYNC_t sobj);	/* Delete a sync object */
# #endif

from cpython.mem cimport PyMem_Malloc, PyMem_Realloc, PyMem_Free

class FatFSException(Exception):
    pass

cdef class FileHandle:
    cdef FIL *fp
    cdef bint isopen
    def __cinit__(self):
        self.fp = <FIL*> PyMem_Malloc(sizeof(FIL))
        self.isopen = False

    def close(self):
        ret = f_close(self.fp)
        if ret != FR_OK:
            raise FatFSException("FatFS::close failed with error code %s" % ret)

    def __dealloc__(self):
        if self.isopen:
            self.close()
        PyMem_Free(self.fp)

cdef class FatFSPartition:
    cdef FATFS* fs
    cdef int pdev
    cdef public object pname
    def __cinit__(self, disk):
        self.fs = <FATFS*> PyMem_Malloc(sizeof(FATFS))
        # TODO: Can we fetch the constant directly? Or define it here? Does it have to be 10 only?
        for i in range(10): # corresponds to FF_VOLUMES in ffconf.h
            if not i in __diskio_wrapper_disks:
                self.pdev = i
                self.pname = bytes("%d:" % i, 'ascii')
                __diskio_wrapper_disks[i] = disk
                break
            raise FatFSException("Physical disk limit reached. Please unmount some of the partitions.")


    def __dealloc__(self):
        PyMem_Free(self.fs)

    def mount(self):
        ret = f_mount(self.fs, self.pname, 1)
        if ret == FR_OK:
            return True
        else:
            raise FatFSException("FatFS::mount failed with error code %s" % ret)

    def unmount(self):
        ret = f_mount(NULL, self.pname, 0)
        if ret == FR_OK:
            del __diskio_wrapper_disks[self.pdev]
            return True
        else:
            raise FatFSException("FatFS::unmount failed with error code %s" % ret)

    def mkfs(self):
        cdef char* buff = <char*> PyMem_Malloc(512)
        cdef MKFS_PARM opt
        opt.fmt = FM_FAT | FM_SFD
        opt.n_fat = 1 # 1 copy of FAT table
        opt.align = 0 # auto align from lower layer
        opt.n_root = 0 # auto number of root FAT entries
        opt.au_size = 0 # auto
        f_mkfs(self.pname, &opt, buff, 512)

    def open(self, path, mode):
        # TODO: Implement mode.
        handle = FileHandle()
        ret = f_open(handle.fp, bytes(path, 'ascii'), FA_WRITE | FA_CREATE_ALWAYS)
        if ret != FR_OK:
            raise FatFSException("FatFS::open failed with error code %s" % ret)
        handle.isopen = True
        return handle

def check_diskio(drive):
    assert(not 0 in __diskio_wrapper_disks, "Check diskio must be used before mounting any real drives.")
    __diskio_wrapper_disks[0] = drive
    ret = diskiocheck()
    del __diskio_wrapper_disks[0]

