from fatfs.ff cimport *

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
    ctypedef BYTE             DSTATUS
    ctypedef enum DRESULT:
        RES_OK = 0,
        RES_ERROR = 1,
        RES_WRPRT = 2,
        RES_NOTRDY = 3,
        RES_PARERR = 4
