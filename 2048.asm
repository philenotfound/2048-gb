INCLUDE "gbtoz80.asm"
INCLUDE "constants.asm"

; rst vectors go unused
SECTION "rst00",HOME[0]
    im 1
    jp StartSMS
    ret

SECTION "rst08",HOME[8]
    ret

SECTION "rst10",HOME[$10]
    ret

SECTION "rst18",HOME[$18]
    ret

SECTION "rst20",HOME[$20]
    ret

SECTION "rst30",HOME[$30]
    ret

SECTION "smsint",HOME[$38]
    jp VBlankSMS

SECTION "vblank",HOME[$40]
	jp VBlankHandler
SECTION "lcdc",HOME[$48]
	reti
SECTION "timer",HOME[$50]
	reti
SECTION "serial",HOME[$58]
	reti
SECTION "joypad",HOME[$60]
	reti
SECTION "smspause",HOME[$66]
    retn

SECTION "bank0",HOME[$68]

SECTION "romheader",HOME[$100]
    nop
    jp Start

Section "start",HOME[$150]


StartSMS:
    ld sp, $cff0

    ld hl,VdpData
    ld b,VdpDataEnd-VdpData
    ld c,VDPControl
    otir

    ld hl,$0000 | VRAMWrite
    call SetVDPAddress
    ; 2. Output 16KB of zeroes
    ld bc, $4000    ; Counter for 16KB of VRAM
ClearVRAMLoop:
    ld a,$00    ; Value to write
    out [VDPData],a ; Output to VRAM address, which is auto-incremented after each write
    dec bc
    ld a,b
    or c
    jp nz,ClearVRAMLoop

    ld hl,$0000 | CRAMWrite
    call SetVDPAddress
    ; 2. Output colour data
    ld hl,PaletteData
    ld b,(PaletteDataEnd-PaletteData)
    ld c,VDPData
    otir

    ld hl,$0000 | VRAMWrite
    call SetVDPAddress
    ; 2. Output tile data
    ld hl,Title              ; Location of tile data
    ld bc,$2600  ; Counter for number of bytes to write
.loop
    ; Output data byte then three zeroes, because our tile data is 1 bit
    ; and must be increased to 4 bit
    ld a,[hl]        ; Get data byte
    out [VDPData],a
    ;out [VDPData],a
    inc hl           ; Add one to hl so it points to the next data byte
    dec bc
    ld a,b
    or c
    jr nz,.loop


    ; Turn screen on
    ld a,%11100000
;          |||| |`- Zoomed sprites -> 16x16 pixels
;          |||| `-- Doubled sprites -> 2 tiles per sprite, 8x16
;          |||`---- 30 row/240 line mode
;          ||`----- 28 row/224 line mode
;          |`------ VBlank interrupts
;          `------- Enable display
    out [VDPControl],a
    ld a,$81
    out [VDPControl],a
    ei

    jp Start_


SetVDPAddress:
; Sets the VDP address
; Parameters: hl = address
    push af
    ld a,l
    out [VDPControl],a
    ld a,h
    out [VDPControl],a
    pop af
    ret


PaletteData:
    RGBSMS 3, 3, 3
    RGBSMS 2, 2, 3
    RGBSMS 0, 0, 1
    RGBSMS 0, 0, 0
    RGBSMS 0, 1, 0
    RGBSMS 0, 2, 0
    RGBSMS 0, 3, 0
    RGBSMS 0, 3, 0
rept 3*8
    RGBSMS 2, 2, 3
endr
    
PaletteDataEnd

PaletteDataIngame:
    RGBSMS 3, 3, 3
    RGBSMS 2, 2, 3
    RGBSMS 3, 3, 0
    RGBSMS 3, 2, 0
    RGBSMS 1, 1, 0
    RGBSMS 0, 0, 0
    RGBSMS 3, 3, 3
    RGBSMS 3, 3, 3
    
    RGBSMS 3, 3, 3
    RGBSMS 3, 3, 3
    RGBSMS 3, 3, 0
    RGBSMS 3, 2, 0
    RGBSMS 1, 1, 0
    RGBSMS 0, 0, 0
    RGBSMS 3, 3, 3
    RGBSMS 3, 3, 3
    
    RGBSMS 3, 3, 3
    RGBSMS 3, 3, 3
    RGBSMS 3, 3, 0
    RGBSMS 3, 2, 0
    RGBSMS 1, 1, 0
    RGBSMS 0, 0, 0
    RGBSMS 3, 3, 3
    RGBSMS 3, 3, 3
    
    RGBSMS 3, 3, 3
    RGBSMS 3, 3, 3
    RGBSMS 3, 3, 0
    RGBSMS 3, 2, 0
    RGBSMS 1, 1, 0
    RGBSMS 0, 0, 0
    RGBSMS 3, 3, 3
    RGBSMS 3, 3, 3
PaletteDataIngameEnd:


PaletteDataFadeout:
    RGBSMS 3, 3, 3
    RGBSMS 2, 2, 3
    RGBSMS 3, 3, 0
    RGBSMS 3, 2, 0
    RGBSMS 1, 1, 0
    RGBSMS 0, 0, 0
    RGBSMS 3, 3, 3
    RGBSMS 3, 3, 3
PaletteDataFadeoutEnd

; VDP initialisation data
VdpData:
    db $04,$80,$00,$81,$ff,$82,$ff,$85,$ff,$86,$ff,$87,$00,$88,$00,$89,$ff,$8a
VdpDataEnd:

VBlankCopyOAMSMS:
    ld hl,$3f00 | VRAMWrite
    call SetVDPAddress
    ld hl, W_OAM
    ld b, $28
.yloop
    ld a,[hl]
    out [VDPData],a
    inc hl
    inc hl
    inc hl
    inc hl
    dec b
    jr nz, .yloop
    
    ld hl,$3f80 | VRAMWrite
    call SetVDPAddress
    ld hl, $c301
    ld b, $28
