SECTION "memrst", ROM0

memrst:: ; bc = size, de = destination

    ; This function implements Duff's Device. For more information, check:
    ;
    ;     https://en.wikipedia.org/wiki/Duff%27s_device

    ; A = C & 7 = Extra bytes to copy

    ld      a, c
    and     a, 7

    ; BC = BC >> 3 = Blocks of 8 bytes to copy

    REPT 3
    srl     b
    rr      c
    ENDR

    ; If this isn't done, bc = 0 is treated as 0xFFFF because the registers are
    ; decremented before checking the value.

    inc     b
    inc     c

    ; Jump table

    and     a, a
    jr      z, copy0 ; A = 0
    dec     a
    jr      z, copy1 ; A = 1
    dec     a
    jr      z, copy2 ; A = 2
    dec     a
    jr      z, copy3 ; A = 3
    dec     a
    jr      z, copy4 ; A = 4
    dec     a
    jr      z, copy5 ; A = 5
    dec     a
    jr      z, copy6 ; A = 6
    jr      copy7 ; At this point, A = 7

copy8:
    xor a
    ld      [de], a
    inc     de
copy7:
    xor a
    ld      [de], a
    inc     de
copy6:
    xor a
    ld      [de], a
    inc     de
copy5:
    xor a
    ld      [de], a
    inc     de
copy4:
    xor a
    ld      [de], a
    inc     de
copy3:
    xor a
    ld      [de], a
    inc     de
copy2:
    xor a
    ld      [de], a
    inc     de
copy1:
    xor a
    ld      [de], a
    inc     de
copy0:
    dec     c
    jr      nz, copy8
    dec     b
    jr      nz, copy8

    ret