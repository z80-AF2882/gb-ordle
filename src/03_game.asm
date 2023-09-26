INCLUDE "hardware.inc"
INCLUDE "debug.inc"
INCLUDE "word_list.inc"
INCLUDE "main.inc"
INCLUDE "game.inc"
INCLUDE "tiles.inc"

; Game state
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DEF GAMF_WORD_SELECTED  EQU %10000000   ; 0 => increment seed per frame
DEF GAMF_WORD_ANIMATION EQU %00000111   ; ???

; Commands
DEF CMDF_LEFT_UP        EQU 0 ;JOYF_LEFT
DEF CMDF_RIGHT_UP       EQU 1 ;JOYF_RIGHT

DEF CMDB_LEFT_UP        EQU 0 ;JOYB_LEFT
DEF CMDB_RIGHT_UP       EQU 1 ;JOYB_RIGHT

; Cursor state
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DEF CURF_SHRINKING      EQU %00001000      ; 0 => move cursor paddles to edges, 1 => move cursor paddles to field
DEF CURF_POSITION       EQU %00000111      ; 0..4
DEF CURF_POSITION_NEW   EQU %01110000      ; 0..4
DEF CURF_WIGGLE_DELAY   EQU %10000000      ; 

; Object indexes
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DEF OBJ_CURSOR_44       EQU 0
DEF OBJ_GUESS_44        EQU 4
DEF OBJ_SCROLL_44       EQU 8

; Object addresses
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Cursor
DEF ADDR_CURSOR      EQU _SHADOW_OAM + (OBJ_CURSOR_44 * sizeof_OAM_ATTRS)
DEF ADDR_CURSOR_TL   EQU ADDR_CURSOR + 0 * sizeof_OAM_ATTRS
DEF ADDR_CURSOR_BL   EQU ADDR_CURSOR + 1 * sizeof_OAM_ATTRS
DEF ADDR_CURSOR_TR   EQU ADDR_CURSOR + 2 * sizeof_OAM_ATTRS
DEF ADDR_CURSOR_BR   EQU ADDR_CURSOR + 3 * sizeof_OAM_ATTRS
; Active guess
DEF ADDR_GUESS       EQU _SHADOW_OAM + (OBJ_GUESS_44 * sizeof_OAM_ATTRS)
DEF ADDR_GUESS_TL    EQU ADDR_GUESS + 0 * sizeof_OAM_ATTRS
DEF ADDR_GUESS_BL    EQU ADDR_GUESS + 1 * sizeof_OAM_ATTRS
DEF ADDR_GUESS_TR    EQU ADDR_GUESS + 2 * sizeof_OAM_ATTRS
DEF ADDR_GUESS_BR    EQU ADDR_GUESS + 3 * sizeof_OAM_ATTRS
; Scroll in
DEF ADDR_SCROLL      EQU _SHADOW_OAM + (OBJ_SCROLL_44 * sizeof_OAM_ATTRS)
DEF ADDR_SCROLL_TL   EQU ADDR_SCROLL + 0 * sizeof_OAM_ATTRS
DEF ADDR_SCROLL_BL   EQU ADDR_SCROLL + 1 * sizeof_OAM_ATTRS
DEF ADDR_SCROLL_TR   EQU ADDR_SCROLL + 2 * sizeof_OAM_ATTRS
DEF ADDR_SCROLL_BR   EQU ADDR_SCROLL + 3 * sizeof_OAM_ATTRS


; Cursor positioning / movement
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DEF CURSOR_FIRST_ROW_Y  EQU 20
DEF CURSOR_FIRST_ROW_START_X EQU 24
DEF CURSOR_BOUNCE       EQU 5   ;   Number of px paddle wiggles left to right
DEF CURSOR_SPACE_WIDTH  EQU 24  ;   Number of px between left and right paddle
DEF CURSOR_FIELD_WIDTH  EQU 24  ;   Number of px between TL pixel of first field and second field 

SECTION "Game", ROM0
GameStage::

Init:
.variables
    ; reset current guess
    xor a
    ld hl, CurrentGuess
    ld [hli], a
    ld [hli], a
    ld [hli], a
    ld [hli], a
    ld [hl], a
    ; no need to 
    ldh [StageState], a
    ldh [CursorState], a    
    ldh [LastJoypad], a
    ldh [AnimationCounter], a
    call UpdateCursorWiggleXPosition    
