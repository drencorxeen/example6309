
; Set starting position

SetStartPos
 ldd #62*256+46		; default screen position (62,46)
 sta curposx		; set horizontal position
 stb curposy		; set vertical position
 ldd #398		; set starting screen position (X)
* if X is odd, the end is fine, beginning wrong
* if even the beginning is fine, ending wrong
 std mazeoffx
 ldd #290 ;#291 		; set starting screen position (Y)
 std mazeoffy
 rts

DoLines
 bsr VLines	; vertical lines
 lbsr HLines	; horizontal lines
 rts

; Render the vertical lines of the map
VLines	leau LC34A,pcr	; point to short circuit offset table for vertical lines
	ldd mazeoffx	; fetch screen display offset for maze
	bge LC013	; brif screen X offset is positive
	ldd #0		; minimize to 0
LC013	lslb		; shift upper 4 bits of position into A
	rola
	lslb
	rola
	lsla		; two bytes per offset
	ldd a,u		; get offset from start of offset table
	leau d,u	; point to actual render data
LC01C	clra		; zero extend next read
	pulu b		; fetch column number
	tstb		; end of data?
	beq LC06F	; brif so
	lslb		; multiply by 4
	rola
	lslb
	rola
	subd mazeoffx	; compare to maze offset
	blt LC06B	; brif off the left of the screen
	cmpd #$7f	; are we off the right side of the screen?
	bgt LC06F	; brif so - don't render anything
	tfr d,x		; save offset from left of the screen
	clra		; zero extend next read
	pulu b		; get top coordinate of line
	lslb		; times 4
	rola
	lslb
	rola
	subd mazeoffy	; compare to screen offset (vertical)
	cmpd #8		; is it in the header or off the screen?
	bge LC043	; brif not
	ldb #8		; force to start at top of visible area
LC043	cmpd #$5f	; are we at the bottom of the screen?
	ble LC04B	; brif not
	ldb #$5f	; force to end at the bottom of the screen
LC04B	pshs b		; save first Y coordinate
	clra		; zero extend next read
	pulu b		; fetch bottom Y coordinate (offset from top of screen)
	lslb		; times 4
	rola
	lslb
	rola
	subd mazeoffy	; compare to screen offset (vertical)
	bge LC059	; brif below top of screen
	clrb		; normalize into screen
LC059	cmpd #$5f	; are we off the bottom of the screen
	ble LC061	; brif not
	ldb #$5f	; normalize into screen
LC061	lda ,s		; get adjusted top coordinate back
	cmpb ,s+	; is the bottom coordinate below the top coordinate?
	bls LC01C	; brif so - we don't need to render anything
	bsr VLine	; draw line
	bra LC01C	; go check next line to render
LC06B	leau 2,u	; move to next line to consider
	bra LC01C	; go render it if necessary
LC06F	rts

 * Draw vertical line
 * A = top Y coordinate
 * B = bottom Y coordinate
 * X = X coordinate
VLine	pshs a		; save top coordinate
	pshs b		; save bottom coordinate
	tfr x,d		; stuff the horizontal coordinate into an accumulator
	andb #1		; figure out which pixel in the byte we're at
	leay LC09A,pcr	; point to pixel bit masks
	lda b,y		; get the proper pixel bit mask
	ldb ,s+		; get bottom coordinate
	subb ,s		; subtract out top coordinate (number of pixels to do)
	exg d,x		; swap count and pixel mask with X coordinate
	lda ,s+		; get top coordinate
	lslb		; compensate for the right shifts below
	lsra		; * calcuate offset from start of screen; this needs to
	rorb		; * multiply the row number by 64 and add the column
	lsra		; * number divided by 2
	rorb
	ora #$E0	; add to base screen address
	exg d,x		; put into pointer and get back pixel mask and counter
LC091	sta ,x		; set pixel for line
	leax 64,x	; move to next row
	decb		; done last pixel?
	bpl LC091	; brif not
	rts

LC09A	fcb $60,$06

HLines	leau LC36A,pcr	; point to short circuit offsets for horizontal drawing
	ldd mazeoffy	; get vertical offset of screen
	bge LC0A9	; brif valid coordinate
	ldd #0		; minimize to 0
