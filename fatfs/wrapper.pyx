from fatfs.ff cimport *
from fatfs.diskio cimport *

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

cdef class FIL_Handle:
    cdef FIL *fp
    def __cinit__(self):
        self.fp = <FIL*> PyMem_Malloc(sizeof(FIL))

    def __dealloc__(self):
        PyMem_Free(self.fp)

cdef class FATFS_Handle:
    cdef FATFS* fp
    def __cinit__(self):
        self.fp = <FATFS*> PyMem_Malloc(sizeof(FATFS))

    def __dealloc__(self):
        PyMem_Free(self.fp)


# Open or create a file
def pyf_open (FIL_Handle fph, const TCHAR* path, BYTE mode) -> FRESULT:
    return f_open(fph.fp, path, mode)

# Close an open file object
def pyf_close (FIL_Handle fph) -> FRESULT:
    return f_close(fph.fp)

# Read data from the file
#def pyf_read (FIL* fp, void* buff, UINT btr, UINT* br) -> FRESULT:
#    raise Exception("Not implemented.")
## Write data to the file
def pyf_write (FIL_Handle fph, data) -> FRESULT:
    assert isinstance(data, (bytes, bytearray))
    cdef UINT written
    cdef char* dataptr = data
    ret = f_write(fph.fp, <void*>dataptr, len(data), &written)
    if ret != FR_OK:
        raise FatFSException("FatFS::close failed with error code %s" % ret)
    assert((ret != FR_OK) or (written == len(data)), "FatFS::write succeeded, but written different %i bytes out of %i." % (written, len(data)))
    return ret, written
## Move file pointer of the file object
#def pyf_lseek (FIL* fp, FSIZE_t ofs) -> FRESULT:
#    raise Exception("Not implemented.")
## Truncate the file
#def pyf_truncate (FIL* fp) -> FRESULT:
#    raise Exception("Not implemented.")
## Flush cached data of the writing file
#def pyf_sync (FIL* fp) -> FRESULT:
#    raise Exception("Not implemented.")
## Open a directory
#def pyf_opendir (DIR* dp, const TCHAR* path) -> FRESULT:
#    raise Exception("Not implemented.")
## Close an open directory
#def pyf_closedir (DIR* dp) -> FRESULT:
#    raise Exception("Not implemented.")
## Read a directory item
#def pyf_readdir (DIR* dp, FILINFO* fno) -> FRESULT:
#    raise Exception("Not implemented.")
## Find first file
#def pyf_findfirst (DIR* dp, FILINFO* fno, const TCHAR* path, const TCHAR* pattern) -> FRESULT:
#    raise Exception("Not implemented.")
## Find next file
#def pyf_findnext (DIR* dp, FILINFO* fno) -> FRESULT:
#    raise Exception("Not implemented.")
## Create a sub directory
def pyf_mkdir (path) -> FRESULT:
    return f_mkdir(path)
## Delete an existing file or directory
#def pyf_unlink (const TCHAR* path) -> FRESULT:
#    raise Exception("Not implemented.")
## Rename/Move a file or directory
#def pyf_rename (const TCHAR* path_old, const TCHAR* path_new) -> FRESULT:
#    raise Exception("Not implemented.")
## Get file status
#def pyf_stat (const TCHAR* path, FILINFO* fno) -> FRESULT:
#    raise Exception("Not implemented.")
## Change attribute of a file/dir
#def pyf_chmod (const TCHAR* path, BYTE attr, BYTE mask) -> FRESULT:
#    raise Exception("Not implemented.")
## Change timestamp of a file/dir
#def pyf_utime (const TCHAR* path, const FILINFO* fno) -> FRESULT:
#    raise Exception("Not implemented.")
## Change current directory
#def pyf_chdir (const TCHAR* path) -> FRESULT:
#    raise Exception("Not implemented.")
## Change current drive
#def pyf_chdrive (const TCHAR* path) -> FRESULT:
#    raise Exception("Not implemented.")
## Get current directory
#def pyf_getcwd (TCHAR* buff, UINT len) -> FRESULT:
#    raise Exception("Not implemented.")
## Get number of free clusters on the drive
#def pyf_getfree (const TCHAR* path, DWORD* nclst, FATFS** fatfs) -> FRESULT:
#    raise Exception("Not implemented.")
## Get volume label
#def pyf_getlabel (const TCHAR* path, TCHAR* label, DWORD* vsn) -> FRESULT:
#    raise Exception("Not implemented.")
## Set volume label
#def pyf_setlabel (const TCHAR* label) -> FRESULT:
#    raise Exception("Not implemented.")
## Forward data to the stream
#def pyf_forward (FIL* fp, UINT(*func)(const BYTE*,UINT), UINT btf, UINT* bf) -> FRESULT:
#    raise Exception("Not implemented.")
## Allocate a contiguous block to the file
#def pyf_expand (FIL* fp, FSIZE_t fsz, BYTE opt) -> FRESULT:
#    raise Exception("Not implemented.")
# Mount/Unmount a logical drive
def pyf_mount (FATFS_Handle fph, const TCHAR* path, BYTE opt) -> FRESULT:
    return f_mount(fph.fp, path, opt)

