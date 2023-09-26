INCLUDE "hardware.inc"
INCLUDE "main.inc"
INCLUDE "tiles.inc"

DEF BoardStart      EQU $9803

DEF EmptySpaceTile  EQU T_BORDER_TL

DEF DrawBoardDelay  EQU 20      ; number of frames to wait before drawing next board row

DEF LettersPerRow   EQU 5

SECTION "Start", ROM0
StartStage::
;
ScrollToPlayfield:
    ; TODO remove magic 
    ld d, 3
    ld a, -4
    ld bc, 4
    ld hl, ShadowOam
.loop
    dec [hl]
    dec [hl]
    add hl, bc
    dec d
    jr nz, .loop
    ld hl, ShadowOam
    ld hl, rSCY
    inc [hl]
    cp [hl]
    jp z, .done
    inc [hl]
    cp [hl]
    jp nz, Sleep
.done    
    ON_UPDATE(DrawBoardInit)
    jp Sleep
.end
;
DrawBoardInit:    
    ld hl, BoardStart
    push hl
    ON_UPDATE(DrawBoard)
    jp Sleep
        
DrawBoard:
    pop hl
    ld de, 17
    ld c, LettersPerRow
.drawTopRow
    ld a, T_BORDER_TL
    ld [hli], a    
    ld a, T_BORDER_TR
    ld [hli], a
    inc hl
    dec c
    jr nz, .drawTopRow
    add hl, de    
    ld c, LettersPerRow
.drawBotRow
    ld a, T_BORDER_BL
    ld [hli], a
    ld a, T_BORDER_BR
    ld [hli], a
    inc hl
    dec c
    jr nz, .drawBotRow
    add hl, de
    add hl, de
    add hl, de
    dec hl
    dec hl
    push hl
    ld a, $9a
    cp h
    jr nz, StartDelayDrawBoard
    ld a, $a3       ; hl==$9aa3 => last box drawn
    jr nz, StartDelayDrawBoard
    ON_UPDATE(GameStage)    
    jp Sleep

StartDelayDrawBoard:
    ldh a, [Joypad]
    and JOYF_START
    ld a, DrawBoardDelay
    jr z, .setDelay
    rra
.setDelay    
    ldh [AnimationCounter], a
    ON_UPDATE(DelayDrawBoard)
    ; continue
DelayDrawBoard:
    ldh a, [AnimationCounter]
    dec a
    ldh [AnimationCounter], a
    jp nz, Sleep
    ON_UPDATE(DrawBoard)
    jp Sleep

SECTION UNION "Local HRAM Variables", HRAM
AnimationCounter:
    DS 1