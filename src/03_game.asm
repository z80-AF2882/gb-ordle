INCLUDE "hardware.inc"
INCLUDE "debug.inc"
INCLUDE "word_list.inc"
INCLUDE "main.inc"
INCLUDE "game.inc"

; Game state
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DEF GAMF_WORD_SELECTED  EQU %10000000   ; 0 => increment seed per frame
DEF GAMF_WORD_ANIMATION EQU %00000111   ; ???

; Commands
DEF CMDF_LEFT_UP        EQU JOYF_LEFT
DEF CMDF_RIGHT_UP       EQU JOYF_RIGHT

DEF CMDB_LEFT_UP        EQU JOYB_LEFT
DEF CMDB_RIGHT_UP       EQU JOYB_RIGHT

; Cursor state
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DEF CURF_SHRINKING      EQU %00001000      ; 0 => move cursor paddles to edges, 1 => move cursor paddles to field
DEF CURF_POSITION       EQU %00000111      ; 0..4
DEF CURF_POSITION_NEW   EQU %01110000      ; 0..4

; Cursor GFX
DEF CURSOR_FIRST_OBJ    EQU 0
DEF CURSOR_FIRST_TILE   EQU 48
DEF CURSOR_FIRST_ADDR   EQU _SHADOW_OAM + (CURSOR_FIRST_OBJ * 4)
DEF CURSOR_TL_ADDR      EQU CURSOR_FIRST_ADDR + 0
DEF CURSOR_BL_ADDR      EQU CURSOR_FIRST_ADDR + 4
DEF CURSOR_TR_ADDR      EQU CURSOR_FIRST_ADDR + 8
DEF CURSOR_BR_ADDR      EQU CURSOR_FIRST_ADDR + 12
; Cursor positioning / movement
DEF CURSOR_FIRST_ROW_Y  EQU 20
DEF CURSOR_FIRST_ROW_START_X EQU 24
DEF CURSOR_BOUNCE       EQU 2   ;   Number of px paddle wiggles left to right
DEF CURSOR_SPACE_WIDTH  EQU 24  ;   Number of px between left and right paddle
DEF CURSOR_FIELD_WIDTH  EQU 24  ;   Number of px between TL pixel of first field and second field 

SECTION "Game", ROM0
GameStage::

Init:
.variables
    ; reset current guess
    xor a
    ld hl, CurrentGuess
    REPT 5
    ld [hli], a
    ENDR    
    ldh [StageState], a
    ldh [CursorState], a    
    ldh [LastJoypad], a
    ldh [AnimationCounter], a
    call UpdateCursorWiggleXPosition    
.sprites
    FOR N, 4
    IF N % 2 == 0
    ld a, CURSOR_FIRST_ROW_Y
    ELSE
    ld a, CURSOR_FIRST_ROW_Y + 8    
    ENDC
    ld [CURSOR_FIRST_ADDR + (N * sizeof_OAM_ATTRS) + OAMA_Y], a
    IF N < 2 
    ld a, CURSOR_FIRST_ROW_START_X
    ELSE
    ld a, CURSOR_FIRST_ROW_START_X + CURSOR_SPACE_WIDTH
    ENDC
    ld [CURSOR_FIRST_ADDR + (N * sizeof_OAM_ATTRS) + OAMA_X], a
    ld a, CURSOR_FIRST_TILE + N    
    ld [CURSOR_FIRST_ADDR + (N * sizeof_OAM_ATTRS) + OAMA_TILEID], a
    xor a
    ld [CURSOR_FIRST_ADDR + (N * sizeof_OAM_ATTRS) + OAMA_FLAGS], a
    ENDR

    ON_UPDATE(GameLoop)
    jp Sleep
.end

GameLoop::

UpdateCommand:    
    ld d, 0             ; new command     
    ldh a, [Joypad]
    ld b, a             ; pressed buttons
    ld c, a
    ldh a, [LastJoypad]        
    xor c
    jr z, .storeCommand
    ld c, a             ; button changes 
.checkLeft
    bit JOYB_LEFT, c
    jr z, .checkRight
    bit JOYB_LEFT, b
    jr nz, .checkRight    
    ld a, d
    or CMDF_LEFT_UP
    ld d, a