.xnloop
    ld a,[hl]
    add $28
    out [VDPData],a
    inc hl
    ld a,[hl]
    out [VDPData],a
    inc hl
    inc hl
    inc hl
    dec b
    jr nz, .xnloop
    
    ret

VBlankSMS:
    push af
    in a, [VPDStatus]
    ld a, [H_TURNOFF]
    and a
    jr z, .on
    ld a,%00100010
;          |||| |`- Zoomed sprites -> 16x16 pixels
;          |||| `-- Doubled sprites -> 2 tiles per sprite, 8x16
;          |||`---- 30 row/240 line mode
;          ||`----- 28 row/224 line mode
;          |`------ VBlank interrupts
;          `------- Enable display
    out [VDPControl],a
    push hl
    pop hl
    push hl
    pop hl
    ld a,$81
    out [VDPControl],a
    xor a
    ld [H_TURNOFF], a
    pop af
    ret
.on
    push bc
    push de
    push hl
    call CopyTilemapSMS
    call VBlankCopyOAMSMS
    call ReadJoypadSMS
    ld hl, H_TIMER
    inc [hl]
    ld a, r
    ld b, a
    call GetRNG
    pop hl
    pop de
    pop bc
    pop af
    ei
    ret

CopyTilemapSMS:
    ld hl,$3800 | VRAMWrite
    call SetVDPAddress
    ld hl, W_TILEMAP
    ld b, 23
.loop
rept 32
    ld a,[hl]    ; Get data byte
    out [VDPData],a
    xor a
    out [VDPData],a
    inc hl
endr
    dec b
    jp nz,.loop
    ret

ReadJoypadSMS:
	ld a, [H_JOY]
	ld [H_JOYOLD], a
    ; SMS:  x x 2 1 r l d u
    ; GB:   d u l r S s B A
    in a, [$dc]
    xor a, $ff
    ;ld [$c000], a
    ;swap
    rrc a
    rrc a
    rrc a
    rrc a
    ; SMS:  r l d u x x 2 1
    ld b, a
    and %00001111
    bit 4, b ; u
    jr z, .no_u
    set 6, a
.no_u
    bit 5, b
    jr z, .no_d
    set 7, a
.no_d
    bit 6, b
    jr z, .no_l
    set 5, a
.no_l 
    bit 7, b
    jr z, .no_r
    set 4, a
.no_r
	ld [H_JOY],a ; save joypad state
	
	ld a, [H_JOY]
	ld b, a
	ld a, [H_JOYOLD]
	xor $ff
	and b
	ld [H_JOYNEW], a
	ret
    

; gb:

VBlankHandler:
    push af
    push bc
    push de
    push hl
    ld a, [H_FAST_VCOPY]
    and a
    jr z, .regular
    call FastVblank
    jr .copied
.regular
    call CopyTilemap
.copied
    call $FF80
    call ReadJoypadRegister
    ld hl, H_TIMER
    inc [hl]
    call GetRNG
    pop hl
    pop de
    pop bc
    pop af
    reti

CopyTilemap: ; We can copy just 8 lines per vblank.
; Contains an unrolled loop for speed.
    ;ld de, $9800
    ;ld hl, W_TILEMAP
    ld hl, H_VCOPY_D
    ld a, [hli]
    ld d, a
    ld a, [hli]
    ld e, a
    ld a, [hli]
    ld c, a
    ld a, [hl]
    ld l, a
    ld h, c
    ld a, [H_VCOPY_ROWS]
    ld c, a
.row

    dec c
    jr z, .done

    ld a, [hli]
    ld [de], a
    inc de
    ld a, [hli]
    ld [de], a
    inc de
    ld a, [hli]
    ld [de], a
    inc de
    ld a, [hli]
    ld [de], a
    inc de
    ld a, [hli]
    ld [de], a
    inc de
    ld a, [hli]
    ld [de], a
    inc de
    ld a, [hli]
    ld [de], a
    inc de
    ld a, [hli]
    ld [de], a
    inc de
    ld a, [hli]
    ld [de], a
    inc de
    ld a, [hli]
    ld [de], a
    inc de
    ld a, [hli]
    ld [de], a
    inc de
    ld a, [hli]
    ld [de], a
    inc de
    ld a, [hli]
    ld [de], a
    inc de
    ld a, [hli]
    ld [de], a
    inc de
    ld a, [hli]
    ld [de], a
    inc de
    ld a, [hli]
    ld [de], a
    inc de
    ld a, [hli]
    ld [de], a
    inc de
    ld a, [hli]
    ld [de], a
    inc de
    ld a, [hli]
    ld [de], a
    inc de
    ld a, [hli]
    ld [de], a
    inc de
    
    ld a, e
    add $c
    ld e, a
    jr nc, .row
;carry
    inc d
    jr .row
.done
    ld a, [H_VCOPY_TIMES]
    inc a
    ld [H_VCOPY_TIMES], a
    cp a, $03
    jr z, .reset
    cp a, $02
    jr nz, .eightrows
    ; only 5 rows left
    ld a, $5
    ld [H_VCOPY_ROWS], a

.eightrows
    ld a, d
    ld [H_VCOPY_D], a
    ld a, e
    ld [H_VCOPY_E], a
    ld a, h
    ld [H_VCOPY_H], a
    ld a, l
    ld [H_VCOPY_L], a
    ret
.reset
    ld a, $98
    ld [H_VCOPY_D], a
    xor a
    ld [H_VCOPY_E], a
    ld a, $C0
    ld [H_VCOPY_H], a
    xor a
    ld [H_VCOPY_L], a
    ld [H_VCOPY_TIMES], a
    ld a, $8
    ld [H_VCOPY_ROWS], a
    ret

FastVblank:
    ;ld [W_SPTMP], sp
