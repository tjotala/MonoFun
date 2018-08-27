ideal                                   ; TASM ideal mode
p386n                                   ; i386 real mode instructions
smart                                   ; smart instructions
warn                                    ; enable all warnings
jumps                                   ; enable jump-arounds
locals                                  ; enable local symbols
model tiny,pascal                       ; tiny model, pascal calling conv

include "monofun.inc"
include "dos.inc"
include "vio.inc"
include "amis.inc"

codeseg
assume cs:@code,ds:nothing,es:nothing,ss:nothing
org 002ch
label EnvSegAddr word

org 0100h                                ; for a .COM file

Begin:
        jmp InitApp

Signature AMIS_Signature <'TJOtala','MonoFun','Monochrome Display Idle Twiddler'>

Hooks AMIS_Hook <008h,offset Int08h>
      AMIS_Hook <02dh,offset Int2Dh>
label EndOfHooks near

MultiplexNum db ?

Timer dw DefTimer
InitTimer dw DefTimer

proc DummyReset far
        ret
endp

;
; Interrupt 08h handler
;
; Purpose:
;       Handles the fun part.
; In:
;       none
; Out:
;       none
; Notes:
;       This handler must NOT alter any registers and/or flags.
;
Int08h AMIS_Handler <,?,,,offset DummyReset,>
proc Int08Handler far
        cmp [Timer],0
        je @@NoTimer
        dec [Timer]
        jnz @@Continue
        pusha
        push ds es
        push cs
        pop ds
        assume ds:@code
        mov ax,[InitTimer]
        mov [Timer],ax
        call Draw
        pop es ds
        assume ds:nothing
        popa
@@NoTimer:
@@Continue:
        jmp [Int08h.NextHandler]
endp

;
; Interrupt 2Dh handler
;
; Purpose:
;       Handles AMIS API calls.
; In:
;       ah = function
;       other registers = depends on the function
; Out:
;       depends on the function
; Notes:
;       See Ralf Brown's Interrupt List for the AMIS spec.
;
Int2Dh AMIS_Handler <,?,,,offset DummyReset,>
proc Int2DHandler far
        cmp ah,[MultiplexNum]
        je @@Handle
        jmp [Int2Dh.NextHandler]
@@Handle:
        cmp al,AmisLast
        ja @@NotImplemented
        xor ah,ah
        add ax,ax
        xchg bx,ax
        jmp [@@Handlers + bx]

label @@Handlers word
        dw offset @@InstallationCheck
        dw offset @@GetEntryPoint
        dw offset @@UnInstall
        dw offset @@RequestPopUp
        dw offset @@GetChainedInts
        dw offset @@GetHotKeys

@@InstallationCheck:
        mov cx,VersionNum
        lea di,[Signature]
        mov dx,cs
        mov al,0ffh
        iret

@@GetEntryPoint:
@@UnInstall:
@@RequestPopUp:
@@GetHotKeys:
@@NotImplemented:
        mov al,000h
        iret

@@GetChainedInts:
        lea bx,[Hooks]
        mov al,004h
        iret
endp

assume ds:@code
include "graphics.asm"

assume ds:@code
label InitCode near

;
; InitApp
;
; Purpose:
;       Initializes this application
; In:
;       ds,es = PSP segment address
; Out:
;       none, returns via DOS Terminate or DOS StayResident function calls.
;
proc InitApp far
;
; Greet user
;
        lea dx,[GreetMsg]
        dos DosDisplayString
;
; Check DOS version
;
        dos DosGetVersion
        xchg al,ah
        cmp ax,00300h
        jae @@DosOk
        lea dx,[BadDosMsg]
        dos DosDisplayString
        int 20h
@@DosOk:
;
; Find a previous copy of this application
;
        call FindResidentMultiplexNumber
        jc @@Install
        mov [MultiplexNum],ah
        mov [ResCopyAddr],es
;
; Disable resident copy
;
        mov [es:Timer],0
;
; Terminate the fun module
;
        call Terminate
;
; Uninstall interrupt handlers
;
        call UnInstallHandlers pascal,[ResCopyAddr]
        jc @@Exit
;
; Release memory
;
        mov es,[ResCopyAddr]
        dos DosFreeMemory
;
; Inform user
;
        lea dx,[UnInstalledMsg]
;
; Display a string & exit
;
@@Exit:
        dos DosDisplayString
        dos DosTerminate,000h
;---------------------------------------
@@Install:
;
; Find free multiplex number for us to use
;
        call FindFreeMultiplexNumber
        jnc @@MultiplexOk
        lea dx,[NoMultiplexNumMsg]
        jmp @@Exit
@@MultiplexOk:        
        mov [MultiplexNum],ah
;
; Start the fun module
;
        call Initialize
;
; Install interrupt handlers
;
        call InstallHandlers
;
; Free environment strings block
;
        mov es,[EnvSegAddr]
        dos DosFreeMemory
;
; Inform user
;
        lea dx,[InstalledMsg]
        dos DosDisplayString
;
; Stay resident
;
        mov dx,offset InitCode
        add dx,0fh
        shr dx,4
        dos DosStayResident
endp

