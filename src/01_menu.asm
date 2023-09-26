INCLUDE "hardware.inc"
INCLUDE "debug.inc"
INCLUDE "main.inc"
INCLUDE "tiles.inc"
INCLUDE "charmap.inc"

PressStartTextAddress EQU $9a44

SECTION "Menu", ROM0
MenuStage::
    ; ;;;;;;;;;;;;
    ; ld a, LOW(Console)    
    ; ld [Index], a
    ; ld a, HIGH(Console)
    ; ld [Index + 1], a
    ; ;;;;;;;;;;;;

    ld hl, ShadowOam
    ld b, T_START_UP
    ld c, 3
    ld d, 161
    ld e, 77
.loop
    ld a, d
    ld [hli], a
    ld a, 8
    add e
    ld e, a
    ld [hli], a
    ld a, b
    inc b
    ld [hli], a
    xor a    
    ld [hli], a
    dec c
    jr nz, .loop


    ld hl, PressStart
    ld bc, PressStart.end - PressStart
    ld de, PressStartTextAddress
    call memcpy
    ld a, 80
    ldh [Step], a  

    ON_UPDATE(ScrollUp)
    jp Sleep
.end

ScrollUp:
    ; scroll bg
    ld hl, rSCY
    inc [hl]
    ; scroll sprites
    ld bc, 4
    ld hl, ShadowOam
    dec [hl]
    add hl, bc
    dec [hl]
    add hl, bc
    dec [hl]
    add hl, bc
    ; 
    ld hl, Step
    dec [hl]
    jr nz, WaitForButtonPress    
    ON_UPDATE(WaitForButtonPress)
    jp Sleep
.end
    

WaitForButtonPress:    
    rst 8
    and JOYF_START
    jr z, .switchTile
    ON_UPDATE(StartStage)
    jp Sleep
.switchTile
    ld a, [CurrentFrame]
    bit 5, a
    ld a, T_START_UP
    jr nz, .otherTile
    add a, 3    
.otherTile
    ld hl, ShadowOam + 2
    ld [hli], a
    inc hl
    inc hl
    inc hl
    inc a
    ld [hli], a
    inc hl
    inc hl
    inc hl
    inc a
    ld [hli], a
    call IncSeed
    jp  Sleep
.end
    
SECTION "Menu Constands", ROM0
PressStart:
    DB "press     ..."    
.end    

SECTION UNION "Local HRAM Variables", HRAM
Step:
    DS 1
; Index:
;     DS 2