LC0A9	lslb		; get upper 4 bits of offset into A
	rola
	lslb
	rola
	lsla		; two bytes per offset entry
	ldd a,u		; get offset from start of offset table
	leau d,u	; point to data to render
LC0B2	clra		; zero extend for next read
	pulu b		; get horizontal coordinate
	tstb		; end of data?
	beq LC104	; brif so
	lslb		; times 4
	rola
	lslb
	rola
	subd mazeoffy	; get offset relative to screen position
	cmpd #8		; are we above the screen or in the header?
	blt LC100	; brif so
	cmpd #$5f	; are we below the bottom of the screen?
	bgt LC100	; brif so
	tfr d,x		; save vertical offset for later
	clra		; zero extend for next read
	pulu b		; get left coordinate for line
	lslb		; times 4
	rola
	lslb
	rola
	subd mazeoffx	; get offset relative to the screen position
	bge LC0D8	; brif not off the left side
	clrb		; normalize to left side
LC0D8	cmpd #$7f	; off the right of the screen?
	ble LC0E0	; brif not
	ldb #$7f	; normalize to right side
LC0E0	pshs b		; save left coordinate
	clra		; zero extend next read
	pulu b		; fetch right coordinate
	lslb		; times 4
	rola
	lslb
	rola
	subd mazeoffx	; offset according to the screen position
	bge LC0EE	; brif not off left side of screen
	clrb		; normalize to left side of screen
LC0EE	cmpd #$7f	; are we off the right side of the screen?
	ble LC0F6	; brif not
	ldb #$7f	; normalize to right side of screen
LC0F6	lda ,s		; get left coordinate back
	cmpb ,s+	; is right coordinate left of left coordinate?
	bls LC0B2	; brif so (or same as)
	bsr HLine	; go draw line
	bra LC0B2	; go handle next line
LC100	leau 2,u	; move to next set of line data
	bra LC0B2	; go render it if needed
LC104	rts

 * Draw horizontal line
 * A = left X coordinate
 * B = right X coordinate
 * X = Y coordinate
HLine	pshs d		; save coordinates
	anda #1		; figure out if line endpoints are
	andb #1		; on even or odd coordinates
	std odd1
	ldd ,s		; get back the coordinate
	exg x,d		; save both coordinates and get vertical offset
	tfr b,a		; put Y coordinate in A
	ldb ,s		; left X coordinate in B
	rolb		; calcuate screen offset
	lsra
	rorb
	lsra
	rorb
	ora #$E0	; add screen base
	exg d,x		; screen pointer goes in X, get back the coordinates
	subb ,s		; calculate number of pixels
	incb
	lsrb		; divide by 2 for the number of bytes
* BEGINNING OF LINE
	tst odd1
	beq even@
	lda #$06 	; odd: single pixel at beginning of line
	sta ,x+
* MIDDLE OF LINE
even@	lda #$66	; set up for whole bytes
loop@	sta ,x+		; save to screen
	decb		; done?
	bne loop@	; brif not
* END OF LINE
done@	tst odd2	
	bne exit@
	lda #$60	; 60 even: single pixel at end of line
	sta ,x
exit@	puls d,pc

; The following two tables are indexes into the maze data to short circuit
; rendering some lines that are definitely outside the viewable area.
;
; Line data, both vertical and horizontal, consists of three bytes each. The
; first byte is the vertical or horizontal coordinate that covers the whole line.
;
; The second is the start of the line (top or left). The third is the end of
; the line (bottom or right). All coordinates are divided by four which means
; lines must be on a multiple of 4, but it also saves a lot of space for the
; map data. It could be thought of as a 256x256 maze that is zoomed by a
; factor of four when used.
;
; Offsets for rendering vertical lines (can be excluded based on horizontal position)
LC34A	fdb vertscr0-LC34A
	fdb vertscr1-LC34A
	fdb vertscr2-LC34A
	fdb vertscr3-LC34A
	fdb vertscr4-LC34A
	fdb vertscr5-LC34A
	fdb vertscr6-LC34A
	fdb vertscr7-LC34A
	fdb vertscr8-LC34A
	fdb vertscr9-LC34A
	fdb vertscr10-LC34A
	fdb vertscr11-LC34A
	fdb vertscr12-LC34A
	fdb vertscr13-LC34A
	fdb vertscr14-LC34A
	fdb vertscr15-LC34A

