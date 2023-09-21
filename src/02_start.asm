INCLUDE "hardware.inc"
INCLUDE "main.inc"

DEF BoardStart      EQU $9803
DEF EmptySpaceTile  EQU 44      ; index of blank field (no letter selected)

DEF DrawBoardDelay  EQU 20      ; number of frames to wait before drawing next board row

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
    ld a, EmptySpaceTile
    ld c,5
.drawTopRow
    ld [hli], a
    inc a
    ld [hli], a
    dec a
    inc hl
    dec c
    jr nz, .drawTopRow
    add hl, de    
    ld a, EmptySpaceTile + 2
    ld c,5
.drawBotRow
    ld [hli], a
    inc a
    ld [hli], a
    dec a
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
    ld a, DrawBoardDelay
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

SECTION "Start Variables", HRAM
AnimationCounter:
    DS 1