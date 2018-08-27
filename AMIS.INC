
enum AmisFunctions {
  AmisInstallationCheck = 000h,
  AmisGetEntryPoint,
  AmisUnInstall,
  AmisRequestPopUp,
  AmisGetChainedInst,
  AmisGetHotKeys,
  AmisLast = AmisGetHotKeys
}

macro amis Func
  ifnb <Func>
        mov al,Func
  endif
        int 2dh
endm

AmisSignature = 424bh
AmisShortJump = 10ebh

struc AMIS_Signature
  ManufacturerName db 8 dup(' ')
  ProductName db 8 dup(' ')
  Description db 64 dup(0)
ends

struc AMIS_Hook
  InterruptNum db ?
  HandlerOffs dw ?
ends

struc AMIS_Handler
  JumpToHandler dw AmisShortJump
  NextHandler dd ?
  Signature dw AmisSignature
  EoiFlag db 000h
  JumpToReset dw ?
  Reserved db 7 dup(0)
ends