; Offsets for rendering horizontal lines (can be excluded based on vertical position)
LC36A	fdb horscr0-LC36A
	fdb horscr1-LC36A
	fdb horscr2-LC36A
	fdb horscr3-LC36A
	fdb horscr4-LC36A
	fdb horscr5-LC36A
	fdb horscr6-LC36A
	fdb horscr7-LC36A
	fdb horscr8-LC36A
	fdb horscr9-LC36A
	fdb horscr10-LC36A
	fdb horscr11-LC36A
	fdb horscr12-LC36A
	fdb horscr13-LC36A
	fdb horscr14-LC36A
	fdb horscr15-LC36A

; This is the beginning of the map data.
vertscr0	fcb 1,148,158
	fcb 1,176,188
	fcb 2,50,63
	fcb 2,68,88
	fcb 2,88,104
	fcb 2,104,124
	fcb 3,2,16
	fcb 3,26,44
	fcb 4,28,36
	fcb 4,158,176
	fcb 5,158,169
	fcb 5,170,176
	fcb 7,69,80
	fcb 7,81,96
	fcb 7,96,111
	fcb 7,112,123
	fcb 8,148,152
	fcb 8,154,158
	fcb 9,36,44
	fcb 10,56,63
	fcb 11,166,169
	fcb 11,170,173
	fcb 11,176,188
	fcb 13,69,76
	fcb 13,85,96
	fcb 13,107,111
	fcb 13,112,119
	fcb 14,140,144
	fcb 14,148,152
	fcb 14,154,158
vertscr1	fcb 16,2,12
	fcb 16,13,16
	fcb 16,34,40
	fcb 16,166,173
	fcb 16,96,107
	fcb 17,96,107
	fcb 18,40,50
	fcb 20,40,50
	fcb 20,107,119
	fcb 21,13,20
	fcb 22,12,16
	fcb 22,50,56
	fcb 22,144,148
	fcb 22,158,174
	fcb 22,81,85
	fcb 23,80,85
	fcb 23,20,26
	fcb 23,28,34
	fcb 24,144,148
	fcb 24,158,172
	fcb 24,68,73
	fcb 25,20,26
	fcb 25,28,34
	fcb 26,12,16
	fcb 27,13,20
	fcb 28,40,48
	fcb 28,73,76
	fcb 28,110,123
	fcb 29,132,140
	fcb 30,133,140
	fcb 30,40,46
vertscr2	fcb 32,2,12
	fcb 32,13,16
	fcb 32,34,40
	fcb 32,140,144
	fcb 32,148,152
	fcb 32,154,158
	fcb 32,168,172
	fcb 32,174,187
	fcb 35,85,88
	fcb 35,89,96
	fcb 38,148,152
	fcb 38,154,158
	fcb 40,24,26
	fcb 40,28,46
	fcb 40,48,50
	fcb 40,68,88
	fcb 40,89,99
	fcb 41,69,98
	fcb 41,110,124
	fcb 45,2,16
	fcb 45,148,158
vertscr3	fcb 48,168,172
	fcb 48,174,187
	fcb 48,74,80
	fcb 50,80,85
	fcb 50,108,115
	fcb 50,119,126
	fcb 50,24,31
	fcb 50,33,50
	fcb 51,2,9
	fcb 51,55,61
	fcb 52,85,90
	fcb 54,90,95
	fcb 56,95,98
	fcb 56,137,143
	fcb 56,147,164
	fcb 56,168,172
	fcb 56,174,187
	fcb 57,95,99
	fcb 59,90,95
	fcb 60,133,137
	fcb 60,9,18
	fcb 60,46,55
	fcb 61,132,137
	fcb 61,85,90
	fcb 62,18,24
	fcb 62,40,46
	fcb 63,24,28
	fcb 63,36,40
	fcb 63,143,147
	fcb 63,80,85