;    ld a, [H_FAST_PART]
;    and a
;    jr nz, .bottom
;.top
    ld sp, W_TILEMAP+22
    ld hl, $9800 + $22
;    jr .set
;.bottom
;    ld sp, W_TILEMAP+82
;    ld hl, $9800 + $82
;.set
    ld b, 6
.loop
rept 2
    popdetohli 8
    ld de, $10
    add hl, de
    add sp, $4
endr
    dec b
    jr nz, .loop
; squeeze in one last row
    popdetohli 8
    ld de, $10
    add hl, de
    add sp, $4
;...and a bit
    popdetohli 2
; and now wait patiently for blank
    waithblank
    ; go!
    popdetohli 6
    ld de, $10
    add hl, de
    add sp, $4
    
    waithblank
    popdetohli 6
    
    waithblank
    popdetohli 2
    ld de, $10
    add hl, de
    add sp, $4
    popdetohli 4
    waithblank
    popdetohli 4
    
    ld a, [W_SPTMP]
    ld l, a
    ld a, [W_SPTMP+1]
    ld h, a
    ld sp, hl
    ret

DisableLCD: ; $0061
	ld a, 1
	ld [H_TURNOFF], a
	halt
	ret

EnableLCD:
    ld a,%11100010
;          |||| |`- Zoomed sprites -> 16x16 pixels
;          |||| `-- Doubled sprites -> 2 tiles per sprite, 8x16
;          |||`---- 30 row/240 line mode
;          ||`----- 28 row/224 line mode
;          |`------ VBlank interrupts
;          `------- Enable display
    out [VDPControl],a
    ld a,$81
    out [VDPControl],a
	ret

FadeToWhite:
    ret
    lda [rBGP], %11100100
    halt
    halt
    halt
    halt
FateToWhite_:
    ret
    lda [rBGP], %10100100
    halt
    halt
    halt
    halt
    lda [rBGP], %01010100
    halt
    halt
    halt
    halt
    lda [rBGP], %00000000
    halt
    halt
    halt
    halt
    ret
FadeFromWhite:
    ret
    lda [rBGP], %00000000
    halt
    halt
    halt
    halt
    lda [rBGP], %01010100
    halt
    halt
    halt
    halt
    lda [rBGP], %10100100
    halt
    halt
    halt
    halt
    lda [rBGP], %11100100
    halt
    halt
    halt
    halt
    ret
    
CopyData:
; copy bc bytes of data from hl to de
	ld a,[hli]
	ld [de],a
	inc de
	dec bc
	ld a,c
	or b
	jr nz,CopyData
	ret

CopyDataFF:
; copy data from hl to de ending with $ff (inclusive)
	ld a,[hli]
	ld [de],a
	inc de
	inc a
	ret z
	jr CopyDataFF

WriteDataInc:
; write data in hl increasing a until b.
.loop
    ld [hli], a
    inc a
    cp a, b
    jr nz, .loop
    ret

FillMemory:
; write a in hl b times
.loop
    ld [hli], a
    dec b
    jr nz, .loop
    ret

ModuloC: ; modulo c
.loop
    cp a, c
    ret c
    sub a, c
    jr .loop

WriteSpriteRow:
    ; a = tile id
    ; b = amount
    ; de = xy
    ; hl = target
.loop
    ld [hl], d
    inc hl
    ld [hl], e
    ld c, a
    ld a, e
    add 8
    ld e, a
    ld a, c
    inc hl
    ld [hli], a
    inc a
    inc a
    ld [hl], 0
    inc hl
    dec b
    jr nz, .loop
    ret

ClearOAM:
    xor a
    ld hl, W_OAM
    ld b, 4*$28
    call FillMemory
    ret
    
ClearTilemap:
    ld hl, W_TILEMAP
    ld bc, 32*24
.loop
    xor a
    ld [hli], a
    dec bc
    ld a, b
    or c
    jr nz, .loop
    ret

; a standard function:
; this function directly reads the joypad I/O register
; it reads many times in order to give the joypad a chance to stabilize
; it saves a result in [H_JOY] in the following format
; (set bit indicates pressed button)
; bit 0 - A button
; bit 1 - B button
; bit 2 - Select button
; bit 3 - Start button
; bit 4 - Right
; bit 5 - Left
; bit 6 - Up
; bit 7 - Down
ReadJoypadRegister: ; 15F
    ld a, [H_JOY]
    ld [H_JOYOLD], a
	ld a,%00100000 ; select direction keys
	ld c,$00
	ld [rJOYP],a
	ld a,[rJOYP]
	ld a,[rJOYP]
	ld a,[rJOYP]
	ld a,[rJOYP]
	ld a,[rJOYP]
	ld a,[rJOYP]
	cpl ; complement the result so that a set bit indicates a pressed key
	and a,%00001111
	swap a ; put direction keys in upper nibble
	ld b,a
	ld a,%00010000 ; select button keys
	ld [rJOYP],a
	ld a,[rJOYP]
	ld a,[rJOYP]
	ld a,[rJOYP]
	ld a,[rJOYP]
	ld a,[rJOYP]
	ld a,[rJOYP]
	ld a,[rJOYP]
	ld a,[rJOYP]
	ld a,[rJOYP]
	ld a,[rJOYP]
	cpl ; complement the result so that a set bit indicates a pressed key
	and a,%00001111
	or b ; put button keys in lower nibble
	ld [$fff8],a ; save joypad state
	ld a,%00110000 ; unselect all keys
	ld [rJOYP],a
	
	ld a, [H_JOY]
	ld b, a
	ld a, [H_JOYOLD]
	xor $ff
	and b
	ld [H_JOYNEW], a
	ret

GetRNG:
    ld a, r
    ld b, a
    ld a, [H_RNG1]
    xor b
    ld [H_RNG1], a
    ret

WaitForKey:
.loop
    halt
    ld a, [H_JOYNEW]
    and a, %00001001 ; A or START
    jr z, .loop
    ret

