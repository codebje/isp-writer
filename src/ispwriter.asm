.z180

#target bin

#include "z180registers.asm"
#include "bootbios.asm"

; There's only a CODE section just now
#code		CODE, $2000		; the binary image is loaded here

		ld	hl, message
		call	asci0_xmit

		; set MMU up for all RAM
		xor	a
		out0	(BBR), a
		out0	(CBR), a
		ld	a, $F0
		out0	(CBAR), a

		; copy the fill byte into place
		xor	a
		out0	(DAR0L), a
		out0	(DAR0H), a
		out0	(SAR0B), a
		out0	(BCR0H), a
		ld	a, $02
		out0	(DAR0B), a
		ld	bc, fill_byte
		out0	(SAR0L), c
		out0	(SAR0H), b
		ld	a, 1
		out0	(BCR0L), a
		ld	hl, 0110000000000010b
		out0	(DMODE), l
		out0	(DSTAT), h

		xor	a
		out0	(SAR0L), a
		out0	(SAR0H), a
		ld	a, 2
		out0	(SAR0B), a

		ld	a, $ff
		out0	(BCR0L), a
		out0	(BCR0H), a
		
		ld	b, 6
filler:		out0	(DSTAT), h
		djnz	filler

		; patch everything to pretend the ROM is at $10000 not $80000
		ld	a, 1
		ld	($0157 + patch_start), a
		ld	($02b6 + patch_start), a
		ld	($1cac + patch_start), a
		ld	($1d7a + patch_start), a

		; copy the boot ROM to $10000
		xor	a
		out0	(DAR0L), a
		out0	(DAR0H), a
		out0	(SAR0B), a
		inc	a
		out0	(DAR0B), a
		ld	bc, patch_start
		out0	(SAR0L), c
		out0	(SAR0H), b
		ld	bc, patch_size
		out0	(BCR0L), c
		out0	(BCR0H), b
		ld	bc, 0110000000000010b
		out0	(DMODE), c
		out0	(DSTAT), b		; burst mode, pow!

		; copy the BIOS and friends from $10572 to $0e000 and boot from there
		xor	a
		out0	(DAR0B), a
		out0	(DAR0L), a
		ld	a, $e0
		out0	(DAR0H), a
		ld	a, $01
		out0	(SAR0B), a
		ld	bc, $572
		out0	(SAR0L), c
		out0	(SAR0H), b
		ld	bc, $2000 - $572
		out0	(BCR0L), c
		out0	(BCR0H), b
		ld	bc, 0110000000000010b
		out0	(DMODE), c
		out0	(DSTAT), b		; burst mode, bam!

		ld	sp, $d000		; fix SP to something safer than the middle of the BIOS

		jp	$f6e4			; cold boot entry point

fill_byte	.db	$e5
message		.text	13, 10, 'CPM-enabled BIOS patched', 13, 10, 0

patch_start	equ	$

#insert		"../../bootrom/bin/bootrom.bin"

patch_size	equ	$ - patch_start
		.dephase

