
struc Point
  x dw ?
  y dw ?
ends

struc Dot
  Pos Point <?,?>
  Flag dw ?
ends

MaxDots = 75

CGAConfigPort = 003ddh
HGCConfigPort = 003bfh
HGCControlPort = 003b8h
HGCStatusPort = 003bah
HGC6845IndexPort = 003b4h
HGC6845DataPort = (HGC6845IndexPort + 1)

macro iodelay
        jmp $+2
endm

ScreenAddr dw 0b000h
ScreenWidth dw 720
ScreenHeight dw 348

Dots Dot MaxDots dup()
LeadDot dw offset Dots
LeadDir Point <1,1>

R6845_Graphics db 54,45,46, 8,91, 2,87,87,\
                   2, 3, 0, 0, 0, 0, 0, 0
R6845_Text     db 97,80,82,15,25, 6,25,25,\
                   2,13,11,12, 0, 0, 0, 0

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
        mov es,[ScreenAddr]
        mov si,[LeadDot]
        add si,size Dot
        cmp si,offset LeadDot
        jb @@NewLeadOk
        lea si,[Dots]
@@NewLeadOk:
        cmp [(Dot ds:si).Flag],0
        je @@NoErase
        call @@DrawDot,[(Dot ds:si).Pos.x],[(Dot ds:si).Pos.y]
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
        call @@DrawDot,[(Dot ds:si).Pos.x],[(Dot ds:si).Pos.y]
        mov [LeadDot],si
        ret

proc @@DrawDot
arg @@x:word,@@y:word
uses si,di
        mov si,[@@x]
        mov di,[@@y]
        call DrawDot
        ret
endp
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
;        mov al,00000001b
;        mov dx,CGAConfigPort
;        out dx,al
        call SetMode,00000010b,offset R6845_Graphics,0,32768 / 2
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
        call SetMode,00000000b,offset R6845_Text,(007h shl 8) or ' ',80 * 25
        clc
        ret
endp

;
; SetMode
;
; Purpose:
;       Sets the monochrome screen to the requested mode.
; In:
;       Mode = mode value without video enable (bit 3)
;       CRTCValues -> CRT controller values
;       Fill = fill word
;       Words = # of words to fill
; Out:
;       none
;
proc SetMode
arg @@Mode:byte,@@CRTCValues:near ptr byte,@@Fill:word,@@Words:word
uses si,di
        mov al,1
        mov dx,HGCConfigPort
        out dx,al                       ; switch to 'half' mode
        iodelay

        mov al,[@@Mode]
        mov dx,HGCControlPort
        out dx,al                       ; switch to the requested mode

        mov cx,16                       ; 16 values to output
        xor ah,ah                       ; start with index 0
        mov si,[@@CRTCValues]
        mov dx,HGC6845IndexPort
        cld
@@Loop:
        mov al,ah
        out dx,al
        iodelay
        lodsb
errif HGC6845IndexPort ne (HGC6845DataPort - 1)
        inc dx
        out dx,al
        dec dx
        inc ah
        loop @@Loop

        mov es,[ScreenAddr]
        xor di,di
        mov cx,[@@Words]
        mov ax,[@@Fill]
        rep stosw

        mov cx,5
        mov dx,HGCStatusPort
@@WaitLoop1:
        in al,dx
        or al,al
        jns @@WaitLoop1
@@WaitLoop2:
        in al,dx
        or al,al
        js @@WaitLoop2
        loop @@WaitLoop1

        mov al,[@@Mode]
        or al,00001000b                 ; enable video output
        mov dx,HGCControlPort
        out dx,al                       ; switch to the requested mode

        ret
endp

;
; DrawLine
;
; Purpose:
;       Draws a line using an improved Bresenham's integer
;       line drawing algorithm.
; In:
;       sx,sy = start coordinates
;       ex,ey = end coordinates
; Out:
;       none
;
proc DrawLine
arg @@sx:word,@@sy:word,@@ex:word,@@ey:word
local @@dx_diag:word,@@dy_diag:word,@@dx_nondiag:word,@@dy_nondiag:word,\
 @@diag_inc:word,@@nondiag_inc:word,@@d:word
        mov es,[ScreenAddr]
        mov si,[@@sx]                   ; x=sx
        mov di,[@@sy]                   ; y=sy
        mov ax,1                        ; dx_diag=1
        mov bx,ax                       ; dy_diag=1
        mov cx,[@@ex]
        sub cx,si                       ; a=ex-sx
        jns @@XOk
        neg cx                          ; a=-a
        neg ax                          ; dx_diag=-1
@@XOk:
        mov dx,[@@ey]
        sub dx,di                       ; b=ey-sy
        jns @@YOk
        neg dx                          ; b=-b
        neg bx                          ; dy_diag=-1
@@YOk:
        mov [@@dx_diag],ax
        mov [@@dy_diag],bx
        cmp cx,dx                       ; a<b?
        jae @@DiagOk
        xchg cx,dx                      ; swap a,b
        mov [@@dx_nondiag],0
        mov [@@dy_nondiag],bx           ; dy_nondiag=dy_diag
        jmp @@DiagOk
@@SlopeOk:
        mov [@@dx_nondiag],ax           ; dx_nondiag=dx_diag
        mov [@@dy_nondiag],0
@@DiagOk:
        add dx,dx                       ; nondiag_inc=b+b
        mov [@@nondiag_inc],dx
        sub dx,cx                       ; d=nondiag_inc-a
        mov [@@d],dx
        sub dx,cx                       ; diag_inc=d-a
        mov [@@diag_inc],dx
        inc cx
        jmp @@BeginLoop
@@Loop:
        cmp [@@d],0
        jge @@SlopeOk2
        add si,[@@dx_nondiag]
        add di,[@@dy_nondiag]
        mov ax,[@@nondiag_inc]
        jmp @@ResumeLoop
@@SlopeOk2:
        add si,[@@dx_diag]
        add di,[@@dy_diag]
        mov ax,[@@diag_inc]
@@ResumeLoop:
        add [@@d],ax
@@BeginLoop:
        call DrawDot,si,di
        loop @@Loop
        ret
endp

;
; DrawDot
;
; Purpose:
;       Draws a dot at the given coordinates.
; In:
;       si,di = coordinates
;       es = screen address
; Out:
;       none
;
proc DrawDot
        mov bx,di
        add bx,bx
        mov bx,[@@LineAddr + bx]
        mov ax,si
        shr ax,3
        add ax,bx
        mov bx,si
        and bx,7
        mov bl,[@@BitMask + bx]
        xchg bx,ax
        xor [es:bx],al
        ret

label @@LineAddr word
cnt = 0
rept 348
  dw (cnt and 3) * 2000h + (cnt / 4) * 90
  cnt = cnt + 1
endm
label @@BitMask byte
cnt = 0
rept 8
  db 10000000b shr cnt
  cnt = cnt + 1
endm
endp