; copies DMA routine to HRAM. By GB specifications, all DMA needs to be done in HRAM (no other memory section is available during DMA)
WriteDMACodeToHRAM:
	ld c, $80
	ld b, $a
	ld hl, DMARoutine
.copyLoop
	ld a, [hli]
	;ld [$ff00+c], a
	inc c
	dec b
	jr nz, .copyLoop
	ret

; this routine is copied to HRAM and executed there on every VBlank
DMARoutine:
	ld a, W_OAM >> 8
	;ld [$ff00+$46], a   ; start DMA
	ld a, $28
.waitLoop               ; wait for DMA to finish
	dec a
	jr nz, .waitLoop
	ret

Start:
    di
    
    ; palettes
    ld a, %11100100
    ld [rBGP], a
    ld a, %11010000
    ld [rOBP0], a
    
    ld a, 0
    ld [rSCX], a
    ld [rSCY], a
    
    ld a, %11000111
    ld [rLCDC], a
    
    ei
    
    call DisableLCD
    
    ; seed the RNG
    ld hl, $C000
    ld l, [hl]
    ld a, [hl]
    push af
    
    ; fill the memory with zeroes
    ld hl, $C000
.loop
    ld a, 0
    ld [hli], a
    ld a, h
    cp $e0
    jr nz, .loop
    
    pop af
    ; set up the stack pointer
    ld sp, $dffe
    push af

    ld hl, $ff80
.loop2
    ld a, 0
    ld [hli], a
    ld a, h
    cp $00
    jr nz, .loop2
    
    pop af
    ld [H_RNG1], a
    
    call WriteDMACodeToHRAM
    
    ; set up vblank copy offsets
    ld a, $98
    ld [H_VCOPY_D], a
    ld a, $C0
    ld [H_VCOPY_H], a
    ld a, $8
    ld [H_VCOPY_ROWS], a
    
Start_:
    
    ; set up ingame graphics
    ;ld hl, Title
    ;ld de, $9000
    ;ld bc, $800
    ;call CopyData
    ;ld hl, Title+$800
    ;ld de, $8800
    ;ld bc, $100
    ;call CopyData
    
    ld hl, TitleTilemap
    ld de, W_TILEMAP
    ld bc, TitleTilemapEnd-TitleTilemap
    call CopyData
        
    call EnableLCD
    xor a
    ld [$ffff], a
    ld a, %00000001
    ld [$ffff], a
    ei
    
    call WaitForKey
    
    call FadeToWhite
    call ClearTilemap
    call DisableLCD
    ; set up ingame graphics
    ld hl,$0000 | VRAMWrite
    call SetVDPAddress
    ; 2. Output tile data
    ld hl,Tiles              ; Location of tile data
    ld bc,$2000  ; Counter for number of bytes to write
.loop
    ; Output data byte then three zeroes, because our tile data is 1 bit
    ; and must be increased to 4 bit
    ld a,[hl]        ; Get data byte
    out [VDPData],a
    ;out [VDPData],a
    inc hl           ; Add one to hl so it points to the next data byte
    dec bc
    ld a,b
    or c
    jr nz, .loop
    
    ld hl,$2000 | VRAMWrite
    call SetVDPAddress
    ; 2. Output tile data
    ld hl,Sprites              ; Location of tile data
    ld bc,$1000  ; Counter for number of bytes to write
.loop2
    ; Output data byte then three zeroes, because our tile data is 1 bit
    ; and must be increased to 4 bit
    ld a,[hl]        ; Get data byte
    out [VDPData],a
    ;out [VDPData],a
    inc hl           ; Add one to hl so it points to the next data byte
    dec bc
    ld a,b
    or c
    jr nz, .loop2
    

    ld hl,$0000 | CRAMWrite
    call SetVDPAddress
    ; 2. Output colour data
    ld hl,PaletteDataIngame
    ld b,(PaletteDataIngameEnd-PaletteDataIngame)
    ld c,VDPData
    otir
    
;    ld hl,$0000 | VRAMWrite
;    call SetVDPAddress
;    ld bc, $0400
;.hiloop
;    ld a, 1
;    out [VDPData],a
;    xor a
;    out [VDPData],a
;    dec bc
;    jr nz, .hiloop
    
    ld a, 1
    ld [H_FAST_VCOPY], a
    call EnableLCD
    jp InitGame

