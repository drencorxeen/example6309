 org $0

vsync rmb 1
seed  rmb 2
tick  rmb 1
xpos  rmb 1
yline rmb 1
xline rmb 1
addr1 rmb 2
addr2 rmb 2
joyx  rmb 1
joyy  rmb 1
lastb rmb 1
joyb  rmb 1
 IFDEF M6809
sreg rmb 2
wreg rmb 0
ereg rmb 1
freg rmb 1
 ENDC

 org $1000

STACK rmb 1

XPOS equ 0
YPOS equ 1
XDELTA equ 2
YDELTA equ 3
COLOR equ 4
table rmb 5*16

 org $2000

start

 * Enable 6309 native mode
 IFDEF M6309
 lbsr enable6309
 ENDC

 * Disable IRQ and FIRQ
 lbsr DisableIRQ

 * Relocate stack
 lds #STACK

 * Set direct page
 clra
 tfr a,dp

 * Turn off ROMs
 lbsr romsoff

 * 1.78 Mhz CPU
 lbsr fast

 * Initialize MMU
 lbsr InitMMU

 * Seed random number routine
 ldd $112
 bne no@ ; can't be zero
 ldd #123
no@
 std seed

 * Clear VSYNC flag
 clr vsync

 * Init CPU
 lbsr cpuinit

 * Init graphics
 lbsr gfxinit

 * Clear screens
 lbsr Task0
 lbsr gfxcls
 lbsr Task1
 lbsr gfxcls

 * Initialize IRQ routine
 lbsr InitIRQ

 * Enable IRQ interrupts
 lbsr EnableIRQ

 * Start green lines at center of screen
 clr xpos
 lda #128/2
 sta xline
 lda #96/2
 sta yline

 * Init dot table
 lda #14 ; number of dots
 pshs a
 ldu #table
 leax colors,pcr
loop@
 lbsr rand ; random x
 lda #125
 mul
 inca
 sta XPOS,u
 lbsr rand ; random y
 lda #93
 mul
 inca
 sta YPOS,u
 lbsr rand ; random xdelta, going to be 1 or FF
 lda #1
 andb #1
 beq no@
 lda #$FF
no@
 sta XDELTA,u
 lbsr rand ; random ydelta, going to be 1 or FF
 lda #1
 andb #1
 beq no@
 lda #$FF
 sta YDELTA,u
 lbsr rand ; random color
 lda #14
 mul
 inca
 lda a,x
 sta COLOR,u
 leau 5,u
 dec ,s
 bne loop@
 clr ,u ; end of table
 puls a

mainloop

 lbsr FlipScreens

* Turn on border (DEBUG)
; lda #100
; sta $ff9a

 * BEGIN SCREEN DRAWING
 lbsr DrawFrame
 * END SCREEN DRAWING

* Turn off border (DEBUG)
; lda #0
; sta $ff9a

 lbra mainloop

IRQ
 clr vsync
* Turn on border (DEBUG)
; lda #100
; sta $ff9a
 lbsr JoyIn
 ldb #KEYBREAK
 lbsr KeyIn
 bne no@
 lbsr reset
no@
* Turn off border (DEBUG)
; lda #0
; sta $ff9a
 inc vsync	  ; set VSYNC flag
 lda $FF02	  ; dismiss interrupt
 rti

 incl video.asm
 incl utils.asm
 incl joystick.asm
 incl drawframe.asm

SCREEN EQU $E000

 end start
