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

		; erase the RAM disk
		xor	a
		out0	(DAR0L), a
		out0	(DAR0H), a
		out0	(SAR0B), a
		ld	a, $02
		out0	(DAR0B), a
		ld	bc, fill_byte
		out0	(SAR0L), c
		out0	(SAR0H), b
		ld	bc, 0
		out0	(BCR0L), c
		out0	(BCR0H), b
		ld	bc, 0110000000001010b
		out0	(DMODE), c
		out0	(DSTAT), b		; 64k filled
		out0	(DSTAT), b		; 128k filled
		out0	(DSTAT), b		; 192k filled
		out0	(DSTAT), b		; 256k filled
		out0	(DSTAT), b		; 320k filled
		out0	(DSTAT), b		; 384k filled

		; copy the ROM disk to $10000
		xor	a
		out0	(DAR0L), a
		out0	(DAR0H), a
		out0	(SAR0B), a
		inc	a
		out0	(DAR0B), a
		ld	bc, $2200 + patch_start
		out0	(SAR0L), c
		out0	(SAR0H), b
		ld	bc, 32768
		out0	(BCR0L), c
		out0	(BCR0H), b
		ld	bc, 0110000000000010b
		out0	(DMODE), c
		out0	(DSTAT), b		; burst mode, pow!

		; patch the BIOS for ROM disk and "ROM" CPM/BIOS
		xor	a			; CPM now lives at $0c000 not $805b1
		ld	($1c4d + patch_start), a
		ld	($1c56 + patch_start), a
		ld	a, $c0
		ld	($1c4e + patch_start), a

		xor	a			; ROM disk now lives at $10000
		ld	($1d26 + patch_start), a
		inc	a
		ld	($1d27 + patch_start), a

		; copy the BIOS and friends to $c000
		xor	a
		out0	(SAR0B), a
		out0	(DAR0B), a
		out0	(DAR0L), a
		ld	a, $c0
		out0	(DAR0H), a
		ld	bc, patch_start + $5b1
		out0	(SAR0L), c
		out0	(SAR0H), b
		ld	bc, $2000
		out0	(BCR0L), c
		out0	(BCR0H), b
		ld	bc, 0110000000000010b
		out0	(DMODE), c
		out0	(DSTAT), b		; burst mode, bam!

		; warm-boot the CPM bios
		jp	$D671			; cold boot entry point

fill_byte	.db	$e5
message		.text	13, 10, 'CPM-enabled BIOS patched', 13, 10, 0

patch_start	equ	$

#insert		"../../bootrom/bin/bootrom.bin"

patch_size	equ	$ - patch_start
		.dephase

