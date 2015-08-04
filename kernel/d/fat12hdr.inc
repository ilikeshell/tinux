;----------------------------------------------------------------------------------------------
;	FAT12磁盘头
;----------------------------------------------------------------------------------------------
BS_OEMName		db	"ForrestY"		;OEM厂商名，共8个字节
BPB_BytesPerSec	dw 	512			;每扇区字节数，共2个字节
BPB_SecPerClus	db	1			;每个簇的扇区数，共1个字节
BPB_RsvdSecCnt	dw	1			;boot记录占用多少扇区，共2个字节
BPB_NumFATs		db	2			;共有多少个FAT表，共1个字节
BPB_RootEntCnt	dw	224			;根目录文件数最大值，共2个字节
BPB_TotSec16		dw	2880			;逻辑扇区总数，共2个字节
BPB_Media		db	0F0h			;介质描述符，共1个字节
BPB_FATSz16		dw	9			;每个FAT表所占用的扇区数，共2个字节
BPB_SecPerTrk		dw	18			;每个磁道扇区数，共2个字节
BPB_NumHeads		dw	2			;磁头数，共2个字节
BPB_HiddSec		dd	0			;隐藏扇区数，共4个字节
BPB_TotSec32		dd	0			;如果BPB_TotSec16为0，则由该值记录扇区数，共4个字节
BS_DrvNum		db	0			;中断13的驱动器号，共1个字节
BS_Reserved1		db	0			;未使用，共1个字节
BS_BootSig		db	29h			;扩展引导标记，共1个字节
BS_VolID		dd	0			;卷序列号，共4个字节
BS_VolLab		db	"Tinux  Boot"		;卷标，必须11个字节
BS_FileSysType	db	"FAT12   "		;文件系统类型，必须8个字节
;----------------------------------------------------------------------------------------------
;	基于FAT12的一些常量定义
;----------------------------------------------------------------------------------------------
FATSz			equ	9
RootDirSectors	equ	14			;224 * 32 / 512 = 14
SectorNoOfRootDir	equ	19			;根目录从19号扇区开始
OffsetFatTblSec	equ	1			;Fat表从1号扇区开始
OffsetDataSec		equ	RootDirSectors + SectorNoOfRootDir - 2