vertscr4	fcb 64,28,31
	fcb 64,33,36
	fcb 64,28,31
	fcb 65,28,36
	fcb 65,143,147
	fcb 65,74,80
	fcb 65,108,111
	fcb 65,112,115
	fcb 65,119,122
	fcb 65,123,126
	fcb 66,24,28
	fcb 66,36,40
	fcb 67,18,24
	fcb 67,40,46
	fcb 69,9,18
	fcb 69,46,48
	fcb 69,50,55
	fcb 70,69,88
	fcb 70,88,111
	fcb 70,112,122
	fcb 72,137,143
	fcb 72,147,153
	fcb 72,155,164
	fcb 72,168,172
	fcb 72,174,187
	fcb 75,68,83
	fcb 75,86,104
	fcb 75,104,123
	fcb 78,2,9
	fcb 78,55,61
vertscr5	fcb 81,42,48
	fcb 81,50,56
	fcb 82,3,17
	fcb 86,17,42
	fcb 87,17,26
	fcb 87,27,42
	fcb 87,75,79
	fcb 87,90,94
	fcb 87,99,117
	fcb 87,123,139
	fcb 87,139,153
	fcb 87,155,172
	fcb 87,174,189
	fcb 89,125,139
	fcb 89,140,152
	fcb 89,152,165
	fcb 89,167,188
	fcb 91,42,56
	fcb 93,79,83
	fcb 93,86,90
	fcb 93,132,139
	fcb 93,140,147
	fcb 95,79,83
	fcb 95,86,90
vertscr6	fcb 96,42,56
	fcb 96,22,26
	fcb 96,27,32
	fcb 97,157,165
	fcb 97,167,170
	fcb 97,176,188
	fcb 101,75,79
	fcb 101,90,94
	fcb 101,99,107
	fcb 101,109,117
	fcb 103,132,139
	fcb 103,140,147
	fcb 104,22,32
	fcb 104,5,17
	fcb 104,48,50
	fcb 104,80,83
	fcb 104,86,89
	fcb 107,125,139
	fcb 109,43,48
	fcb 109,50,55
	fcb 109,11,24
	fcb 109,24,35
	fcb 109,125,140
vertscr7	fcb 112,68,73
	fcb 112,96,101
	fcb 113,141,147
	fcb 114,73,80
	fcb 114,89,96
	fcb 114,101,107
	fcb 115,35,42
	fcb 116,35,43
	fcb 117,73,80
	fcb 117,89,96
	fcb 117,101,107
	fcb 119,68,73
	fcb 119,96,101
	fcb 120,42,55
	fcb 120,157,165
	fcb 120,167,170
	fcb 120,176,188
	fcb 121,43,56
	fcb 123,109,123
	fcb 125,48,56
	fcb 125,1,3
	fcb 125,5,7
	fcb 125,109,123
	fcb 127,80,83
	fcb 127,86,89
	fcb 127,125,141
vertscr8	fcb 128,152,158
	fcb 128,174,179
	fcb 129,125,141
	fcb 130,67,71
	fcb 130,75,79
	fcb 130,90,94
	fcb 130,98,102
	fcb 130,167,174
	fcb 130,179,188
	fcb 132,167,174
	fcb 132,179,189
	fcb 133,147,152
	fcb 134,35,42
	fcb 134,174,179
	fcb 135,35,42
	fcb 135,147,152
	fcb 136,56,67
	fcb 136,79,83
	fcb 136,86,90
	fcb 138,56,67
	fcb 138,79,83
	fcb 138,86,90
	fcb 140,102,107
	fcb 140,109,114
	fcb 141,43,48
	fcb 141,11,17
	fcb 141,19,35
	fcb 142,43,48
	fcb 142,102,112
	fcb 142,141,147
	fcb 142,152,158
