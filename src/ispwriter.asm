.z180

#target bin

#include "z180registers.asm"
#include "bootbios.asm"

; There's only a CODE section just now
#code		CODE, $2000		; the binary image is loaded here

		;.org	$2000

		; copy the patch to $1100
		ld	hl, patch_start
		ld	de, $1100
		ld	bc, patch_size
		ldir

		; patch recv_packet to jump to replacement
		ld	a, $c3
		ld	(recv_packet), a
		ld	bc, recv_packet_2
		ld	(recv_packet+1), bc

		ld	hl, message
		call	asci0_xmit

		; test ym_crc
		ld	hl, message
		ld	bc, 10
		call	ym_crc
		ld	bc, de
		ld	a, b
		call	bin_to_hex
		ld	(binhex), de
		ld	a, c
		call	bin_to_hex
		ld	(binhex+2), de
		ld	hl, binhex
		call	asci0_xmit

		; go back to the boot menu
		ret

message		.text	13, 10, 'Y-modem patch rev. D installed', 13, 10, 0
binhex		.text	'????', 13, 10, 0

		.phase	$1100

patch_start:	equ	$$

YM_SOH		equ	$01		; start of a 128-byte packet
YM_STX		equ	$02		; start of a 1024-byte packet
YM_EOT		equ	$04		; end of transmission
YM_ACK		equ	$06		; received ok
YM_NAK		equ	$15		; receive error
YM_CAN		equ	$18		; cancel transmission
YM_CRC		equ	'C'		; request CRC-16 mode

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; recv_packet
;;
;; Receive a Y-Modem packet, retrying up to ten times.
;;
;; in:		hl	destination of packet (1026 bytes required)
;; 		c	the byte to send in case of timeout
;; out:		zf	set on error
;;		a	the command code received
;;		c	the packet sequence number
;		b	the number of retries remaining
#local
recv_packet_2::	push	de
		push	hl

		ld	a, c
		ld	(metadata+1), a

		ld	b, 10		; retry ten times
		jr	read_cmd

metadata:	ld	a, 0
		call	send_byte

read_cmd:	ld	de, 5*100
		call	recv_byte
		jr	z, retry

		cp	a, YM_CAN	; Cancel?
		jr	z, cancel

		cp	a, YM_EOT	; End of transmission?
		jr	z, eot

		cp	a, YM_SOH
		jr	z, recv_body

		cp	a, YM_STX
		jr	z, recv_body

		call	flush_rx	; anything else, clear it out and retry

retry:		djnz	metadata
		xor	a		; djnz doesn't set zf, so setit here

done:		pop	hl
		pop	de
		ret

cancel:		ld	de, 5*100
		call	recv_byte
		jr	z, retry
		cp	a, YM_CAN
		jr	z, done
		jr	retry

eot:		or	a		; clear zf - a contains a non-zero value
		jr	done

recv_body:	ld	(cmd), a
		ld	de, 1*100
		call	recv_byte
		jr	z, retry
		ld	c, a
		call	recv_byte
		jr	z, retry
		cpl
		cp	a, c
		jr	nz, retry
		ld	(seq), a

		push	hl
		push	bc

		ld	bc, 130
		ld	a, (cmd)
		cp	a, YM_SOH
		jr	z, $+5
		ld	bc, 1026

		push	hl
		push	bc

		ld	de, 1*100
		call	recv_wait

		pop	bc
		pop	hl

		jr	z, retry_

		call	ym_crc		; CRC should be zero

		pop	bc
		pop	hl

		ld	a, d
		or	e
		jr	nz, retry
		ld	a, (seq)
		ld	c, a
		ld	a, (cmd)
		or	a		; clear zf
		jr	done

retry_:		pop	bc
		pop	hl
		jr	retry

cmd:		.db	0
seq:		.db	0
crcmsg		.text   13,10,"CRC: "
crcval		.text	'????',13,10,0
#endlocal

#local
print_packet::	push	af
		push	bc
		push	de
		push	hl

		ld	hl, packet_hdr
		call	asci0_xmit
		pop	hl
		push	hl

		ld	a, h
		call	print_hex
		ld	a, l
		call	print_hex

		call	newline

		;; print 130 bytes at (hl) in 8 rows of 16 plus 2 spare
		ld	b, 8
lines:		push	bc
		ld	b, 16
bytes:		ld	a, (hl)
		inc	hl
		call	print_hex
		ld	a, ' '
		call	send_byte
		djnz	bytes
		call	newline
		pop	bc
		djnz	lines

		ld	a, (hl)
		inc	hl
		call	print_hex

		ld	a, (hl)
		inc	hl
		call	print_hex

		call	newline

		pop	hl
		pop	de
		pop	bc
		pop	af
		ret
packet_hdr	.text	13,10,'HL = ',0

newline:	push	af
		ld	a, 13
		call	send_byte
		ld	a, 10
		call	send_byte
		pop	af
		ret

print_hex:	push	af
		push	de
		call	bin_to_hex
		ld	a, e
		call	send_byte
		ld	a, d
		call	send_byte
		pop	de
		pop	af
		ret
#endlocal

patch_size	equ	$$ - patch_start
		.dephase

