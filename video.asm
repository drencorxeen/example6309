
* Init CPU

cpuinit
 pshs b

; INITIALIZATION REGISTER 0 $FF90
; 0    Coco 1/2 compatible: NO
; 1    MMU enabled: YES
; 0    GIME IRQ enabled: NO
; 0    GIME FIRQ enabled: NO
; 1    RAM at FExx is constant: YES
; 0    Standard SCS (spare chip select): OFF
; 00   ROM map control: 16k internal, 16K external
 ldb #$48
 stb $FF90

; INITIALIZATION REGISTER 1 $FF91
; 0    Unused
; 1    Memory type 1=256K, 0=64K chips
; 1    TINS Timer clock source 1=279.365 nsec, 0=63.695 usec
; 0000 Unused
; 0    MMU task select 0=enable FFA0-FFA7, 1=enable FFA8-FFAF
 ldb #$60
 sta $ff91
 puls b,pc

* Init Graphics

gfxinit
 pshs d
; VIDEO MODE REGISTER $FF98
; 1  Graphic mode: YES
; 0  Unused
; 0  Composite color phase invert: NO
; 0  Monochrome on composite video out: NO
; 0  50Hz video: NO
; 00 Lines per row: one line per row
 ldb #$80
 stb $FF98

; VIDEO RESOLUTION REGISTER $FF99
; 0   Unused
; 11  LPF: 225
; 111 HRES: 160 bytes per row
; 10  CRES: 16 colors, 2 pixels per byte
 ldb #$7E
 stb $FF99

; HORIZONTAL OFFSET REGISTER $FF9F
 clr $FF9F

; COLOR PALETTE REGISTERS $FFB0 - $FFBF
 lda #0		; 0 BLACK
 sta $FFB0
 lda #55	; 1 YELLOW
 sta $FFB1
 lda #23	; 2 BRIGHT GREEN
 sta $FFB2
 lda #32 	; 3 RED
 sta $FFB3
 lda #20 	; 4 DARK GREEN
 sta $FFB4
 lda #7 	; 5 DARK GRAY
 sta $FFB5
 lda #9 	; 6 BLUE
 sta $FFB6
 lda #56 	; 7 LIGHT GRAY
 sta $FFB7
 lda #23 	; 8 LIGHT GREEN
 sta $FFB8
 lda #62 	; 9 LIGHT YELLOW
 sta $FFB9
 lda #47 	; 10 MAGENTA
 sta $FFBA
 lda #53 	; 11 PUMPKIN
 sta $FFBB
 lda #31 	; 12 CYAN
 sta $FFBC
 lda #38 	; 13 ORANGE
 sta $FFBE
 lda #63 	; 14 WHITE
 sta $FFBF

; BORDER COLOR REGISTER $FF9A
 lda #0		; BLACK
 sta $ff9A

 puls d,pc

; Clear screen
 IFDEF M6309
gfxcls
 clr ,-s
 ldu #SCREEN
 ldw #36000
 tfm s,u+
 leas 1,s
 rts
 ELSE
gfxcls
 ldu #SCREEN
 ldx #1125
 ldd #0
loop@
 std ,u++
 std ,u++
 std ,u++
 std ,u++
 std ,u++
 std ,u++
 std ,u++
 std ,u++
 std ,u++
 std ,u++
 std ,u++
 std ,u++
 std ,u++
 std ,u++
 std ,u++
 std ,u++
 leax -1,x
 bne loop@
 rts
 ENDC

; Set pixel
; 320 x 225, 16 colors
; X is x 0-320
; Y is y 0-224
; B is color $00,$11,$22...$FF
 IFDEF M6309
gfxpset
 pshs d,u
 ldu #SCREEN
 tfr y,d
 lda #160
 mul
 addr d,u ; u now points to beginning of row
 tfr x,d
 lsrd
 leau d,u ; u now points to screen byte
 lda 1,s ; color
 ldb ,u ; screen byte
 bcc even@
 andd #$0FF0
 bra cont@
even@
 andd #$F00F
cont@
 orr a,b  
 stb ,u ; replace screen byte
 puls d,u,pc
 ELSE
gfxpset
 pshs d,u
 ldu #SCREEN
 tfr y,d
 lda #160
 mul
 leau d,u ; u now points to beginning of row
 tfr x,d
 lsra
 rorb
 leau d,u ; u now points to screen byte
 lda 1,s ; color
 ldb ,u ; screen byte
 bcc even@
 anda #$0F
 andb #$F0
 bra cont@
even@
 anda #$F0
 andb #$0F
cont@
 pshs a
 orb ,s+
 stb ,u ; replace screen byte
 puls d,u,pc
 ENDC

FlipScreens
 sync
 inc tick
 lda tick
 anda #1
 bne task0@
 lbsr Screen1
 lbsr Task0
 rts
task0@
 lbsr Screen0
 lbsr Task1
 rts

Task0
 ldb #$60	; switch to task 0
 stb $FF91
 rts

Task1
 ldb #$61	; switch to task 1
 stb $FF91
 rts

Screen0
 ldd #$EC00
 sta $FF9D	; MSB = $76000 / 2048
 stb $FF9E	; LSB = (addr / 8) AND $ff
 rts

Screen1
 ldd #$CC00
 sta $FF9D	; MSB = $66000 / 2048
 stb $FF9E	; LSB = (addr / 8) AND $ff
 rts
