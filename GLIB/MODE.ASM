__VER__		EQU	000
INCLUDE	\masm\std.inc

CGAconfig	EQU	3ddh
HGCconfig	EQU	3bfh
HGCcontrol	EQU	3b8h
HGCstatus	EQU	3bah
HGC6845_i	EQU	3b4h

CODEHDR
		PUBLIC	_gmode, _tmode
		PUBLIC	__gver, __gscr
		PUBLIC	__gcpx, __gcpy
		PUBLIC	__gssx, __gssy
		PUBLIC	__gswdt, __gshgt
		PUBLIC	__gcolor
_R6845_grp	DB	54,45,46, 8,91, 2,87,87
		DB	 2, 3, 0, 0, 0, 0, 0, 0
_R6845_txt	DB	97,80,82,15,25, 6,25,25
		DB	 2,13,11,12, 0, 0, 0, 0
__gver		DB	0,0		; 0.00
__gscr		DW	0b000h
__gcpx		DW	0		; current drawing point
__gcpy		DW	0
__gssx		DW	0		; adjust to start of screen
__gssy		DW	0
__gswdt		DW	720		; screen size x
__gshgt		DW	348		; same in y
__gcolor	DB	1		; current color


COMMENT	\
	Set HGC to graphics mode

	entry:	none
\
_gmode		PROC	NEAR
		push	si
		mov	al, 1
		mov	dx, CGAconfig
		out	dx, al
		mov	al, 2
		ZERO	bx
		mov	cx, 32768/2
		mov	si, OFFSET _R6845_grp
		jmp	SHORT __setmode

COMMENT	\
	Set HGC to text mode
\
_tmode		PROC	NEAR
		push	si
		ZERO	al
		mov	bx, 0700h+' '
		mov	cx, 80*25
		mov	si, OFFSET _R6845_txt

COMMENT	\
	Set HGC to given mode

	entry:	al	control port value without v_enable
		bx	fill word
		cx	# of words to clear
		si	offset to R6845 params
\
__setmode	PROC	NEAR
		push	ax
		push	cx
		mov	ah, al
		mov	al, 1
		mov	dx, HGCconfig
		out	dx, al			; HGC to half
		IO_DELAY
		mov	al, ah
		mov	dx, HGCcontrol
		out	dx, al			; HGC to mode without v_enable
		mov	cx, 16
		ZERO	ah
		mov	dx, HGC6845_i
		cld
__setmode100:	mov	al, ah
		out	dx, al
		IO_DELAY
		inc	dx
		lodsb
		out	dx, al
		dec	dx
		inc	ah
		loop	__setmode100
		pop	cx
		push	di
		ZERO	di
		mov	ax, 0b000h
		mov	__gscr, ax
		mov	es, ax
		mov	ax, bx
		repz	stosw
		pop	di
		mov	dx, HGCstatus	 	; wait till screen settles
		mov	cx, 5
__setmode200:	in	al, dx			; get status
		or	al, al
		js	__setmode300		; drawing screen
		jmp	SHORT __setmode200	; no, it isn't
__setmode300:	in	al, dx			; get again
		or	al, al
		jns	__setmode400		; not drawing screen
		jmp	SHORT __setmode300	; wait till it is
__setmode400:	loop	__setmode200
		pop	ax
		or	al, 8
		mov	dx, HGCcontrol
		out	dx, al			; HGC to mode with v_enable
		pop	si
		ret
__setmode	ENDP
_tmode		ENDP
_gmode		ENDP
CODEFTR