.sprites
    ; top left
    ld a, CURSOR_FIRST_ROW_Y
    ld [ADDR_CURSOR_TL + OAMA_Y], a
    ld a, CURSOR_FIRST_ROW_START_X
    ld [ADDR_CURSOR_TL + OAMA_X], a
    ld a, T_PADDLE_TL
    ld [ADDR_CURSOR_TL + OAMA_TILEID], a
    xor a
    ld [ADDR_CURSOR_TL + OAMA_FLAGS], a
    ; bottom left
    ld a, CURSOR_FIRST_ROW_Y + TILE_SIZE
    ld [ADDR_CURSOR_BL + OAMA_Y], a
    ld a, CURSOR_FIRST_ROW_START_X
    ld [ADDR_CURSOR_BL + OAMA_X], a
    ld a, T_PADDLE_BL
    ld [ADDR_CURSOR_BL + OAMA_TILEID], a
    xor a
    ld [ADDR_CURSOR_BL + OAMA_FLAGS], a
    ; top right
    ld a, CURSOR_FIRST_ROW_Y
    ld [ADDR_CURSOR_TR + OAMA_Y], a
    ld a, CURSOR_FIRST_ROW_START_X + CURSOR_SPACE_WIDTH
    ld [ADDR_CURSOR_TR + OAMA_X], a
    ld a, T_PADDLE_TR
    ld [ADDR_CURSOR_TR + OAMA_TILEID], a
    xor a
    ld [ADDR_CURSOR_TR + OAMA_FLAGS], a
    ; bottom right
    ld a, CURSOR_FIRST_ROW_Y + TILE_SIZE
    ld [ADDR_CURSOR_BR + OAMA_Y], a
    ld a, CURSOR_FIRST_ROW_START_X + CURSOR_SPACE_WIDTH
    ld [ADDR_CURSOR_BR + OAMA_X], a
    ld a, T_PADDLE_BR
    ld [ADDR_CURSOR_BR + OAMA_TILEID], a
    xor a
    ld [ADDR_CURSOR_BR + OAMA_FLAGS], a
   

    call ForceUpdateGuess
    
    ON_UPDATE(GameLoop)
    jp Sleep
.end

GameLoop::

UpdateCommand:    
    ld d, 0             ; new command     
    rst 8
    ld b, a             ; pressed buttons
    ld c, a
    ldh a, [LastJoypad]        
    xor c
    jr z, .storeCommand
    ld c, a             ; button changes 
; .checkLeft
;     bit JOYB_LEFT, c
;     jr z, .checkRight
;     bit JOYB_LEFT, b
;     jr nz, .checkRight    
;     ld a, d
;     or CMDF_LEFT_UP
;     ld d, a
; .checkRight
;     bit JOYB_RIGHT, c
;     jr z, .storeCommand
;     bit JOYB_RIGHT, b
;     jr nz, .storeCommand    
;     ld a, d
;     or CMDF_RIGHT_UP
;     ld d, a
.storeCommand
    ld a, d
    ldh [Command], a    
    rst 8
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
    ld a, [ADDR_CURSOR_TR + OAMA_X]
    dec a
    ld [ADDR_CURSOR_TR + OAMA_X], a
    ld [ADDR_CURSOR_BR + OAMA_X], a
    
    ld a, [ADDR_CURSOR_TL + OAMA_X]
    inc a
    ld [ADDR_CURSOR_TL + OAMA_X], a
    ld [ADDR_CURSOR_BL + OAMA_X], a

    ld d, a
    ldh a, [CursorWiggleXPositionStart]
    cp d
    jr nz, .end
    ldh a, [CursorState]
    and ~CURF_SHRINKING
    ldh [CursorState], a
    jr .end
.expand    
    ld a, [ADDR_CURSOR_TR + OAMA_X]
    inc a
    ld [ADDR_CURSOR_TR + OAMA_X], a
    ld [ADDR_CURSOR_BR + OAMA_X], a
    
    ld a, [ADDR_CURSOR_TL + OAMA_X]
    dec a
    ld [ADDR_CURSOR_TL + OAMA_X], a
    ld [ADDR_CURSOR_BL + OAMA_X], a
    
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

ForceUpdateGuess:
    
UpdateGuess:
    ret
.end
    

    
SECTION UNION "Local HRAM Variables", HRAM
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
CursorScreenXPosition:
    DS 1
CurrentGuess:
    DS 5
Command:
    DS 1