.checkRight
    bit JOYB_RIGHT, c
    jr z, .storeCommand
    bit JOYB_RIGHT, b
    jr nz, .storeCommand    
    ld a, d
    or CMDF_RIGHT_UP
    ld d, a
.storeCommand
    ld a, d
    ldh [Command], a    
    ldh a, [Joypad]
    ldh [LastJoypad], a
    ; ASSERT d == Command
.end

ProcessCommand:
    ; ASSERT d == Command
.checkMoveLeft
    bit CMDB_LEFT_UP, d
    jr z, .checkMoveRight
.moveLeft    
    ldh a, [CursorState]
    ld b, a
    swap a
    and CURF_POSITION
    jr nz, .checkMoveRight  ; already moving, skip
    ld a, b
    and CURF_POSITION       ; left most position, skip
    jr z, .checkMoveRight   
    dec a    
    jr .startCursorAnimation
.checkMoveRight
    bit CMDB_RIGHT_UP, d
    jr z, .contTODO
.moveRight
    ldh a, [CursorState]
    ld b, a
    swap a
    and CURF_POSITION
    jr nz, .contTODO        ; already moving, skip
    ld a, b
    and CURF_POSITION
    cp 5                    ; right most position, skip
    jr z, .contTODO   
    inc a
.startCursorAnimation    
    ld c, a
    ld a, b                 ; old cursor state
    and ~(CURF_POSITION|CURF_POSITION_NEW)  ; reset position bits
    or c                    ; set position and position new
    swap a 
    or c
    swap a                  ; keep flags on original positon (swap x2)
    ldh [CursorState], a
.contTODO
.end


IncrementSeed:
    ldh a, [StageState]
    and GAMF_WORD_SELECTED
    call z, IncSeed
.end

CursorMoveAnimation:
.end

CursorWiggleAnimation:
    ldh a, [CursorState]
    and CURF_SHRINKING
    jr z, .expand
.shrink
    ld a, [CURSOR_TR_ADDR + OAMA_X]
    dec a
    ld [CURSOR_TR_ADDR + OAMA_X], a
    ld [CURSOR_BR_ADDR + OAMA_X], a
    
    ld a, [CURSOR_TL_ADDR + OAMA_X]
    inc a
    ld [CURSOR_TL_ADDR + OAMA_X], a
    ld [CURSOR_BL_ADDR + OAMA_X], a

    ld d, a
    ldh a, [CursorWiggleXPositionStart]
    cp d
    jr nz, .end
    ldh a, [CursorState]
    and ~CURF_SHRINKING
    ldh [CursorState], a
    jr .end
.expand    
    ld a, [CURSOR_TR_ADDR + OAMA_X]
    inc a
    ld [CURSOR_TR_ADDR + OAMA_X], a
    ld [CURSOR_BR_ADDR + OAMA_X], a
    
    ld a, [CURSOR_TL_ADDR + OAMA_X]
    dec a
    ld [CURSOR_TL_ADDR + OAMA_X], a
    ld [CURSOR_BL_ADDR + OAMA_X], a
    
    ld d, a
    ldh a, [CursorWiggleXPositionEnd]
    cp d
    jr nz, .end
    ldh a, [CursorState]
    or CURF_SHRINKING    
    ldh [CursorState], a
.end


GameLoopFinish:
    
    jp Sleep
.end

UpdateCursorWiggleXPosition:
    ; Update CursorXPosition variable from game state
    ld a, [CursorState]
    and CURF_POSITION   
    ld c, a
    ld b, CURSOR_FIRST_ROW_START_X
.loop
    cp 0
    jr z, .update
    ld a, b
    add CURSOR_FIELD_WIDTH
    ld b, a
    dec c
    jr .loop
.update
    ld a, b
    ldh [CursorWiggleXPositionStart], a
    ld d, CURSOR_BOUNCE
    sub d
    ldh [CursorWiggleXPositionEnd], a
    ret
.end

    
SECTION "Game Variables", HRAM  
AnimationCounter:
    DS 1
LastJoypad:
    DS 1
StageState:
    DS 1
CursorState:
    DS 1    
CursorWiggleXPositionStart:
    DS 1
CursorWiggleXPositionEnd:
    DS 1
CurrentGuess:
    DS 5
Command:
    DS 1
