
VersionNumMajor = 000h
VersionNumMinor = 000h
VersionNum = (VersionNumMajor shl 8) + VersionNumMinor

DefTimer = 1                            ; default timer, 1 tick

FunSignature = ('O' shl 8) or 'T'

struc Fun
  Signature dw FunSignature
  Initialize dw ?                       ; -> initialization function
  Terminate dw ?                        ; -> termination function
  Draw dw ?                             ; -> drawing function
ends