TitleTilemap:
    db 0,0,0,0,0,0,$00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00,0,0,0,0,0,0
    db 0,0,0,0,0,0,$00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00,0,0,0,0,0,0
    db 0,0,0,0,0,0,$0f, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $90, $91, $92, $93, $94,$95,0,0,0,0,0
    db 0,0,0,0,0,0,$10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $1a, $1b, $1c, $1d, $1e, $a0, $a1, $a2, $a3, $a4,$a5,0,0,0,0,0
    db 0,0,0,0,0,0,$20, $21, $22, $23, $24, $25, $26, $27, $28, $29, $2a, $2b, $2c, $2d, $2e, $b0, $b1, $b2, $b3, $b4,$b5,0,0,0,0,0
    db 0,0,0,0,0,0,$30, $31, $32, $33, $34, $35, $36, $37, $38, $39, $3a, $3b, $3c, $3d, $3e, $c0, $c1, $c2, $c3, $c4,$c5,0,0,0,0,0
    db 0,0,0,0,0,0,$00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00,0,0,0,0,0,0
    db 0,0,0,0,0,0,$00, $00, $40, $41, $42, $43, $44, $45, $46, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00,0,0,0,0,0,0
    db 0,0,0,0,0,0,$00, $00, $00, $00, $47, $48, $49, $4a, $4b, $4c, $4d, $4e, $4f, $50, $51, $52, $53, $54, $00, $00,0,0,0,0,0,0
    db 0,0,0,0,0,0,$00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00,0,0,0,0,0,0
    db 0,0,0,0,0,0,$00, $00, $55, $56, $57, $58, $89, $8a, $8b, $8c, $8d, $59, $5a, $5b, $5c, $5d, $86, $87, $88, $00,0,0,0,0,0,0
    db 0,0,0,0,0,0,$00, $00, $00, $00, $5e, $5f, $60, $61, $62, $63, $64, $65, $66, $67, $68, $00, $00, $00, $00, $00,0,0,0,0,0,0
    db 0,0,0,0,0,0,$00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00,0,0,0,0,0,0
    db 0,0,0,0,0,0,$00, $00, $69, $6a, $6b, $6c, $6d, $6e, $6f, $70, $71, $72, $73, $74, $00, $00, $00, $00, $00, $00,0,0,0,0,0,0
    db 0,0,0,0,0,0,$00, $00, $00, $00, $75, $76, $77, $78, $79, $7a, $7b, $7c, $7d, $00, $00, $00, $00, $00, $00, $00,0,0,0,0,0,0
    db 0,0,0,0,0,0,$00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00,0,0,0,0,0,0
    db 0,0,0,0,0,0,$00, $00, $00, $00, $00, $00, $00, $80, $81, $82, $83, $84, $85, $00, $00, $00, $00, $00, $00, $00,0,0,0,0,0,0
    db 0,0,0,0,0,0,$00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00,0,0,0,0,0,0
    db 0,0,0,0,0,0,$00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00,0,0,0,0,0,0
    db 0,0,0,0,0,0,$00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $96, $97, $98, $99, $9a, $9b, $9c, $9d,$9e,$9f,0,0,0,0
    db 0,0,0,0,0,0,$00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $a6, $a7, $a8, $a9, $aa, $ab, $ac, $ad,$ae,$af,0,0,0,0
    db 0,0,0,0,0,0,$00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $b6, $b7, $b8, $b9, $ba, $bb, $bc, $bd,$be,$bf,0,0,0,0
TitleTilemapEnd

ModuloB:
.loop
    cp a, b
    ret c
    sub a, b
    jr .loop

DivB:
    ld c, 0
.loop
    cp a, b
    jr c, .ret
    sub a, b
    inc c
    jr .loop
.ret
    ld a, c
    ret

Powers:
    dw 1, 2, 4, 8, 16, 32, 64, 128, 256, 512, 1024, 2048

AddScore:
    push hl
    push de
    ld hl, Powers
    ld e, a
    ld d, 0
    add hl, de
    add hl, de
    ld a, [hli]
    ld h, [hl]
    ld l, a
    ld a, [H_SCORE]
    ld e, a
    ld a, [H_SCORE+1]
    ld d, a
    push hl
    add hl, de
    ld a, l
    ld [H_SCORE], a
    ld a, h
    ld [H_SCORE+1], a
    pop hl
    ld a, [H_PLUSSCORE]
    ld e, a
    ld a, [H_PLUSSCORE+1]
    ld d, a
    add hl, de
    ld a, l
    ld [H_PLUSSCORE], a
    ld a, h
    ld [H_PLUSSCORE+1], a
    
    ld a, [H_SCORE]
    ld l,a
    ld a,[H_SCORE+1]
    ld h, a
    ld a, [H_HIGHSCORE]
    ld e, a
    ld a, [H_HIGHSCORE+1]
    ld d, a
    cp h
    jr z, .maybe
    jr nc, .nothi
    jr c, .new
.maybe
    ld a, e
    cp l
    jr nc, .nothi
.new
    ld a, l
    ld [H_HIGHSCORE], a
    ld a, h
    ld [H_HIGHSCORE+1], a
.nothi
    pop de
    pop hl
    ret

Modulo10: ; bc %= 10
.loop
    ld a, b
    and a
    jr nz, .nz
    ld a, c
    cp 10
    ret c
.nz
    ld a, c
    sub 10
    ld c, a
    jr nc, .loop
    dec b
    jr .loop

Div10: ; bc /= 10
    push de
    ld de, 0
.loop
    ld a, b
    and a
    jr nz, .nz
    ld a, c
    cp 10
    jr c, .ret
.nz
    ld a, c
    sub 10
    ld c, a
    jr nc, .ok
    dec b
.ok
    inc de
    jr .loop
.ret
    push de
    pop bc
    pop de
    ret

WriteNumAndCarry:
    push bc
    call Modulo10
    ld a, c
    ;add a
    add $e8
    ld [hld], a
    pop bc
    call Div10
    ret

WriteNumber:
; writes number at de to hl (backwards)
    ld a, [de]
    ld c, a
    inc de
    ld a, [de]
    ld b, a
    call WriteNumAndCarry
    call WriteNumAndCarry
    call WriteNumAndCarry
    call WriteNumAndCarry
    ret
    
SprWriteNumAndCarry:
    push bc
    call Modulo10
    ld a, c
    add a
    add $60
    ld [hld], a
    pop bc
    call Div10
    ret

SprWriteNumber:
    ld a, [de]
    ld c, a
    inc de
    ld a, [de]
    ld b, a
    call SprWriteNumAndCarry
    call SprWriteNumAndCarry
    call SprWriteNumAndCarry
    call SprWriteNumAndCarry
    ret

UpdateTilemapScore:
    ; draw score
    hlcoord $15, 6
    ld a, $e0
    ld [hli], a
    inc a
    ld [hli], a
    inc a
    ld [hli], a
    hlcoord $15, $a+6
    ld a, $e3
    ld [hli], a
    inc a
    ld [hli], a
    inc a
    ld [hli], a
    inc a
    ld [hli], a
    inc a
    ld [hli], a
    
    hlcoord $15, 8+6
    ld de, H_SCORE
    call WriteNumber
    hlcoord $15, $13+6
    ld de, H_HIGHSCORE
    call WriteNumber
    ret

