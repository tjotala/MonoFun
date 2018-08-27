__VER__		EQU	000
INCLUDE \masm\std.inc
		EXTRN	__gscr:WORD, __gaddrs:WORD
		EXTRN	__gssx:WORD, __gssy:WORD, __gswdt:WORD, __gshgt:WORD
CODEHDR
		PUBLIC	_gplot, __gplot

COMMENT	\
	Plot a pixel to graphics screen

	- home point (0,0) is at the upper left corner of the screen
	- starting point of the screen can be adjusted via __gssx & __gssy
	- pixels are clipped if they reside outside following coordinates
		x: __gssx...__gssx+__gswdt
		y: __gssy...__gssy+__gshgt

	entry:	ax	x
		bx	y
		dl	color; 0=clear, 1=set, 2=reverse
	return:	es	screen segment
		bx	pixel address
		al	pixel mask; NOT if color was 0
\
_gplot		PROC	NEAR
		mov	es, __gscr		; es=target seg
__gplot:	cmp	ax, __gswdt
		jae	_gplot900
		cmp	bx, __gshgt
		jae	_gplot900
		add	ax, __gssx
		add	bx, __gssy
		shl	bx, 1			; y*2
		mov	bx, __gaddrs[bx]	; get line start offs
		mov	ch, al
		mov	cl, 3
		shr	ax, cl			; /8 for byte#
		add	bx, ax			; bx=byte address
		and	ch, 00000111b		; get pixel bit# from left
		mov	cl, ch
		mov	al, 128
		shr	al, cl			; al=OR mask
		or	dl, dl			; ah=0=clear?
		jnz	_gplot100
		not	al			; reverse mask
		and	es:[bx], al		; clear the pixel
		ret
_gplot100:	dec	dl
		jnz	_gplot200
		or	es:[bx], al		; set the pixel
		ret
_gplot200:	xor	es:[bx], al		; otherwise, reverse it
_gplot900:	ret
_gplot		ENDP
CODEFTR