vertscr9	fcb 144,48,56
	fcb 144,67,71
	fcb 144,75,79
	fcb 144,90,94
	fcb 144,98,102
	fcb 145,1,3
	fcb 145,5,7
	fcb 147,125,136
	fcb 147,136,152
	fcb 147,152,165
	fcb 148,29,42
	fcb 148,43,56
	fcb 149,125,136
	fcb 149,136,152
	fcb 149,152,167
	fcb 151,5,17
	fcb 151,69,83
	fcb 151,86,96
	fcb 151,96,112
	fcb 153,29,40
	fcb 153,40,56
	fcb 153,5,19
	fcb 153,71,89
	fcb 153,91,109
	fcb 153,111,114
vertscr10	fcb 161,158,162
	fcb 162,131,142
	fcb 162,162,175
	fcb 163,162,174
	fcb 163,13,20
	fcb 163,28,38
	fcb 163,46,62
	fcb 165,48,60
	fcb 165,77,89
	fcb 165,91,103
	fcb 165,172,174
	fcb 165,175,177
	fcb 166,5,13
	fcb 166,20,28
	fcb 166,38,46
	fcb 167,142,158
	fcb 168,3,13
	fcb 168,20,28
	fcb 168,38,46
	fcb 169,62,69
	fcb 169,71,77
	fcb 169,103,109
	fcb 169,111,123
	fcb 170,142,158
	fcb 171,13,20
	fcb 171,28,38
	fcb 171,62,69
	fcb 171,71,77
	fcb 171,103,109
	fcb 171,111,123
	fcb 173,169,172
	fcb 173,177,180
	fcb 174,53,60
	fcb 175,77,88
	fcb 175,88,103
	fcb 175,131,142
vertscr11	fcb 178,3,20
	fcb 178,28,38
	fcb 179,77,88
	fcb 179,88,103
	fcb 179,169,172
	fcb 179,177,180
	fcb 183,71,77
	fcb 183,103,109
	fcb 184,131,142
	fcb 184,158,162
	fcb 185,71,77
	fcb 185,103,109
	fcb 187,172,174
	fcb 187,175,177
	fcb 189,77,88
	fcb 189,88,103
	fcb 191,3,8
	fcb 191,15,20
	fcb 191,28,31
	fcb 191,35,38
vertscr12	fcb 192,142,153
	fcb 193,77,88
	fcb 193,88,103
	fcb 196,153,165
	fcb 196,180,184
	fcb 197,165,174
	fcb 197,62,69
	fcb 197,71,77
	fcb 197,103,109
	fcb 197,111,123
	fcb 197,125,131
	fcb 199,62,69
	fcb 199,71,77
	fcb 199,103,109
	fcb 199,111,131
	fcb 199,165,174
	fcb 199,184,189
	fcb 200,153,165
	fcb 200,184,188
	fcb 202,35,46
	fcb 203,77,88
	fcb 203,88,103
	fcb 203,180,184
	fcb 204,142,153
	fcb 204,35,46
vertscr13	fcb 208,3,8
	fcb 208,15,20
	fcb 208,53,62
	fcb 209,165,174
	fcb 209,175,184
	fcb 210,166,183
	fcb 211,77,81
	fcb 211,99,103
	fcb 212,118,125
	fcb 212,131,142
	fcb 213,20,31
	fcb 214,71,77
	fcb 214,81,87
	fcb 214,93,99
	fcb 214,103,109
	fcb 214,111,118
	fcb 216,20,31
	fcb 216,71,77
	fcb 216,81,86
	fcb 216,94,99
	fcb 216,103,113
	fcb 216,115,118
	fcb 216,162,165
	fcb 216,166,170
	fcb 216,175,183
	fcb 216,184,188
	fcb 217,176,189
	fcb 219,3,20
	fcb 219,77,81
	fcb 219,99,103
	fcb 220,162,165
	fcb 220,166,170
	fcb 221,152,156