GridTilemap:
    db $10, $11, $12, $13, $10, $11, $12, $13, $10, $11, $12, $13, $10, $11, $12, $13
    db $14, $15, $16, $17, $14, $15, $16, $17, $14, $15, $16, $17, $14, $15, $16, $17
    db $18, $19, $1A, $1B, $18, $19, $1A, $1B, $18, $19, $1A, $1B, $18, $19, $1A, $1B
    db $1C, $1D, $1E, $1F, $1C, $1D, $1E, $1F, $1C, $1D, $1E, $1F, $1C, $1D, $1E, $1F
    db $10, $11, $12, $13, $10, $11, $12, $13, $10, $11, $12, $13, $10, $11, $12, $13
    db $14, $15, $16, $17, $14, $15, $16, $17, $14, $15, $16, $17, $14, $15, $16, $17
    db $18, $19, $1A, $1B, $18, $19, $1A, $1B, $18, $19, $1A, $1B, $18, $19, $1A, $1B
    db $1C, $1D, $1E, $1F, $1C, $1D, $1E, $1F, $1C, $1D, $1E, $1F, $1C, $1D, $1E, $1F
    db $10, $11, $12, $13, $10, $11, $12, $13, $10, $11, $12, $13, $10, $11, $12, $13
    db $14, $15, $16, $17, $14, $15, $16, $17, $14, $15, $16, $17, $14, $15, $16, $17
    db $18, $19, $1A, $1B, $18, $19, $1A, $1B, $18, $19, $1A, $1B, $18, $19, $1A, $1B
    db $1C, $1D, $1E, $1F, $1C, $1D, $1E, $1F, $1C, $1D, $1E, $1F, $1C, $1D, $1E, $1F
    db $10, $11, $12, $13, $10, $11, $12, $13, $10, $11, $12, $13, $10, $11, $12, $13
    db $14, $15, $16, $17, $14, $15, $16, $17, $14, $15, $16, $17, $14, $15, $16, $17
    db $18, $19, $1A, $1B, $18, $19, $1A, $1B, $18, $19, $1A, $1B, $18, $19, $1A, $1B
    db $1C, $1D, $1E, $1F, $1C, $1D, $1E, $1F, $1C, $1D, $1E, $1F, $1C, $1D, $1E, $1F

DetermineFastVcopyPart: ; XXX unused, remove
    ld hl, W_ANIMFRAMES
    ld a, [H_ANIMFRAME]
    swap a
    add 12
    ld l, a
    ; if anything in the bottom row is moving, we need to update it.
rept 4
    ld a, [hli]
    bit 7, a
    jr nz, .bottom
endr
    ; if we're moving down and anything in the third row is moving, we need 
    ; to update it.
    ld a, [H_ANIMDIR]
    and a
    jr nz, .top
    ld hl, W_ANIMFRAMES
    ld a, [H_ANIMFRAME]
    swap a
    add 8
    ld l, a
rept 4
    ld a, [hli]
    bit 7, a
    jr nz, .bottom
endr
.top
    xor a
    ;ld [H_FAST_PART], a
    ret
.bottom
    ld a, 1
    ;ld [H_FAST_PART], a
    ret

TilemapAddValues:
; down up left right
    dw 32, -32, -1, 1

UpdateTilemap:
    ld a, [H_ANIMDIR]
    add a
    ld hl, TilemapAddValues
    ld d, 0
    ld e, a
    add hl, de
    ld a, [hli]
    ld [H_CURTMAPADD], a
    ld a, [hl]
    ld [H_CURTMAPADD+1], a
    ; draw 2048 tiles
    ld de, GridTilemap
    hlcoord 4, 8
    ld b, 16
    ld c, 16
    di
.row
    ld b, 16
.col
    ld a, [de]
    ld [hli], a
    inc de
    dec b
    jr nz, .col
    push bc
    ld bc, 16
    add hl, bc
    pop bc
    dec c
    jr nz, .row
    
    ld bc, $0000
    ld a, [H_ANIMATE]
    and a
    jr z, .regular
    ld de, W_ANIMFRAMES
    ld a, [H_ANIMFRAME]
    swap a
    ld e, a
    jr .picked
.regular
    ld de, W_2048GRID
.picked
    hlcoord 4, 8
    dec de
.loop
    inc de
    ld a, [de]
    res 7, a
    and a
    jp z, .blank
    inc a
    sla a
    sla a
    sla a
    sla a
    push af
    push bc
    push de
    ld a, [de]
    bit 7, a
    jr z, .noanim
    ; anim
    ld a, [H_ANIMSUB]
    and a
    jr z, .noanim
    ld b, a
    ld a, [H_CURTMAPADD]
    ld e, a
    ld a, [H_CURTMAPADD+1]
    ld d, a
.shiftloop
    add hl, de
    dec b
    jp nz, .shiftloop
.noanim
    pop de
    pop bc
    pop af
    ld c, 4
.tileloop
    ld [hli], a
    inc a
    ld [hli], a
    inc a
    ld [hli], a
    inc a
    ld [hli], a
    inc a
    push bc
    ld bc, 28
    add hl, bc
    pop bc
    dec c
    jp nz, .tileloop
    push bc
    ld bc,0 -((32*4)-4)
    add hl, bc
    pop bc
    
    push af
    push bc
    push de
    ld a, [de]
    bit 7, a
    jr z, .noanim2
    ; anim
    ld a, [H_ANIMSUB]
    and a
    jr z, .noanim2
    ld b, a
    ld a, [H_CURTMAPADD]
    cpl
    ld e, a
    ld a, [H_CURTMAPADD+1]
    cpl
    ld d, a
.shiftloop2
    add hl, de
    inc hl
    dec b
    jr nz, .shiftloop2
.noanim2
    pop de
    pop bc
    pop af
    
.next
    inc b
    ld a, b
    cp 16
    jr z, .ret
    and %00000011
    jp nz, .loop
    push bc
    ld bc, 32*3 + 16; OFFSET FROM LEFT
    add hl, bc
    pop bc
    jp .loop

