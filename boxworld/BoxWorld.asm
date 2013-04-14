;+------------------------------------------------------+
;|			Box World v1.1			|
;|		     by Joe Wingbermuehle		|
;|		   12-05-1997 <> 06-08-1998		|
;+------------------------------------------------------+
.nolist
#include	"joeti83.inc"
#include	"sos.inc"
.org		$9327
.list

;---------- Variables ----------
#define	loc		sram+$00	; location of '+'
#define lev		sram+$02	; current level
#define	posr		sram+$03	; temporary currow var
#define	posc		sram+$04	; temporary curcol var
#define levnum		sram+$05	; number of levels
#define file		sram+$06	; level data file ptr
#define	curfat		sram+$08	; current fat ptr
#define level		sram+$0A	; current level matrix (128 bytes)

detect_file		=vector0
decompress_level	=vector1


	ccf
	jr	z,start_of_program
	.dw	libraries-$9327
	.dw	sos_description
start_of_program:

;---------- Setup the game -----------
	xor	a
	ld	(levnum),a
first_world:
	ld	hl,(fat)
	ld	(curfat),hl
next_world:
	call	clrscr
	ld	hl,$0202
	ld	(currow),hl
	ld	hl,info1
	call	putps
	ld	hl,$0503
	ld	(currow),hl
	ld	hl,info2
	call	puts
	ld	de,$0204
	ld	(currow),de
	call	puts
	ld	de,$0007
	ld	(currow),de
	call	puts
;-----> Find a level
	ld	ix,detect_string
	ld	hl,(curfat)
	call	detect_file
	jr	z,file_found
	ld	a,(levnum)
	or	a
	jr	nz,first_world
	ret	; exit if no files found
file_found:
	call	puts
	ld	a,(hl)
	ld	(levnum),a
	inc	hl
	ld	(file),hl
	ld	(curfat),de
	ld	a,1
	ld	(lev),a
	call	wait_key
	cp	55
	jr	z,next_world

;---------- Load a level ----------
;Level data format:
; 4 blocks to the byte
; 8*16=128; 128/4=32; 32+2=34
; 34 bytes per level
; %00 = nothing
; %01 = wall
; %10 = dot
; %11 = ':'
; last 2 bytes: +x, +y

start:	ld	hl,(file)
	ld	de,-34
	add	hl,de
	ld	de,34
	ld	a,(lev)
find_level:
	add	hl,de
	dec	a
	jr	nz,find_level
	ld	de,level
	push	de
	ld	bc,32*256+3
	call	decompress_level
	ld	a,(hl)
	ld	(posc),a
	inc	hl
	ld	a,(hl)
	ld	(posr),a
	pop	hl
	ld	b,128
setup_loop:
	ld	a,(hl)
	or	a
	jr	nz,setup_s1
	ld	(hl),' '	; space
	jr	setup_s4
setup_s1:
	dec	a
	jr	nz,setup_s2
	ld	(hl),'ñ'	; wall
	jr	setup_s4
setup_s2:
	dec	a
	jr	nz,setup_s3
	ld	(hl),'Ð'	; dot
	jr	setup_s4
setup_s3:
	ld	(hl),':'	; colon
setup_s4:
	inc	hl
	djnz	setup_loop
	ld	hl,(posr)
	ld	b,l
	ld	e,$10
	xor	a
lsl3:	add	a,e
	djnz	lsl3
	add	a,h
	ld	l,a
	ld	h,$00
	ld	(loc),hl

;---------- Draw the level ----------
	call	homeup
	ld	hl,level
	ld	b,$7F
dloop:	ld	a,(hl)
	call	putc
	inc	hl
	djnz	dloop
	ld	a,(hl)
	call	putmap
	ld	hl,(posr)
	ld	(currow),hl
	ld	a,'+'
	call	putmap

;---------- Main program loop ----------
main:	call	getk
	dec	a
	jp	z,mDown
	dec	a
	jp	z,mLeft
	dec	a
	jr	z,mRight
	dec	a
	jp	z,mUp
	sub	10-4
	jp	z,levup
	dec	a
	jp	z,levdwn
	cp	15-11
	jp	z,start
	cp	56-11
	ret	z
	jr	main

;---------- Move right ----------
mRight:	call		align
	inc		de
	ld		(loc),de
	ld		a,(hl)
	call		putc
	ld		a,'+'
	call		putmap
	call		align
	ld		a,(hl)
	cp		'ñ'
	jp		z,mLeft
	cp		'Ð'
	jr		z,mor
	jp		main
mor:	call		align
	inc		hl
	ld		a,(hl)
	cp		':'
	jr		z,mrcn1
	cp		' '
	jp		nz,mLeft
	ld		a,'Ð'
	ld		(hl),a
mrcn1:	dec		hl
	ld		a,' '
	ld		(hl),a
	ld	hl,curcol
	inc	(hl)
	call		align
	inc		hl
	ld		a,(hl)
	cp		':'
	jr		z,mrcn2
	ld		a,'Ð'
	call		putmap
mrcn2:	ld	hl,curcol
	dec	(hl)
	jp		winc

