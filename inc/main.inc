IF !DEF(MAIN_INC)
DEF MAIN_INC EQU 1

; Joystick flags
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DEF JOYF_DOWN       EQU %10000000
DEF JOYF_UP         EQU %01000000
DEF JOYF_LEFT       EQU %00100000
DEF JOYF_RIGHT      EQU %00010000
DEF JOYF_START      EQU %00001000
DEF JOYF_SELECT     EQU %00000100
DEF JOYF_B          EQU %00000010
DEF JOYF_A          EQU %00000001

DEF JOYE_DISABLED   EQU %10000000


; Shadow OAM address
DEF _SHADOW_OAM     EQU $C000

MACRO ON_UPDATE
    ld a, HIGH(\1)
    ldh [UpdateSub.addrHigh], a
    ld a, LOW(\1)
    ldh [UpdateSub.addrLow], a
ENDM

ENDC