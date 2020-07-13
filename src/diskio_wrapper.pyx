from libc.stdint cimport uint16_t 
from libc.stdint cimport uint32_t 
from libc.stdint cimport uint64_t 

from diskio_python import RamDisk

from cython.operator import dereference

cdef extern from "ff.h":
    ctypedef unsigned int    UINT
    ctypedef unsigned char   BYTE
    ctypedef uint16_t        WORD
    ctypedef uint16_t        WCHAR
    ctypedef uint32_t        DWORD
    ctypedef uint64_t        QWORD
    ctypedef char            TCHAR

cdef extern from "diskio.h":
    ctypedef BYTE             DSTATUS
    #ctypedef BYTE            DSTATUS

# Defined as macros in diskio.h
# We will duplicate them here as enum for further use
cdef enum DSTATUS_Values:
    STA_OK = 0
    STA_NOINIT = 1
    STA_NODISK = 2
    STA_PROTECT = 4

cdef enum IOCTL_Commands:
    CTRL_SYNC         = 0   # Complete pending write process (needed at FF_FS_READONLY == 0)
    GET_SECTOR_COUNT  = 1   # Get media size (needed at FF_USE_MKFS == 1)
    GET_SECTOR_SIZE   = 2   # Get sector size (needed at FF_MAX_SS != FF_MIN_SS)
    GET_BLOCK_SIZE    = 3   # Get erase block size (needed at FF_USE_MKFS == 1)
    CTRL_TRIM         = 4   # Inform device that the data on the block of sectors is no longer used (needed at FF_USE_TRIM == 1)


cdef extern from "diskio.h":
    ctypedef enum DRESULT:
        RES_OK = 0,
        RES_ERROR = 1,
        RES_WRPRT = 2,
        RES_NOTRDY = 3,
        RES_PARERR = 4
    DSTATUS disk_initialize (BYTE pdrv)
    DSTATUS disk_status (BYTE pdrv)
    DRESULT disk_read (BYTE pdrv, BYTE* buff, DWORD sector, UINT count)
    DRESULT disk_write (BYTE pdrv, const BYTE* buff, DWORD sector, UINT count)
    DRESULT disk_ioctl (BYTE pdrv, BYTE cmd, void* buff)

__diskio_wrapper_disks = {}

cdef DSTATUS disk_initialize (BYTE pdrv):
    __diskio_wrapper_disks[pdrv] = RamDisk(bytearray(512*256))
    return DSTATUS_Values.STA_OK

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

def check():
    return diskiocheck()