# Create a FAT volume
def pyf_mkfs (path, n_fat = 1, align = 0, n_root = 0, au_size = 0, workarea_size = 512) -> FRESULT:
    """
    Create a new FAT filesystem on volum given in path. The optional parameters
    are passed to FATFS as is. Defaults will create filesystem with 1 FAT
    table, auto alignment probed from backing device, automatically choose
    number of rot entries and allocation unit size.
    """
    cdef char* buff = <char*> PyMem_Malloc(workarea_size)
    cdef MKFS_PARM opt
    opt.fmt = FM_FAT | FM_SFD
    opt.n_fat = n_fat # 1 copy of FAT table
    opt.align = align # auto align from lower layer
    opt.n_root = n_root # auto number of root FAT entries
    opt.au_size = au_size # auto
    cdef FRESULT ret = f_mkfs(path, &opt, buff, 512)
    PyMem_Free(buff)
    return ret
## Divide a physical drive into some partitions
#def pyf_fdisk (BYTE pdrv, const LBA_t ptbl[], void* work) -> FRESULT:
#    raise Exception("Not implemented.")
## Set current code page
#def pyf_setcp (WORD cp) -> FRESULT:
#    raise Exception("Not implemented.")
## Put a character to the file
#def pyf_putc (TCHAR c, FIL* fp) -> int:
#    raise Exception("Not implemented.")
## Put a string to the file
#def pyf_puts (const TCHAR* str, FIL* cp) -> int:
#    raise Exception("Not implemented.")
## Put a formatted string to the file
#def pyf_printf (FIL* fp, const TCHAR* str, ...) -> int:
#    raise Exception("Not implemented.")
## Get a string from the file
#def pyf_gets (TCHAR* buff, int len, FIL* fp) -> str
#    raise Exception("Not implemented.")


from cpython.mem cimport PyMem_Malloc, PyMem_Realloc, PyMem_Free

def fresult_to_name(fresult):
    # TODO: Implement.
    return "UNKNOWN_%i" % fresult

class FatFSException(Exception):
    def __init__(self, function, ret, *args):
        args_str = ", ".join(map(str, args))
        ret_str = fresult_to_name(ret)
        Exception.__init__(self, "FatFS::%s(%s) failed with error code %i (%s)" % (function, args_str, ret, ret_str))
    pass

class FileHandle:
    def __init__(self):
        self.isopen = False
        self.fp = FIL_Handle()

    def close(self):
        ret = pyf_close(self.fp)
        if ret != FR_OK:
            raise FatFSException("FatFS::close failed with error code %s" % ret)

    def __dealloc__(self):
        if self.isopen:
            self.close()

    def write(self, data):
        if isinstance(data, str):
            data = bytes(data, 'ascii')
        ret, written = pyf_write(self.fp, data)
        if ret != FR_OK:
            raise FatFSException("FatFS::close failed with error code %s" % ret)
        return written

    def read(self, size = -1):
        pass


class FatFSPartition():
    def __init__(self, disk):
        self.fs = FATFS_Handle()
        self.disk = disk
        self.pname = None
        self.pdev = None

        # Find pdev and pname
        # TODO: Can we fetch the constant directly? Or define it here? Does it have to be 10 only?
        for i in range(10): # corresponds to FF_VOLUMES in ffconf.h
            if not i in __diskio_wrapper_disks:
                self.pdev = i
                self.pname = bytes("%d:" % i, 'ascii')
                __diskio_wrapper_disks[i] = disk
                break
            raise FatFSException("Physical disk limit reached. Please unmount some of the partitions.")
    def _adjust_path(self, path):
        """
        Adjusts path for use in pyf_ calls: adds partition prefix and converts to bytes.
        """
        return self.pname + bytes(path, 'ascii')

    def mount(self):
        ret = pyf_mount(self.fs, self.pname, 1)
        if ret == FR_OK:
            return True
        else:
            raise FatFSException("FatFS::mount(%s) failed with error code %s" % (self.pname, ret))

    def unmount(self):
        ret = f_mount(NULL, self.pname, 0)
        if ret == FR_OK:
            del __diskio_wrapper_disks[self.pdev]
            return True
        else:
            raise FatFSException("FatFS::unmount(%s) failed with error code %s" % (self.pname, ret))

    def mkfs(self):
        pyf_mkfs(self.pname)

    def mkdir(self, path):
        p = self._adjust_path(path)
        ret = pyf_mkdir(p)
        if ret != FR_OK:
            #raise FatFSException("FatFS::mkdir(%s) failed with error code %s" % (p, ret))
            raise FatFSException("mount", ret, p)

    def open(self, path, mode):
        # TODO: Implement mode.
        handle = FileHandle()
        p = self._adjust_path(path)
        ret = pyf_open(handle.fp, p, FA_WRITE | FA_CREATE_ALWAYS)
        if ret != FR_OK:
            raise FatFSException("FatFS::open(%s) failed with error code %s" % (p, ret))
        handle.isopen = True
        return handle

def check_diskio(drive):
    assert(not 0 in __diskio_wrapper_disks, "Check diskio must be used before mounting any real drives.")
    __diskio_wrapper_disks[0] = drive
    ret = diskiocheck()
    del __diskio_wrapper_disks[0]

