; -----------------------------------------------------------------------------
; Main file
; -----------------------------------------------------------------------------
;
INCLUDE "hardware.inc"
INCLUDE "main.inc"
INCLUDE "word_list.inc"

    MACRO UNUSED_INT
.s\@ jr .s\@     ;trap unused interrupt
    DS 6, $00
    ENDM

SECTION "Main HRAM Variables", HRAM 
CurrentFrameAsync:
    DS 1    
CurrentFrame::
    DS 1  

Joypad::
.state
    DS 1
.press
    DS 1
.enabled
    DS 1
.end

SECTION "RST 0", ROM0[$0000]
Rst0::
    UNUSED_INT
.end

SECTION "RST 8", ROM0[$0008]
Rst8::    
    ld a, [Joypad.state]
    ret
.end

SECTION "RST 10", ROM0[$0010]
Rst10::
    UNUSED_INT
.end

SECTION "RST 18", ROM0[$0018]
Rst18::
    UNUSED_INT
.end

SECTION "RST 20", ROM0[$0020]
Rst20::
    UNUSED_INT
.end

SECTION "RST 28", ROM0[$0028]
Rst28::
    UNUSED_INT
.end

SECTION "RST 30", ROM0[$0030]
Rst30::
    UNUSED_INT
.end

SECTION "RST 38", ROM0[$0038]
Rst38::
    UNUSED_INT
.end

; INT 40 - VBlank interrupt handler
; ------------------------------------------------------------------------------
; Increase frame counter, DMA shadow OAM to OAM and wake main game loop
SECTION "INT40_VBlank", ROM0[$0040]
INT40_VBlank:     
    push hl
    ld hl, CurrentFrameAsync  
    inc [hl]    
    jp DmaSub
.end

; Rest of INT 40 - VBlank interrupt handler is copied into HRAM at start due to DMA
SECTION "DmaSubCode", ROM0
DmaSubCode:
    pop hl
    push af 
    ld a, $C0
    ldh [rDMA], a
    ld a, 40
.copy
    dec a
    jr nz, .copy
    pop af
    reti
.end

; INT 48 - STAT interrupt handler
SECTION "INT48_Stat", ROM0[$0048]
INT48_Stat:
    UNUSED_INT
.end

; INT 50 - Timer interrupt handler
SECTION "INT50_Timer", ROM0[$0050]
INT50_Timer: 
    UNUSED_INT
.end 

; INT 58 - Serial interrupt handler
SECTION "INT58_Serial", ROM0[$0058]
INT58_Serial:
    UNUSED_INT
.end

; INT 60 - Joypad interrupt handler
SECTION "INT60_Joypad", ROM0[$0060]
INT60_Joypad:
    UNUSED_INT
.end

; Unused space between $0068 and up to $0100
SECTION "Unused space between $0068 and up to $0100", ROM0[$0068]
UnusedSpaceAt0068:
    DS $0100 - $0068, $00
.end
    
; Entry point (4 bytes)
SECTION "Cartridge Header Entry Point",ROM0[$0100]     
    di
    nop
    jr Main

SECTION "CH Nintendo Logo",ROM0[$0104]
    NINTENDO_LOGO

SECTION "CH Title",ROM0[$0134]
    DB "GBORDLE"
    DS 4, $00

SECTION "CH Manufacturer Code",ROM0[$013f]
    DS 4, $00

SECTION "CH CGB Code", ROM0[$0143]
    DB $80  ; CGB supported

SECTION "CH New Licence Code", ROM0[$0144]
    DW $0000

SECTION "CH SGB Flag", ROM0[$0146]
    DB $00  ; no sgb

SECTION "CH Cartridge Type", ROM0[$0147]
    DB $01  ; mcb1

SECTION "CH ROM Size", ROM0[$0148]
    DB $01  ; 64kb

SECTION "CH RAM Size", ROM0[$0149]    
    DB $00  ; 0kb

SECTION "CH Destination Code", ROM0[$014a]    
    DB $00  ; jp + overseas

SECTION "CH Old Licence Code", ROM0[$014b]
    DB $00

SECTION "CH Mask Rom Version Number", ROM0[$014c]
    DB $00

SECTION "CH Header Checksum", ROM0[$014d]
    DB $00

SECTION "CH Global Checksum", ROM0[$014e]
    DW $0000