vertscr14	fcb 224,28,31
	fcb 224,35,38
	fcb 224,77,80
	fcb 224,87,93
	fcb 224,100,103
	fcb 224,142,152
	fcb 224,156,165
	fcb 225,143,152
	fcb 225,156,166
	fcb 225,48,69
	fcb 226,80,86
	fcb 226,94,100
	fcb 227,181,186
	fcb 227,46,69
	fcb 228,152,156
	fcb 229,170,175
	fcb 229,176,181
	fcb 230,171,181
	fcb 231,138,142
	fcb 231,143,147
	fcb 231,77,88
	fcb 231,88,103
	fcb 232,28,38
	fcb 232,181,186
	fcb 234,167,170
	fcb 234,171,174
	fcb 235,138,147
	fcb 235,71,88
	fcb 235,88,104
	fcb 235,104,113
	fcb 236,118,125
	fcb 237,69,88
	fcb 237,88,104
	fcb 237,104,115
	fcb 239,167,174
vertscr15	fcb 0		; mark end of vertical lines table

horscr0	fcb 1,125,145
	fcb 2,3,16
	fcb 2,32,45
	fcb 2,51,78
	fcb 3,82,104
	fcb 3,104,125
	fcb 3,145,168
	fcb 3,178,191
	fcb 3,208,219
	fcb 5,104,125
	fcb 5,145,151
	fcb 5,153,166
	fcb 7,125,145
	fcb 8,191,208
	fcb 9,51,60
	fcb 9,69,78
	fcb 11,109,128
	fcb 11,128,141
	fcb 12,16,22
	fcb 12,26,32
	fcb 13,16,21
	fcb 13,27,32
	fcb 13,163,166
	fcb 13,168,171
	fcb 15,191,208
horscr1	fcb 16,3,16
	fcb 16,22,26
	fcb 16,32,45
	fcb 17,82,86
	fcb 17,87,104
	fcb 17,141,151
	fcb 18,60,62
	fcb 18,67,69
	fcb 19,141,153
	fcb 20,21,23
	fcb 20,25,27
	fcb 20,163,166
	fcb 20,168,171
	fcb 20,178,191
	fcb 20,208,213
	fcb 20,216,219
	fcb 22,96,104
	fcb 24,40,50
	fcb 24,62,63
	fcb 24,66,67
	fcb 26,3,23
	fcb 26,25,40
	fcb 26,87,96
	fcb 27,87,96
	fcb 28,4,23
	fcb 28,25,40
	fcb 28,63,64
	fcb 28,65,66
	fcb 28,163,166
	fcb 28,168,171
	fcb 28,178,191
	fcb 28,224,232
	fcb 29,148,153
	fcb 31,50,64
	fcb 31,191,213
	fcb 31,216,224
horscr2	fcb 32,96,104
	fcb 33,50,64
	fcb 34,16,23
	fcb 34,25,32
	fcb 35,109,115
	fcb 35,116,134
	fcb 35,135,141
	fcb 35,191,202
	fcb 35,204,224
	fcb 36,4,9
	fcb 36,63,64
	fcb 36,65,66
	fcb 38,163,166
	fcb 38,168,171
	fcb 38,178,191
	fcb 38,224,232
	fcb 40,16,18
	fcb 40,20,28
	fcb 40,30,32
	fcb 40,62,63
	fcb 40,66,67
	fcb 42,81,86
	fcb 42,87,91
	fcb 42,96,115
	fcb 42,120,134
	fcb 42,135,148
	fcb 43,109,116
	fcb 43,121,141
	fcb 43,142,148
	fcb 44,3,9
	fcb 46,30,40
	fcb 46,60,62
	fcb 46,67,69
	fcb 46,163,166
	fcb 46,168,192
	fcb 46,192,202
	fcb 46,204,227
horscr3	fcb 48,104,109
	fcb 48,125,141
	fcb 48,165,192
	fcb 48,192,216
	fcb 48,216,225
	fcb 48,142,144
	fcb 48,28,40
	fcb 48,69,81
	fcb 50,2,18
	fcb 50,20,22
	fcb 50,40,50
	fcb 50,69,81
	fcb 50,104,109
	fcb 53,174,192
	fcb 53,192,208
	fcb 55,109,120
	fcb 55,51,60
	fcb 55,69,78
	fcb 56,10,22
	fcb 56,96,121
	fcb 56,125,136
	fcb 56,138,144
	fcb 56,148,153
	fcb 56,81,91
	fcb 60,165,174
	fcb 61,51,78
	fcb 62,163,169
	fcb 62,171,197
	fcb 62,199,208
	fcb 63,2,10