;
; FindResidentMultiplexNumber
;
; Purpose:
;       Finds the multiplex number of a previous copy of this application.
; In:
;       none
; Out:
;       cf = cleared if found, set if not
;       ah = multiplex number if found
;       es = segment address of the resident copy
;
proc FindResidentMultiplexNumber
uses di
if AmisInstallationCheck eq 0
        xor ax,ax
else
        mov ax,(0 shl 8) or (AmisInstallationCheck and 00fh)
endif
@@Loop:
        push ax
        amis
        test al,al
        pop ax
        jz @@TryNext
        cmp cx,VersionNum
        jne @@TryNext
        lea si,[Signature]
        mov es,dx
        mov cx,size Signature
        cld
        repz cmpsb
        jz @@Exit
@@TryNext:
        inc ah
        jnz @@Loop
        stc
@@Exit:
        ret
endp

;
; FindFreeMultiplexNumber
;
; Purpose:
;       Finds a free multiplex number.
; In:
;       none
; Out:
;       cf = cleared if found, set if not
;       ah = multiplex number if found
;
proc FindFreeMultiplexNumber
uses di
if AmisInstallationCheck eq 0
        xor ax,ax
else
        mov ax,(0 shl 8) or (AmisInstallationCheck and 00fh)
endif
@@Loop:
        push ax
        amis
        test al,al
        pop ax
        jz @@Exit
        inc ah
        jnz @@Loop
        stc
@@Exit:
        ret
endp

;
; InstallHandlers
;
; Purpose:
;       Installs the interrupt handlers for this application.
; In:
;       none
; Out:
;       cf = cleared if success, set if error
;       dx -> offset of error message
;
proc InstallHandlers
uses si,di
        lea si,[Hooks]
@@Loop:
        mov al,[(AMIS_Hook ds:si).InterruptNum]
        dos DosGetVector
        mov di,[(AMIS_Hook ds:si).HandlerOffs]
        mov [word low (AMIS_Handler ds:di).NextHandler],bx
        mov [word high (AMIS_Handler ds:di).NextHandler],es
        mov al,[(AMIS_Hook ds:si).InterruptNum]
        mov dx,di
        dos DosSetVector
        add si,size AMIS_Hook
        cmp si,offset EndOfHooks
        jb @@Loop
        clc
        ret
endp

;
; UnInstallHandlers
;
; Purpose:
;       Uninstalls the application.
; In:
;       SegAddr = segment address of the copy to uninstall
; Out:
;       cf = cleared if success, set if error
;       dx -> offset of error message
;
proc UnInstallHandlers
arg @@SegAddr:word
uses si,di,ds
        lea si,[Hooks]
@@Loop:
        mov ds,[@@SegAddr]
        mov al,[(AMIS_Hook ds:si).InterruptNum]
        dos DosGetVector
        mov di,[(AMIS_Hook ds:si).HandlerOffs]
        mov dx,ds
        cmp bx,di                       ; is our handler top dog?
        jne @@TraverseHandlers          ; no, traverse handlers
        mov ax,es
        cmp ax,dx                       ; is our handler top dog?
        jne @@TraverseHandlers
        mov al,[(AMIS_Hook ds:si).InterruptNum]
        lds dx,[(AMIS_Handler ds:di).NextHandler]
        dos DosSetVector
        jmp @@NextInterrupt

@@BadHandler:
        lea dx,[BadUnInstallMsg]
        stc
        jmp @@Exit

@@TryNextHandler:
        les bx,[(AMIS_Handler es:bx).NextHandler]
@@TraverseHandlers:
        cmp [(AMIS_Handler es:bx).JumpToHandler],AmisShortJump
        jne @@BadHandler
        cmp [(AMIS_Handler es:bx).Signature],AmisSignature
        jne @@BadHandler
        cmp [word low (AMIS_Handler es:bx).NextHandler],di
        jne @@TryNextHandler
        cmp [word high (AMIS_Handler es:bx).NextHandler],dx
        jne @@TryNextHandler
        cli
        lds ax,[(AMIS_Handler ds:di).NextHandler]
        mov [word low (AMIS_Handler es:bx).NextHandler],ax
        mov [word high (AMIS_Handler es:bx).NextHandler],ds
        sti

@@NextInterrupt:
        add si,size AMIS_Hook
        cmp si,offset EndOfHooks
        jb @@Loop
        clc
@@Exit:        
        ret
endp



GreetMsg db \
  'MonoFun v',\
  VersionNumMajor + '0','.',(VersionNumMinor / 10) + '0',(VersionNumMinor mod 10) + '0',\
  '  Copyright (c)1995 Tapani J. Otala',13,10,'$'
BadDosMsg db \
  'DOS 3.x or later required, not installed.',13,10,'$'
NoMultiplexNumMsg db \
  'Out of multiplex numbers, not installed.',13,10,'$'
InstalledMsg db \
  'Installed.',13,10,'$'
UnInstalledMsg db \
  'Uninstalled.',13,10,'$'
BadUnInstallMsg db \
  'Unable to unload, disabled.',13,10,'$'

ResCopyAddr dw ?

ends
end Begin

