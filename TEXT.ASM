ideal                                   ; TASM ideal mode
p386n                                   ; i386 real mode instructions
smart                                   ; smart instructions
warn                                    ; enable all warnings
jumps                                   ; enable jump-arounds
locals                                  ; enable local symbols
model tiny,pascal                       ; tiny model, pascal calling conv

include "monofun.inc"

struc Point
  x dw ?
  y dw ?
ends

struc Dot
  Pos Point <?,?>
  Flag dw ?
ends

MaxDots = 75

codeseg
org 000h
Fun <,offset Initialize,offset Terminate,offset Draw>

ScreenAddr dw 0b000h
ScreenWidth dw 80
ScreenHeight dw 25

Dots Dot MaxDots dup()
LeadDot dw offset Dots
LeadDir Point <1,1>

;
; Draw
;
; Purpose:
;       Does fun things with monochrome screen in text mode.
; In:
;       none
; Out:
;       none
;
proc Draw
        mov si,[LeadDot]
        add si,size Dot
        cmp si,offset LeadDot
        jb @@NewLeadOk
        lea si,[Dots]
@@NewLeadOk:
        cmp [(Dot ds:si).Flag],0
        je @@NoErase
        call @@DrawDot
@@NoErase:

        mov bx,[LeadDot]
        mov ax,[(Dot ds:bx).Pos.x]
        add ax,[LeadDir.x]
        cmp ax,[ScreenWidth]
        jb @@NewXOk
        neg [LeadDir.x]
        add ax,[LeadDir.x]
@@NewXOk:
        mov [(Dot ds:si).Pos.x],ax

        mov ax,[(Dot ds:bx).Pos.y]
        add ax,[LeadDir.y]
        cmp ax,[ScreenHeight]
        jb @@NewYOk
        neg [LeadDir.y]
        add ax,[LeadDir.y]
@@NewYOk:
        mov [(Dot ds:si).Pos.y],ax

        mov [(Dot ds:si).Flag],1
        call @@DrawDot
        mov [LeadDot],si
        ret

;
; @@DrawDot
;
; Purpose:
;       Draws a single dot.
; In:
;       ds:si -> dot to draw
; Out:
;       ds:si -> dot
;
proc @@DrawDot
        mov es,[ScreenAddr]
        mov ax,[(Dot ds:si).Pos.y]
        mul [ScreenWidth]
        add ax,[(Dot ds:si).Pos.x]
        add ax,ax
        mov bx,ax
        not [byte es:bx + 1]
        ret
endp
endp

;
; ClearTextScreen
;
; Purpose:
;       Clears the screen.
; In:
;       none
; Out:
;       none
;
proc ClearTextScreen
        xor di,di
        mov es,[ScreenAddr]
        mov ax,[ScreenWidth]
        mul [ScreenHeight]
        mov cx,ax
        mov ax,(007h shl 8) or ' '
        cld
        rep stosw
        ret
endp

;
; Initialize
;
; Purpose:
;       Initializes this module.
; In:
;       none
; Out:
;       cf = cleared if success, set if failed
;
proc Initialize
        xor bh,bh
        vio VioGetCursorShape
        mov [CursorShape],cx
        xor bh,bh
        mov ch,00100000b
        vio VioSetCursorShape
        call ClearTextScreen
        clc
        ret
endp

;
; Terminate
;
; Purpose:
;       Terminates this module.
; In:
;       none
; Out:
;       cf = cleared if success, set if failed
;
proc Terminate
        xor bh,bh
        mov cx,[CursorShape]
        vio VioSetCursorShape
        call ClearTextScreen
        clc
        ret
endp
ends
end