horscr4	fcb 67,130,136
	fcb 67,138,144
	fcb 68,112,119
	fcb 68,2,24
	fcb 68,40,56
	fcb 68,56,75
	fcb 68,40,56
	fcb 68,56,75
	fcb 69,7,13
	fcb 69,41,70
	fcb 69,151,169
	fcb 69,171,197
	fcb 69,199,225
	fcb 69,227,237
	fcb 71,153,169
	fcb 71,171,183
	fcb 71,185,197
	fcb 71,199,214
	fcb 71,216,235
	fcb 71,130,144
	fcb 73,112,114
	fcb 73,117,119
	fcb 73,24,28
	fcb 74,48,65
	fcb 75,87,101
	fcb 75,130,144
	fcb 76,13,28
	fcb 77,165,169
	fcb 77,171,175
	fcb 77,179,183
	fcb 77,185,189
	fcb 77,193,197
	fcb 77,199,203
	fcb 77,211,214
	fcb 77,216,219
	fcb 77,224,231
	fcb 79,130,136
	fcb 79,138,144
	fcb 79,87,93
	fcb 79,95,101
horscr5	fcb 80,224,226
	fcb 80,104,114
	fcb 80,117,127
	fcb 80,7,23
	fcb 80,48,50
	fcb 80,63,65
	fcb 81,7,22
	fcb 81,211,214
	fcb 81,216,219
	fcb 83,75,93
	fcb 83,95,104
	fcb 83,127,136
	fcb 83,138,151
	fcb 85,13,22
	fcb 85,23,35
	fcb 85,50,52
	fcb 85,61,63
	fcb 86,216,226
	fcb 86,75,93
	fcb 86,95,104
	fcb 86,127,136
	fcb 86,138,151
	fcb 87,214,224
	fcb 88,35,40
	fcb 89,35,40
	fcb 89,153,165
	fcb 89,104,114
	fcb 89,117,127
	fcb 90,87,93
	fcb 90,95,101
	fcb 90,130,136
	fcb 90,138,144
	fcb 90,52,54
	fcb 90,59,61
	fcb 91,153,165
	fcb 93,214,224
	fcb 94,216,226
	fcb 94,87,101
	fcb 94,130,144
	fcb 95,54,56
	fcb 95,57,59
horscr6	fcb 96,112,114
	fcb 96,117,119
	fcb 96,13,16
	fcb 96,17,35
	fcb 98,41,56
	fcb 98,130,144
	fcb 99,211,214
	fcb 99,216,219
	fcb 99,87,101
	fcb 99,40,57
	fcb 100,224,226
	fcb 101,112,114
	fcb 101,117,119
	fcb 102,130,140
	fcb 102,142,144
	fcb 103,165,169
	fcb 103,171,175
	fcb 103,179,183
	fcb 103,185,189
	fcb 103,193,197
	fcb 103,199,203
	fcb 103,211,214
	fcb 103,216,219
	fcb 103,224,231
	fcb 107,101,114
	fcb 107,117,140
	fcb 107,13,16
	fcb 107,17,20
	fcb 108,50,65
	fcb 109,153,169
	fcb 109,171,183
	fcb 109,185,197
	fcb 109,199,214
	fcb 109,101,123
	fcb 109,125,140
	fcb 110,28,41
	fcb 111,7,13
	fcb 111,65,70
	fcb 111,153,169
	fcb 111,171,197
	fcb 111,199,214
horscr7	fcb 112,142,151
	fcb 112,7,13
	fcb 112,65,70
	fcb 113,216,235
	fcb 114,140,153
	fcb 115,216,237
	fcb 115,50,65
	fcb 117,87,101
	fcb 118,212,214
	fcb 118,216,236
	fcb 119,13,20
	fcb 119,50,65
	fcb 122,65,70
	fcb 123,7,28
	fcb 123,65,75
	fcb 123,149,169
	fcb 123,171,197
	fcb 123,104,123
	fcb 123,125,149
	fcb 123,87,104
	fcb 124,2,24
	fcb 124,24,41
	fcb 125,149,176
	fcb 125,176,197
	fcb 125,212,236
	fcb 125,89,107
	fcb 125,109,127
	fcb 125,129,147
	fcb 126,50,65
