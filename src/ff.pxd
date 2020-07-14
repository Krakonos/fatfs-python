from libc.stdint cimport uint16_t 
from libc.stdint cimport uint32_t 
from libc.stdint cimport uint64_t 

cdef extern from "ff.h":
    ctypedef unsigned int    UINT
    ctypedef unsigned char   BYTE
    ctypedef uint16_t        WORD
    ctypedef uint16_t        WCHAR
    ctypedef uint32_t        DWORD
    ctypedef uint64_t        QWORD
    ctypedef char            TCHAR
    
    # TODO: May be QWORD depending on options. Check if the options are set correctly.
    ctypedef DWORD           LBA_t
    ctypedef DWORD           FSIZE_t

    ctypedef struct FATFS:
        pass

    ctypedef struct FFOBJID:
        pass
        #
        #typedef struct {
        #	FATFS*	fs;				/* Pointer to the hosting volume of this object */
        #	WORD	id;				/* Hosting volume mount ID */
        #	BYTE	attr;			/* Object attribute */
        #	BYTE	stat;			/* Object chain status (b1-0: =0:not contiguous, =2:contiguous, =3:fragmented in this session, b2:sub-directory stretched) */
        #	DWORD	sclust;			/* Object data start cluster (0:no cluster or root directory) */
        #	FSIZE_t	objsize;		/* Object size (valid when sclust != 0) */
        ##if FF_FS_EXFAT
        #	DWORD	n_cont;			/* Size of first fragment - 1 (valid when stat == 3) */
        #	DWORD	n_frag;			/* Size of last fragment needs to be written to FAT (valid when not zero) */
        #	DWORD	c_scl;			/* Containing directory start cluster (valid when sclust != 0) */
        #	DWORD	c_size;			/* b31-b8:Size of containing directory, b7-b0: Chain status (valid when c_scl != 0) */
        #	DWORD	c_ofs;			/* Offset in the containing directory (valid when file object and sclust != 0) */
        ##endif
        ##if FF_FS_LOCK
        #	UINT	lockid;			/* File lock ID origin from 1 (index of file semaphore table Files[]) */
        ##endif
        #} FFOBJID;
    ctypedef struct FIL:
        pass
        #/* File object structure (FIL) */
        #
        #typedef struct {
        #	FFOBJID	obj;			/* Object identifier (must be the 1st member to detect invalid object pointer) */
        #	BYTE	flag;			/* File status flags */
        #	BYTE	err;			/* Abort flag (error code) */
        #	FSIZE_t	fptr;			/* File read/write pointer (Zeroed on file open) */
        #	DWORD	clust;			/* Current cluster of fpter (invalid when fptr is 0) */
        #	LBA_t	sect;			/* Sector number appearing in buf[] (0:invalid) */
        ##if !FF_FS_READONLY
        #	LBA_t	dir_sect;		/* Sector number containing the directory entry (not used at exFAT) */
        #	BYTE*	dir_ptr;		/* Pointer to the directory entry in the win[] (not used at exFAT) */
        ##endif
        ##if FF_USE_FASTSEEK
        #	DWORD*	cltbl;			/* Pointer to the cluster link map table (nulled on open, set by application) */
        ##endif
        ##if !FF_FS_TINY
        #	BYTE	buf[FF_MAX_SS];	/* File private data read/write window */
        ##endif
        #} FIL;
    ctypedef struct DIR:
        pass
        #/* Directory object structure (DIR) */
        #
        #typedef struct {
        #	FFOBJID	obj;			/* Object identifier */
        #	DWORD	dptr;			/* Current read/write offset */
        #	DWORD	clust;			/* Current cluster */
        #	LBA_t	sect;			/* Current sector (0:Read operation has terminated) */
        #	BYTE*	dir;			/* Pointer to the directory item in the win[] */
        #	BYTE	fn[12];			/* SFN (in/out) {body[8],ext[3],status[1]} */
        ##if FF_USE_LFN
        #	DWORD	blk_ofs;		/* Offset of current entry block being processed (0xFFFFFFFF:Invalid) */
        ##endif
        ##if FF_USE_FIND
        #	const TCHAR* pat;		/* Pointer to the name matching pattern */
        ##endif
        #} DIR;


    ctypedef struct FILINFO:
        pass
        #/* File information structure (FILINFO) */
        #
        #typedef struct {
        #	FSIZE_t	fsize;			/* File size */
        #	WORD	fdate;			/* Modified date */
        #	WORD	ftime;			/* Modified time */
        #	BYTE	fattrib;		/* File attribute */
        ##if FF_USE_LFN
        #	TCHAR	altname[FF_SFN_BUF + 1];/* Altenative file name */
        #	TCHAR	fname[FF_LFN_BUF + 1];	/* Primary file name */
        ##else
        #	TCHAR	fname[12 + 1];	/* File name */
        ##endif
        #} FILINFO;

    ctypedef struct MKFS_PARM:
        BYTE fmt
        BYTE n_fat
        UINT align
        UINT n_root
        DWORD au_size
        #/* Format parameter structure (MKFS_PARM) */
        #
        #typedef struct {
        #	BYTE fmt;			/* Format option (FM_FAT, FM_FAT32, FM_EXFAT and FM_SFD) */
        #	BYTE n_fat;			/* Number of FATs */
        #	UINT align;			/* Data area alignment (sector) */
        #	UINT n_root;		/* Number of root directory entries */
        #	DWORD au_size;		/* Cluster size (byte) */
        #} MKFS_PARM;
    ctypedef enum FRESULT:
        FR_OK = 0
        FR_DISK_ERR = 1
        FR_INT_ERR = 2
        FR_NOT_READY = 3
        FR_NO_FILE = 4
        FR_NO_PATH = 5
        FR_INVALID_NAME = 6
        FR_DENIED = 7
        FR_EXIST = 8
        FR_INVALID_OBJECT = 9
        FR_WRITE_PROTECTED = 10
        FR_INVALID_DRIVE = 11
        FR_NOT_ENABLED = 12
        FR_NO_FILESYSTEM = 13
        FR_MKFS_ABORTED = 14
        FR_TIMEOUT = 15
        FR_LOCKED = 16
        FR_NOT_ENOUGH_CORE = 17
        FR_TOO_MANY_OPEN_FILES = 18
        FR_INVALID_PARAMETER = 19



    # FatFs module application interface

    # Open or create a file
    cdef FRESULT f_open (FIL* fp, const TCHAR* path, BYTE mode)
    # Close an open file object
    cdef FRESULT f_close (FIL* fp)
    # Read data from the file
    cdef FRESULT f_read (FIL* fp, void* buff, UINT btr, UINT* br)
    # Write data to the file
    cdef FRESULT f_write (FIL* fp, const void* buff, UINT btw, UINT* bw)
    # Move file pointer of the file object
    cdef FRESULT f_lseek (FIL* fp, FSIZE_t ofs)
    # Truncate the file
    cdef FRESULT f_truncate (FIL* fp)
    # Flush cached data of the writing file
    cdef FRESULT f_sync (FIL* fp)
    # Open a directory
    cdef FRESULT f_opendir (DIR* dp, const TCHAR* path)
    # Close an open directory
    cdef FRESULT f_closedir (DIR* dp)
    # Read a directory item
    cdef FRESULT f_readdir (DIR* dp, FILINFO* fno)
    # Find first file
    cdef FRESULT f_findfirst (DIR* dp, FILINFO* fno, const TCHAR* path, const TCHAR* pattern)
    # Find next file
    cdef FRESULT f_findnext (DIR* dp, FILINFO* fno)
    # Create a sub directory
    cdef FRESULT f_mkdir (const TCHAR* path)
    # Delete an existing file or directory
    cdef FRESULT f_unlink (const TCHAR* path)
    # Rename/Move a file or directory
    cdef FRESULT f_rename (const TCHAR* path_old, const TCHAR* path_new)
    # Get file status
    cdef FRESULT f_stat (const TCHAR* path, FILINFO* fno)
    # Change attribute of a file/dir
    cdef FRESULT f_chmod (const TCHAR* path, BYTE attr, BYTE mask)
    # Change timestamp of a file/dir
    cdef FRESULT f_utime (const TCHAR* path, const FILINFO* fno)
    # Change current directory
    cdef FRESULT f_chdir (const TCHAR* path)
    # Change current drive
    cdef FRESULT f_chdrive (const TCHAR* path)
    # Get current directory
    cdef FRESULT f_getcwd (TCHAR* buff, UINT len)
    # Get number of free clusters on the drive
    cdef FRESULT f_getfree (const TCHAR* path, DWORD* nclst, FATFS** fatfs)
    # Get volume label
    cdef FRESULT f_getlabel (const TCHAR* path, TCHAR* label, DWORD* vsn)
    # Set volume label
    cdef FRESULT f_setlabel (const TCHAR* label)
    # Forward data to the stream
    cdef FRESULT f_forward (FIL* fp, UINT(*func)(const BYTE*,UINT), UINT btf, UINT* bf)
    # Allocate a contiguous block to the file
    cdef FRESULT f_expand (FIL* fp, FSIZE_t fsz, BYTE opt)
    # Mount/Unmount a logical drive
    cdef FRESULT f_mount (FATFS* fs, const TCHAR* path, BYTE opt)
    # Create a FAT volume
    cdef FRESULT f_mkfs (const TCHAR* path, const MKFS_PARM* opt, void* work, UINT len)
    # Divide a physical drive into some partitions
    cdef FRESULT f_fdisk (BYTE pdrv, const LBA_t ptbl[], void* work)
    # Set current code page
    cdef FRESULT f_setcp (WORD cp)
    # Put a character to the file
    cdef int f_putc (TCHAR c, FIL* fp)
    # Put a string to the file
    cdef int f_puts (const TCHAR* str, FIL* cp)
    # Put a formatted string to the file
    cdef int f_printf (FIL* fp, const TCHAR* str, ...)
    # Get a string from the file
    cdef TCHAR* f_gets (TCHAR* buff, int len, FIL* fp)

    # TODO: Uncomment and fix these (conversion from fp to FIL* is needed)
    # #define f_eof(fp) ((int)((fp)->fptr == (fp)->obj.objsize))
    # cdef f_eof(fp):
    #     return fp.fptr == fp.obj.objsize

    # #define f_error(fp) ((fp)->err)
    # cdef f_error(fp):
    #     return fp.err

    # #define f_tell(fp) ((fp)->fptr)
    # cdef f_tell(fp):
    #     return fp.fptr

    # #define f_size(fp) ((fp)->obj.objsize)
    # cdef f_size(fp):
    #     return fp.obj.objsize

    # #define f_rewind(fp) f_lseek((fp), 0)
    # cdef f_rewind(fp):
    #     return f_lseek(fp, 0)

    # #define f_rewinddir(dp) f_readdir((dp), 0)
    # cdef f_rewinddir(dp):
    #     return f_readdir(dp, 0)

    # #define f_rmdir(path) f_unlink(path)
    # cdef f_rmdir(path):
    #     return f_unlink(path)

    # #define f_unmount(path) f_mount(0, path, 0)
    # cdef f_unmount(path):
    #     return f_mount(0, path, 0)



    #ifndef EOF
    #define EOF (-1)
    #endif
    cdef int EOF = -1








    # /* File access mode and open method flags (3rd argument of f_open) */
    # #define	FA_READ				0x01
    # #define	FA_WRITE			0x02
    # #define	FA_OPEN_EXISTING	0x00
    # #define	FA_CREATE_NEW		0x04
    # #define	FA_CREATE_ALWAYS	0x08
    # #define	FA_OPEN_ALWAYS		0x10
    # #define	FA_OPEN_APPEND		0x30
    cdef enum FILE_ACCESS:
        FA_READ		 = 0x01
        FA_WRITE	 = 0x02
        FA_OPEN_EXISTING = 0x00
        FA_CREATE_NEW	 = 0x04
        FA_CREATE_ALWAYS = 0x08
        FA_OPEN_ALWAYS	 = 0x10
        FA_OPEN_APPEND	 = 0x30


