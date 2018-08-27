__VER__		EQU	000
INCLUDE \masm\std.inc
		EXTRN	__gcolor:BYTE, __gscr:WORD
		EXTRN	__gcpx:WORD, __gcpy:WORD
		EXTRN	__gplot:NEAR
CODEHDR
		PUBLIC	_gline, __gline

COMMENT	\
	Draw a line to graphics screen using an improved Bresenham's
	line drawing algorithm.

	entry:	ax	sx
		bx	sy
		cx	ex
		dx	ey
	within:	si	x
		di	y
\
_dx_diag	EQU	[bp-2]
_dy_diag	EQU	[bp-4]
_dx_nondiag	EQU	WORD PTR [bp-6]
_dy_nondiag	EQU	WORD PTR [bp-8]
_diag_inc	EQU	[bp-10]
_nondiag_inc	EQU	[bp-12]
_d		EQU	WORD PTR [bp-14]
_gline		PROC	NEAR
		mov	es, __gscr
__gline:	push	bp
		push	si
		push	di
		mov	bp, sp
		sub	sp, 7*2
		mov	si, ax		; x=sx
		mov	di, bx		; y=sy
		mov	__gcpx, cx	; update 'current pos'
		mov	__gcpy, dx
		mov	ax, 1		; dx_diag=1
		mov	bx, ax		; dy_diag=1
		sub	cx, si		; a=ex-sx
		jns	_gline100
		not	cx		; a=-a
		neg	ax		; dx_diag=-1
_gline100:	sub	dx, di		; b=ey-sy
		jns	_gline200
		not	dx		; b=-b
		neg	bx		; dy_diag=-1
_gline200:	mov	_dx_diag, ax
		mov	_dy_diag, bx
		cmp	cx, dx		; a<b?
		jae	_gline300
		xchg	cx, dx		; swap a,b
		mov	_dx_nondiag, 0
		mov	_dy_nondiag, bx	; dy_nondiag=dy_diag
		jmp	SHORT _gline400
_gline300:	mov	_dx_nondiag, ax	; dx_nondiag=dx_diag
		mov	_dy_nondiag, 0
_gline400:	add	dx, dx		; nondiag_inc=b+b
		mov	_nondiag_inc, dx
		sub	dx, cx		; d=nondiag_inc-a
		mov	_d, dx
		sub	dx, cx		; diag_inc=d-a
		mov	_diag_inc, dx
		inc	cx
		jmp	SHORT _gline700
_gline500:	cmp	_d, 0
		jge	_gline600
		add	si, _dx_nondiag
		add	di, _dy_nondiag
		mov	ax, _nondiag_inc
		add	_d, ax
		jmp	SHORT _gline700
_gline600:	add	si, _dx_diag
		add	di, _dy_diag
		mov	ax, _diag_inc
		add	_d, ax
_gline700:	push	cx
		mov	ax, si
		mov	bx, di
		mov	dl, __gcolor
		call	__gplot
		pop	cx
		loop	_gline500
		mov	sp, bp
		pop	di
		pop	si
		pop	bp
		ret
_gline		ENDP
CODEFTR