horscr8	fcb 131,162,175
	fcb 131,184,197
	fcb 131,199,212
	fcb 132,93,103
	fcb 132,29,40
	fcb 132,40,61
	fcb 133,30,60
	fcb 137,56,60
	fcb 137,61,72
	fcb 138,231,235
	fcb 139,89,93
	fcb 139,103,107
	fcb 140,89,93
	fcb 140,103,109
	fcb 140,14,29
	fcb 140,30,32
	fcb 141,113,127
	fcb 141,129,142
	fcb 142,162,167
	fcb 142,170,175
	fcb 142,184,192
	fcb 142,204,212
	fcb 142,224,231
	fcb 143,225,231
	fcb 143,56,63
	fcb 143,65,72
horscr9	fcb 144,14,22
	fcb 144,24,32
	fcb 147,56,63
	fcb 147,65,72
	fcb 147,93,103
	fcb 147,113,133
	fcb 147,135,142
	fcb 147,231,235
	fcb 148,1,8
	fcb 148,14,22
	fcb 148,24,32
	fcb 148,38,45
	fcb 152,8,14
	fcb 152,32,38
	fcb 152,128,133
	fcb 152,135,142
	fcb 152,221,224
	fcb 152,225,228
	fcb 153,192,196
	fcb 153,200,204
	fcb 153,72,87
	fcb 154,8,14
	fcb 154,32,38
	fcb 155,72,87
	fcb 156,221,224
	fcb 156,225,228
	fcb 157,97,120
	fcb 158,128,142
	fcb 158,1,4
	fcb 158,5,8
	fcb 158,14,22
	fcb 158,24,32
	fcb 158,38,45
	fcb 158,161,167
	fcb 158,170,184
horscr10	fcb 162,161,162
	fcb 162,163,184
	fcb 162,216,220
	fcb 164,56,72
	fcb 165,89,97
	fcb 165,120,147
	fcb 165,196,197
	fcb 165,199,200
	fcb 165,209,216
	fcb 165,220,224
	fcb 166,210,216
	fcb 166,220,225
	fcb 166,11,16
	fcb 167,89,97
	fcb 167,120,130
	fcb 167,132,149
	fcb 167,234,239
	fcb 168,32,48
	fcb 168,56,72
	fcb 169,5,11
	fcb 169,173,179
	fcb 170,216,220
	fcb 170,229,234
	fcb 170,5,11
	fcb 170,97,120
	fcb 171,230,234
	fcb 172,165,173
	fcb 172,179,187
	fcb 172,72,87
	fcb 172,24,32
	fcb 172,48,56
	fcb 173,11,16
	fcb 174,22,32
	fcb 174,48,56
	fcb 174,72,87
	fcb 174,128,130
	fcb 174,132,134
	fcb 174,163,165
	fcb 174,187,197
	fcb 174,199,209
	fcb 174,234,239
	fcb 175,162,165
	fcb 175,187,209
	fcb 175,216,229
horscr11	fcb 176,97,120
	fcb 176,1,4
	fcb 176,5,11
	fcb 176,217,229
	fcb 177,165,173
	fcb 177,179,187
	fcb 179,128,130
	fcb 179,132,134
	fcb 180,173,179
	fcb 180,196,203
	fcb 181,227,229
	fcb 181,230,232
	fcb 183,210,216
	fcb 184,196,199
	fcb 184,200,203
	fcb 184,209,216
	fcb 186,227,232
	fcb 187,32,48
	fcb 187,56,72
	fcb 188,1,11
	fcb 188,89,97
	fcb 188,120,130
	fcb 188,200,216
	fcb 189,199,217
	fcb 189,87,112
	fcb 189,112,132
horscr12
horscr13
horscr14
horscr15	fcb 0		; end of horizontal lines table
