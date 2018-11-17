
* Init CPU

cpuinit

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
; 0    MMU task select: TASK0
 ldb #$60
 sta $ff91
 rts

* Init Graphics

gfxinit

; VIDEO MODE REGISTER $FF98
; 1   Graphics bitplane mode: YES
; 0   Unused
; 0   Composite color phase invert: NO
; 0   Monochrome on composite video out: NO
; 0   50Hz video: NO
; 010 LPR: two lines per row
 ldb #$82
 stb $FF98

; VIDEO RESOLUTION REGISTER $FF99
; 0   Unused
; 00  LPF: 192 rows
; 100 HRES: 64 bytes per row
; 10  CRES: 16 colors, 2 pixels per byte
 ldb #$12
 stb $FF99

; DISTO MEMORY UPGRADE $FF9B
 clr $FF9B

; VERTICAL SCROLL REGISTER $FF9C
 clr $FF9C

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

 rts

* X xpos
* Y ypos
* U pointer to screen byte
* bcc even
ScreenByte
 pshs d
 ldu #SCREEN
 tfr y,d
 lda #64
 mul
 IFDEF M6309
 addr d,u ; u now points to beginning of row
 tfr x,d
 lsrd
 ELSE
 leau d,u
 tfr x,d
 lsra
 rorb
 ENDC
 leau d,u ; u now points to screen byte
 puls d,pc

; Clear screen
gfxcls

 IFDEF M6309
 tfr s,v
 tfr 0,u
 tfr 0,x
 tfr 0,y
 ELSE
 sts sreg
 ldu #0
 ldx #0
 ldy #0
 ENDC

 * 21 x 32 x 9 bytes 
 IFDEF M6309
 tfr 0,d
 lde #21
 ELSE
 lda #21
 sta ereg
 ldd #0
 ENDC
 lds #SCREEN+6144
loop@
 pshs d,x,y,u,dp
 pshs d,x,y,u,dp
 pshs d,x,y,u,dp
 pshs d,x,y,u,dp
 pshs d,x,y,u,dp
 pshs d,x,y,u,dp
 pshs d,x,y,u,dp
 pshs d,x,y,u,dp
 pshs d,x,y,u,dp
 pshs d,x,y,u,dp
 pshs d,x,y,u,dp
 pshs d,x,y,u,dp
 pshs d,x,y,u,dp
 pshs d,x,y,u,dp
 pshs d,x,y,u,dp
 pshs d,x,y,u,dp
 pshs d,x,y,u,dp
 pshs d,x,y,u,dp
 pshs d,x,y,u,dp
 pshs d,x,y,u,dp
 pshs d,x,y,u,dp
 pshs d,x,y,u,dp
 pshs d,x,y,u,dp
 pshs d,x,y,u,dp
 pshs d,x,y,u,dp
 pshs d,x,y,u,dp
 pshs d,x,y,u,dp
 pshs d,x,y,u,dp
 pshs d,x,y,u,dp
 pshs d,x,y,u,dp
 pshs d,x,y,u,dp
 pshs d,x,y,u,dp
 IFDEF M6309
 dece
 ELSE
 dec ereg
 ENDC
 bne loop@
 * 10 x 9 bytes
 pshs d,x,y,u,dp
 pshs d,x,y,u,dp
 pshs d,x,y,u,dp
 pshs d,x,y,u,dp
 pshs d,x,y,u,dp
 pshs d,x,y,u,dp
 pshs d,x,y,u,dp
 pshs d,x,y,u,dp
 pshs d,x,y,u,dp
 pshs d,x,y,u,dp
 * 6 bytes
 pshs d,x,y
 IFDEF M6309
 tfr v,s
 ELSE
 lds sreg
 ENDC
 rts

; Set pixel
; 128 x 96, 16 colors
; X is x 0-127
; Y is y 0-95
; B is color $00,$11,$22...$FF
 IFDEF M6309
gfxpset
 pshs d,x,y,u
 lbsr ScreenByte
 lda 1,s ; color
 ldb ,u ; get screen byte
 bcc even@
 IFDEF M6309
 andd #$0FF0
 ELSE
 anda #$0F
 andb #$F0
 ENDC
 bra cont@
even@
 IFDEF M6309
 andd #$F00F
 ELSE
 anda #$F0
 andb #$0F
 ENDC
cont@
 orr a,b  
 stb ,u ; replace screen byte
 puls d,x,y,u,pc
 ELSE
gfxpset
 pshs d,u
 lbsr ScreenByte
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
 com tick
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
 ldd #$FC00
 sta $FF9D	; MSB = $7E000 / 2048
 stb $FF9E	; LSB = (addr / 8) AND $ff
 rts

Screen1
 ldd #$DC00
 sta $FF9D	; MSB = $6E000 / 2048
 stb $FF9E	; LSB = (addr / 8) AND $ff
 rts

* X xpos
* Y ypos
* A length
* B color
VLine
 IFDEF M6309
 tfr d,w ; length in e, color in f
 ELSE
 std wreg
 ENDC
 lbsr ScreenByte
loop@
* BEGIN ONE PIXEL
 IFDEF M6309
 tfr f,a
 ELSE
 lda freg
 ENDC
 ldb ,u ; screen byte
 bcc even@
 IFDEF M6309
 andd #$0FF0
 ELSE
 anda #$0F
 andb #$F0
 ENDC
 bra cont@
even@
 IFDEF M6309
 andd #$F00F
 ELSE
 anda #$F0
 andb #$0F
 ENDC
cont@
 IFDEF M6309
 orr a,b  
 ELSE
 pshs a
 orb ,s+
 ENDC
 stb ,u ; replace screen byte
* END ONE PIXEL
 leau 64,u
 IFDEF M6309
 dece
 ELSE
 dec ereg
 ENDC
 bgt loop@
 rts

* X xpos
* Y ypos
* A length
* B color
HLine
 IFDEF M6309
 tfr d,w ; length in e, color in f
 ELSE
 std wreg
 ENDC
 lbsr ScreenByte
 bcc even1@
; line begins on 2nd nibble
 IFDEF M6309
 tfr f,a
 ELSE
 lda freg
 ENDC
 ldb ,u ; get screen byte
 IFDEF M6309
 andd #$0FF0
 orr a,b  
 ELSE
 anda #$0F
 andb #$F0
 pshs a
 orb ,s+
 ENDC
 stb ,u+ ; replace screen byte, point to next byte
 bra cont1@
even1@
; line begins on 1st nibble
cont1@
 stu addr1
 IFDEF M6309
 tfr e,b
 ELSE
 ldb ereg
 ENDC
 decb
 abx
 lbsr ScreenByte
 bcs odd2@
 ; line ends on 1st nibble
 IFDEF M6309
 tfr f,a
 ELSE
 lda freg
 ENDC
 ldb ,u
 IFDEF M6309
 andd #$F00F
 orr a,b
 ELSE
 anda #$F0
 andb #$0F
 pshs a
 orb ,s+
 ENDC
 stb ,u
 leau -1,u
 bra cont2@
odd2@
; line ends on 2nd nibble
cont2@
 stu addr2
; write full bytes
 IFDEF M6309
 tfr f,b
 ELSE
 ldb freg
 ENDC
 ldu addr1
loop@
 stb ,u+
 cmpu addr2
 bls loop@
 rts

; Draw dot
; X is x 0-127
; Y is y 0-95
; B is color $00,$11,$22...$FF
DrawDot
 lbsr gfxpset
 leax 1,x
 lbsr gfxpset
 leay 1,y
 lbsr gfxpset
 leax -1,x
 lbsr gfxpset
 leay -1,y
 rts
