__VER__		EQU	000
INCLUDE \masm\std.inc
CODEHDR
		PUBLIC	__gaddrs
__gaddrs	LABEL	WORD	; Line start offsets to HGC graphics screen
cnt		=	0
		REPT	348
		DW	(cnt AND 3)*2000h+(cnt/4)*90
cnt		=	cnt+1
		ENDM
CODEFTR