.blank
    inc hl
    inc hl
    inc hl
    inc hl
    jr .next
.ret
    ei
    ret

GameOver:
    ld a, 1
    ld [H_GAMEOVER], a
    ld a, %10010100
    ld [rBGP], a
    ld a, $10
    ld b, 9
    ld de, $403b
    ld hl, W_OAM
    call WriteSpriteRow
    ld a, $30
    ld b, 6
    ld de, $6444
    ld hl, W_OAM+4*10
    call WriteSpriteRow
    ret

YouWin:
    ld a, 1
    ld [H_GAMEOVER], a
    ld a, %10010100
    ld [rBGP], a
    ld a, $20
    ld b, 9
    ld de, $403b
    ld hl, W_OAM
    call WriteSpriteRow
    ld a, $30
    ld b, 6
    ld de, $6444
    ld hl, W_OAM+4*9
    call WriteSpriteRow
    ret

Has2048Tile:
    ld hl, W_2048GRID
    ld b, 16
.loop
    ld a, [hli]
    cp 11
    ret z
    dec b
    jr nz, .loop
    ld a, 1
    and a
    ret

StartScoreAnim:
    ret ; XXX todo
    ld a, %11010000
    ld [rOBP0], a
    ld de, H_PLUSSCORE
    ld hl, W_ANIMSCORETILES+5
    call SprWriteNumber
    ld a, $74
    ld [hl], a
    push hl
    pop de
    
    ld b, 5
    ld c, 5*8
    
    ld hl, W_OAM;+$8c
.loop
    ld a, 144+4
    ld [hli],a
    ld a, c
    ld [hli], a
    ld a, [de]
    ld [hli], a
    inc de
    ld0 [hli]
    ld a, c
    add 8
    ld c, a
    dec b
    jr nz, .loop
    
    ld a, 1
    ld [H_ANIMSCORE], a
    ret
    

AnimateScore:
    ret

ClearMergeBits:
    ; operates on hl
    ld b, 16
.loop
    res 7, [hl]
    inc hl
    dec b
    jr nz, .loop
    ret

PushAnimFrame:
    push de
    ld hl, W_ANIMFRAME
    ld de, W_ANIMFRAMES
    ld a, [H_CURANIMFRAME]
    inc a
    ld [H_CURANIMFRAME], a
    dec a
    swap a
    ld e, a
    ld bc, 16
    call CopyData
    
    ld hl, W_2048GRID
    ld de, W_ANIMFRAME
    ld bc, 16
    call CopyData
    
    ld hl, W_ANIMFRAME
    call ClearMergeBits
    pop de
    ret
    

AddValues:
; down up left right
    db 4, -4, -1, 1

NextValues:
    db 1, 1, 4, 4
    
BeginValues:
    db 8, 4, 1, 2

PrepareDirVals:
    ld a, [H_CURDIR]
    ld hl, AddValues
    ld d, 0
    ld e, a
    add hl, de
    ld a, [hl]
    ld [H_CURADD], a
    
    ld a, [H_CURDIR]
    ld hl, NextValues
    ld d, 0
    ld e, a
    add hl, de
    ld a, [hl]
    ld [H_CURNEXT], a
    ret
    

MoveGrid:
; a = direction
    ld [H_CURDIR], a
    
    call CanMoveGridDir
    ret z
    
    call PushAnimFrame
    xor a
    ld [H_CURANIMFRAME], a
    ld [H_PLUSSCORE], a
    ld [H_PLUSSCORE+1], a
    
    call PrepareDirVals
    
.outerloop
    ld a, [H_CURDIR]
    ld hl, BeginValues
    ld d, 0
    ld e, a
    add hl, de
    ld a, [hl]
    
    ld hl, W_2048GRID
    add l
    ld l, a
    
    ld c, 1
    ld e, 0 ; change occured

.loopx
    ld a, [hl]
    and a
    jr z, .donex
    ld b, a
    ld a, [H_CURADD]
    add l
    ld l, a
    ld a, [hl]
    and a
    jr z, .empty
    cp b
    jr z, .same
.nothing
    ; nothing to do here
    ld a, [H_CURADD]
    ld d, a
    ld a, l
    sub d
    ld l, a
.donex
    inc c
    ld a, c
    and %00000011
    jr z, .next
    
    ld a, [H_CURADD]
    ld d, a
    ld a, l
    sub d
    ld l, a
    jr .loopx
.next
    ld a, c
    cp 16
    jr z, .donestep
    inc c
    ld a, [H_CURADD]
    ld d, a
    ld a, l
    add d
    add d
    ld l, a
    ld a, [H_CURNEXT]
    add l
    ld l, a
    jr .loopx
    
.empty
    ld [hl], b
    ld a, [H_CURADD]
    ld d, a
    ld a, l
    sub d
    ld l, a
    xor a
    ld [hl], a
    set 7, l
    set 7, [hl]
    res 7, l
    ld e, 1
    jr .donex
.same
    bit 7, [hl]
    jr nz, .nothing
    inc [hl]
    ld a, [hl]
    set 7, [hl]
    call AddScore
    ld a, [H_CURADD]
    ld d, a
    ld a, l
    sub d
    ld l, a
    xor a
    ld [hl], a
    set 7, l
    set 7, [hl]
    res 7, l
    ld e, 1
    jr .donex
.donestep
    call PushAnimFrame
    ld a, e
    and a
    jr z, .donemoving
    ld e, 0
    jp .outerloop
.donemoving
    ; setup animation
    ld a, [H_CURDIR]
    ld [H_ANIMDIR], a
    ld a, 1
    ld [H_ANIMATE], a
    ld [H_FAST_VCOPY], a
    xor a
    ld [H_ANIMSUB], a
    ld [H_ANIMFRAME], a
    ; etc
    ld hl, W_2048GRID
    call ClearMergeBits
    ;call UpdateTilemapScore ; do this after an animation
    call AddNewTile
    call CanMoveGrid
    call z, GameOver
    call Has2048Tile
    call z, YouWin
    xor a ; else we'll hit other directional keys
    ret

