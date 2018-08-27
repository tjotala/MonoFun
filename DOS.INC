
enum DosFunctions {
  DosDisplayString = 009h,
  DosSetVector = 025h,
  DosGetVersion = 030h,
  DosStayResident = 031h,
  DosGetVector = 035h,
  DosFreeMemory = 049h,
  DosTerminate = 04ch
}  

macro dos Func:req,Param
  ifnb <Param>
        mov ax,((Func) shl 8) or (Param)
  else
        mov ah,Func
  endif
        int 021h
endm