; Main function
SECTION "Main",ROM0[$0150]
Main::


WaitVbl:           
    ; Wait for vertical blank to properly turn off display
    ldh a,[rLY] 
    cp $90
    jr nz,WaitVbl
.end


SetupStack:
    ld sp, Stack.end
.end

SetupIO:
    xor a
    ldh [rIF],a
    ldh [rLCDC],a
    ldh [rSTAT],a
    ldh [rSCX],a
    ldh [rSCY],a
    ldh [rLYC],a
.end

CopyDmaSubIntoHram:    
    ld c, $80      ; dma sub will be copied to _HRAM, at $FF80
    ld b, DmaSubCode.end - DmaSubCode
    ld hl, DmaSubCode
.copy
    ld a, [hli]
    ld [c], a
    inc c
    dec b
    jr nz,.copy 
.end

ZeroShadowOam:    
    ld hl, ShadowOam
    ld b, ShadowOam.end - ShadowOam
    xor a
.zero
    ld [hli], a
    dec b
    jr nz, .zero
.end    

CopyTilesIntoVram:
    ld hl, Tiles
    ld de, _VRAM + $0010
    ld bc, SIZEOF("Tiles")
    call memcpy
.end

ResetBG: 
    ld de, $9904
    ld bc, 13
    call memrst   
    ld de, $9922
    ld bc, 14
    call memrst
.end

SetupInterrupts:
    ld a, IEF_VBLANK
    ldh [rIE], a
.end

SetupLcd:
    ld a, LCDCF_ON | LCDCF_BG8000 | LCDCF_BG9800 | LCDCF_OBJ8 | LCDCF_OBJON | LCDCF_WINOFF | LCDCF_BGON
                    ; lcd setup: tiles at $8000, map at $9800, 8x8 sprites (disabled), no window, etc.
    ldh [rLCDC], a   ; enable lcd 
.end
    
SetupPalletes:
    ld a,%11101100
    ldh [rBGP],a
    ld a,%11010000
    ldh [rOBP0],a    
    ldh [rOBP1],a
.end

SetupMainState:
    xor a
    ld [CurrentFrameAsync], a
    ld hl, Joypad    
    REPT Joypad.end - Joypad
        ld [hli], a
    ENDR
.end
    
SetEventHandler:
    ld a, $c3               ; jp
    ldh [UpdateSub], a
    ON_UPDATE(MenuStage)
    ei
    nop
    jr Sleep
.end

GameLoop:
    ; Increase frame count
    ldh a, [CurrentFrameAsync]
    ldh [CurrentFrame], a

ReadInput:
    ; ldh a, [Joypad.enabled]
    ; cp a, 0
    ; jr nz, .end
.doRead    
    ; Read DPAD
    ld a, P1F_GET_DPAD        
    ldh [rP1], a
    REPT 4
        ldh a, [rP1]
    ENDR
    cpl
    and P1F_OUT
    swap a
    ld b, a
    ; Read Buttons
    ld a, P1F_GET_BTN
    ldh [rP1], a
    REPT 10
        ldh a, [rP1]
    ENDR
    cpl
    and P1F_OUT
    or b    ; Add DPAD
    ; Store state
    ld c, a
    ld a, [Joypad.state]
    xor c
    and c
    ldh [Joypad.press], a
    ld a, c
    ldh [Joypad.state], a
    ld a, P1F_GET_DPAD | P1F_GET_BTN
    ldh [rP1], a
.end
    
CallUpdateSub:
    jp UpdateSub
    
    ; Yield CPU until next frame
Sleep::
    halt
    nop ; halt bug
    ldh a, [rSTAT]
    and STATF_LCD
    cp STATF_VBL
    jr nz, Sleep    ; not awaked by VBlank
    jr GameLoop


SECTION "ShadowOam", WRAM0[_SHADOW_OAM]
ShadowOam::
    DS 160
.end

SECTION "Stack", WRAM0
Stack:
    DS 32
.end

SECTION "DmaSub", HRAM[$FF80]
DmaSub:
    DS DmaSubCode.end - DmaSubCode

; Jump to current frame update sub
; Routine should end with HALT
SECTION "UpdateSub", HRAM
UpdateSub::
    DS 1    ;   jp hi lo
.addrLow::
    DS 1
.addrHigh::
    DS 1

