
VioSetCursorShape = 001h
VioGetCursorShape = 003h

macro vio Func:req,Param
  ifnb <Param>
        mov ax,((Func) shl 8) or (Param)
  else
        mov ah,Func
  endif
        int 010h
endm