;---------- Move left ----------
mLeft:	ld	hl,curcol
	dec	(hl)
	ld		a,'+'
	call		putc
	call		align
	dec		de
	ld		(loc),de
	ld		a,(hl)
	call		putmap
	ld	hl,curcol
	dec	(hl)
	call		align
	ld		a,(hl)
	cp		'ñ'
	jp		z,mRight
	cp		'Ð'
	jr		z,mol
	jp		main
mol:	call		align
	dec		hl
	ld		a,(hl)
	cp		':'
	jr		z,mlcn1
	cp		' '
	jp		nz,mRight
	ld		a,'Ð'
	ld		(hl),a
mlcn1:	inc		hl
	ld		a,' '
	ld		(hl),a
	ld	hl,curcol
	dec	(hl)
	call		align
	dec		hl
	ld		a,(hl)
	cp		':'
	jr		z,mlcn2
	ld		a,'Ð'
	call		putmap
mlcn2:	ld	hl,curcol
	inc	(hl)
	jp		winc

;---------- Move up ----------
mUp:	call		align
	ld		a,(hl)
	call		putmap
	ld	hl,currow
	dec	(hl)
	ld		hl,(loc)
	ld		bc,$0010
	sbc		hl,bc
	ld		(loc),hl
	ld		a,'+'
	call		putmap
	call		align
	ld		a,(hl)
	cp		'ñ'
	jp		z,mDown
	cp		'Ð'
	jr		z,moup
	jp		main
moup:	call		align
	ld		bc,$0010
	sbc		hl,bc
	ld		a,(hl)
	cp		':'
	jr		z,mucn1
	cp		' '
	jp		nz,mDown
	ld		a,'Ð'
	ld		(hl),a
mucn1:	push	hl
	ld		bc,$0010
	add		hl,bc
	ld		a,' '
	ld		(hl),a
	ld	hl,currow
	dec	(hl)
	pop	hl
	ld		a,(hl)
	cp		':'
	jr		z,mucn2
	ld		a,'Ð'
	call		putmap
mucn2:	ld	hl,currow
	inc	(hl)
	jp		winc

;---------- Move down ----------
mDown:	call		align
	ld		a,(hl)
	call		putmap
	ld	hl,currow
	inc	(hl)
	ld		hl,(loc)
	ld		bc,$0010
	add		hl,bc
	ld		(loc),hl
	ld		a,'+'
	call		putmap
	call		align
	ld		a,(hl)
	cp		'ñ'
	jp		z,mUp
	cp		'Ð'
	jr		z,modwn
	jp		main
modwn:	call		align
	ld		bc,$0010
	add		hl,bc
	ld		a,(hl)
	cp		':'
	jr		z,mdcn1
	cp		' '
	jp		nz,mUp
	ld		a,'Ð'
	ld		(hl),a
mdcn1:	call		align
	ld		a,' '
	ld		(hl),a
	push	hl
	ld	hl,currow
	inc	(hl)
	pop	hl
	ld	bc,$0010
	add	hl,bc
	ld	a,(hl)
	cp	':'
	jr	z,mdcn2
	ld	a,'Ð'
	call	putmap
mdcn2:	ld	hl,currow
	dec	(hl)
	jp		winc

;---------- Point hl to level matrix element ----------
align:	ld	de,(loc)
	ld	hl,level
	add	hl,de
	ret

;---------- Move up/down a level ----------
levdwn:	; move down a level
	ld	a,(lev)
	dec	a
	jr	z,lev_exit
	jr	lev_set
levup:	; move up a level
	ld	bc,(levnum)
	ld	a,(lev)
	cp	c
	jr	z,lev_exit
	inc	a
lev_set:
	ld	(lev),a
lev_exit:
	jp	start

;---------- Winner? ----------
winc:	ld	hl,level
	ld	b,128
wincl:	ld	a,(hl)
	cp	'Ð'
	inc	hl
	jp	z,main
	djnz	wincl
	ld	bc,(levnum)
	ld	hl,lev
	ld	a,(hl)
	inc	(hl)
	cp	c
	jr	z,winner
	set	3,(iy+5)
	ld	hl,$0303
	ld	(currow),hl
	ld	hl,level_text
	call	puts
	ld	hl,(lev)
	ld	h,0
	call	disphl
	call	wait_key
	res	3,(iy+5)
	jp	start
winner:	call	clrscr
	ld	hl,$0403
	ld	(currow),hl
	ld	hl,won
	call	putps	; fall through to wait_key

;---------= Wait for a key press =---------
wait_key:
	ld	b,25
wait_loop1:
	ei
	halt
	djnz	wait_loop1
wait_loop2:
	call	getk
	or	a
	jr	z,wait_loop2
	ret

;---------- Constants ----------
detect_string:
	.db	"BW1JW",0
info1:	.db	13
sos_description:
	.db	"BoxWorld v1.1 by Joe W"
	.db	0
info2:	.db	"by Joe",0
info3:	.db	"Wingbermuehle",0
info4:	.db	"Mode - ",0
won:	.db	$08,"You Won!"
level_text:
	.db	"Level:",0

libraries:
	.db	"ZLIB",0,0,0,0,lib4,vec0	; detect
	.db	"ZLIB",0,0,0,0,lib6,vec1	; decompress
	.db	$FF

.end
END