# TODO: Remove or wrap
# /* Fast seek controls (2nd argument of f_lseek) */
#define CREATE_LINKMAP	((FSIZE_t)0 - 1)

    # /* Format options (2nd argument of f_mkfs) */
    # #define FM_FAT		0x01
    # #define FM_FAT32	0x02
    # #define FM_EXFAT	0x04
    # #define FM_ANY		0x07
    # #define FM_SFD		0x08
    cdef enum MKFS_FORMAT:
        FM_FAT		= 0x01
        FM_FAT32	= 0x02
        FM_EXFAT	= 0x04
        FM_ANY		= 0x07
        FM_SFD		= 0x08


    # /* Filesystem type (FATFS.fs_type) */
    # #define FS_FAT12	1
    # #define FS_FAT16	2
    # #define FS_FAT32	3
    # #define FS_EXFAT	4
    cdef enum FATFS_TYPE:
        FS_FAT12	= 1
        FS_FAT16	= 2
        FS_FAT32	= 3
        FS_EXFAT	= 4

    # /* File attribute bits for directory entry (FILINFO.fattrib) */
    # #define	AM_RDO	0x01	/* Read only */
    # #define	AM_HID	0x02	/* Hidden */
    # #define	AM_SYS	0x04	/* System */
    # #define AM_DIR	0x10	/* Directory */
    # #define AM_ARC	0x20	/* Archive */
    cdef enum FILE_ATTR:
        AM_RDO	= 0x01	#  Read only
        AM_HID	= 0x02	#  Hidden
        AM_SYS	= 0x04	#  System
        AM_DIR	= 0x10	#  Directory
        AM_ARC	= 0x20	#  Archive