CanMoveGridDir:
; a = direction
    ld [H_CURDIR], a
    
    call PrepareDirVals
    
.outerloop
    ld a, [H_CURDIR]
    ld hl, BeginValues
    ld d, 0
    ld e, a
    add hl, de
    ld a, [hl]
    
    ld hl, W_2048GRID
    add l
    ld l, a
    
    ld c, 1
.loopx
    ld a, [hl]
    and a
    jr z, .donex
    ld b, a
    ld a, [H_CURADD]
    add l
    ld l, a
    ld a, [hl]
    and a
    jr z, .empty
    cp b
    jr z, .same
.nothing
    ; nothing to do here
    ld a, [H_CURADD]
    ld d, a
    ld a, l
    sub d
    ld l, a
.donex
    inc c
    ld a, c
    and %00000011
    jr z, .next
    ld a, [H_CURADD]
    ld d, a
    ld a, l
    sub d
    ld l, a
    jr .loopx
    
.next
    ld a, c
    cp 16
    jr z, .done
    inc c
    ld a, [H_CURADD]
    ld d, a
    ld a, l
    add d
    add d
    ld l, a
    ld a, [H_CURNEXT]
    add l
    ld l, a
    jr .loopx
    xor a
    ret ; move won't do anything
.empty
.same
    ld a, 1
    and a
    ret
.done
    ; we didn't find any move
    xor a
    ret

CanMoveGrid:
    ld a, 0
    call CanMoveGridDir
    ret nz
    ld a, 1
    call CanMoveGridDir
    ret nz
    ld a, 2
    call CanMoveGridDir
    ret nz
    ld a, 3
    call CanMoveGridDir
    ret

MoveDown:
    ld a, 0
    jp MoveGrid
MoveUp:
    ld a, 1
    jp MoveGrid
MoveLeft:
    ld a, 2
    jp MoveGrid
MoveRight:
    ld a, 3
    jp MoveGrid

AddNewTile:
    ; pick tile (2=90, 4=10%)
    call GetRNG
    cp 256/10
    jr c, .four
    ld d, 1
    jr .picked
.four
    ld d, 2
.picked

    ; find free tiles
    ld b, 16
    ld c, 0 ; amount of free tiles
    ld hl, W_2048GRID
.loop
    ld a, [hli]
    and a
    jr nz, .nonfree
    inc c
.nonfree
    dec b
    jr z, .counted
    jr .loop
.counted
    ld a, c
    and a
    ret z ; no free tiles
    
    call GetRNG
    call ModuloC
    inc a
    ld b, a
    
    ld hl, W_2048GRID
.loop2
    ld a, [hli]
    and a
    jr nz, .loop2
    dec b
    jr nz, .loop2
    dec hl
    ld [hl], d
    ret

InitGame:
    ld a, 1
    ld b, $0d
    hlcoord 0, 10
    call WriteDataInc ; write data in hl increasing a until b.
    hlcoord 1, 8
    ld a, $0d
    ld [hli], a
    inc a
    ld [hli], a
    inc a
    ld [hli], a
    ld a, $d0
    ld b, $dd
    call WriteDataInc ; write data in hl increasing a until b.
    
    xor a
    ld [H_SCORE], a
    ld [H_SCORE+1], a
    ld [H_GAMEOVER], a
    ld hl, W_2048GRID
    ld b, 16
    call FillMemory
    call ClearOAM
    
    call AddNewTile
    call AddNewTile
    ;ld a, 1
    ;ld [W_2048GRID+5], a
    ;ld [W_2048GRID+10], a
    
    ld a, %11100100
    ld [rBGP], a
    call UpdateTilemap
    call UpdateTilemapScore

    call FadeFromWhite
    xor a
    ld [H_FAST_VCOPY], a
    ;hlcoord 0, 1
    ;ld a, $04
    ;ld b, $0e
    ;call WriteDataInc
    
.gameloop
    halt
    ld a, [H_ANIMATE]
    and a
    jr z, .input
    ; animate

    call UpdateTilemap
    ld a, [H_ANIMSUB]
    inc a
    ld [H_ANIMSUB], a
    cp 3
    jr nz, .gameloop
    xor a
    ld [H_ANIMSUB], a
    ld a, [H_ANIMFRAME]
    inc a
    ld [H_ANIMFRAME], a
    ld b, a
    ld a, [H_CURANIMFRAME]
    cp b
    jr nz, .gameloop
    xor a
    ld [H_ANIMATE], a
    ld [H_FAST_VCOPY], a
    call UpdateTilemapScore
    call StartScoreAnim
    jr .gameloop
.input
    call AnimateScore
    ld a, [H_GAMEOVER]
    and a
    jr nz, .gameover
    ld hl, H_JOYNEW
    ld a, [hl]
    ld [hl], 0
    
    swap a
; down up left right
    bit 3, a
    call nz, MoveDown
    bit 2, a
    call nz, MoveUp
    bit 1, a
    call nz, MoveLeft
    bit 0, a
    call nz, MoveRight
    call UpdateTilemap
    jp .gameloop
.gameover
    call UpdateTilemap
    call WaitForKey
    call FateToWhite_
    jp InitGame
    

Tiles:
    INCBIN "gfx/tiles.2bpp"




SECTION "bank1",DATA,BANK[$1]
Title:
    INCBIN "gfx/title.2bpp"
Sprites:
    INCBIN "gfx/sprites.2bpp"

SECTION "smsheader",DATA[$7ff0],BANK[$1]
    db "TMR SEGA  "
    dw $0000 ; checksum
    dw $0000 ; product code (bcd)
    db 0   ; version
    db $71



