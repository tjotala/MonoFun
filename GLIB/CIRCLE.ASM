__VER__		EQU	000
INCLUDE \masm\std.inc
		EXTRN	__gscr:WORD, __gcolor:BYTE
		EXTRN	__gplot:NEAR
CODEHDR
		PUBLIC	_gcircle, __gcircle

COMMENT	\
	Draw a circle to graphics screen using an improved Bresenham circle
	drawing algorithm

	entry:	ax	cx
		bx	cy
		cx	radius
	within:	-2	cx
		-4	cy
		-6	ie
		si	ix
		di	iy
\
_cx		EQU	[bp-2]
_cy		EQU	[bp-4]
_ie		EQU	[bp-6]
_gcircle	PROC	NEAR
		mov	es, __gscr
__gcircle:	push	bp
		push	si			; ix
		push	di			; iy
		mov	bp, sp
		sub	sp, 3*2
		mov	_cx, ax
		mov	_cy, bx
		ZERO	si			; ix=0
		mov	di, cx			; iy=r
		mov	_ie, si			; ie=0
		jmp	SHORT _gcircle300
_gcircle100:	mov	ax, _ie
		or	ax, ax
		jns	_gcircle200		; if ie<0, do
		add	ax, di
		stc
		adc	ax, di			; ie+=2*iy+1
		dec	di			; iy--
_gcircle200:	sub	ax, si
		stc
		sbb	ax, si			; ie-=2*ix+1
		inc	si			; ix++
		mov	_ie, ax
; bottom right
		mov	bx, _cy
		add	bx, di			; cy+iy
		mov	ax, _cx
		add	ax, si			; cx+ix
		mov	dl, __gcolor
		call	__gplot			; cx+ix, cy+iy
; bottom left
		mov	bx, _cy
		add	bx, di			; cy+iy
		mov	ax, _cx
		sub	ax, si			; cx-ix
		mov	dl, __gcolor
		call	__gplot			; cx-ix, cy+iy
; middle bottom right
		mov	bx, _cy
		add	bx, si			; cy+ix
		mov	ax, _cx
		add	ax, di			; cx+iy
		mov	dl, __gcolor
		call	__gplot			; cx+iy, cy+ix
; middle bottom left
		mov	bx, _cy
		add	bx, si			; cy+ix
		mov	ax, _cx
		sub	ax, di			; cx-iy
		mov	dl, __gcolor
		call	__gplot			; cx-iy, cy+ix
_gcircle300:
; top left
		mov	bx, _cy
		sub	bx, di			; cy-iy
		mov	ax, _cx
		sub	ax, si			; cx-ix
		mov	dl, __gcolor
		call	__gplot			; cx-ix, cy-iy
; top right
		mov	bx, _cy
		sub	bx, di			; cy-iy
		mov	ax, _cx
		add	ax, si			; cx+ix
		mov	dl, __gcolor
		call	__gplot			; cx+ix, cy-iy
; middle top left
		mov	bx, _cy
		sub	bx, si			; cy-ix
		mov	ax, _cx
		sub	ax, di
		mov	dl, __gcolor
		call	__gplot			; cx-iy, cy-ix
; middle top right
		mov	bx, _cy
		sub	bx, si			; cy-ix
		mov	ax, _cx
		add	ax, di			; cx+iy
		mov	dl, __gcolor
		call	__gplot			; cx+iy, cy-ix

		cmp	si, di			; ix>iy?
		ja	_gcircle400
		jmp	_gcircle100		; not yet, wrap

_gcircle400:	mov	sp, bp
		pop	di
		pop	si
		pop	bp
		ret
_gcircle	ENDP
CODEFTR
