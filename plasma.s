; Register use:
; R1 = expression stack pointer
; R2 = heap pointer
; R3 = frame pointer
; R4 = bytecode instruction pointer (word)
; R5 = bytecode instruction pointer (byte within word)
; R13 = stack pointer
; R14 = link register
	EQU restk,  1
	EQU rheap,  2
	EQU rifp,   3
	EQU ripw,   4
	EQU ripb,   5
	EQU rsp,   13
	EQU rlink, 14

	EQU expression_stack_top, 0x0200
	EQU plasma_data, 0x8000
	EQU stack_top, 0xf000

	ORG 0x0000
	mov pc, r0, vminit

	ORG 0x0200
vminit:
	mov restk, r0, expression_stack_top
	mov rheap, r0, heap_start
	mov rsp, r0, stack_top
	jsr rlink, r0, a1cmd
	halt r0, r0, 0x999

interp:
	push rlink, rsp
	mov ripb, r0, 0			# First opcode in a function is always byte 0
interp_loop:
	; Get the next opcode byte into r10
	ld r10, ripw
	mov ripb, ripb
	z.mov pc, r0, interp_even
	bswp r10, r10
interp_even:
	and r10, r0, 0xff
	; Get the address of the corresponding opcode handler. We need to shift the
	; opcode byte right one bit to get a valid index into our word-addressed
	; opcode table.
	lsr r10, r10
	ld r10, r10, opcode_table
	; Transfer control to the handler. 
	; TODO: We could probably just do this with mov pc, r10 and have the handler
	; jump back to the relevant point in the interpreter - but let's do it like
	; this for now until things take shape. (This would avoid the need for the
	; handlers to have to stack rlink.)
	jsr rlink, r10
	;halt r0, r0, 0x300
	; The handler will have updated ripw/ripb, so interpret the next opcode.
	mov pc, r0, interp_loop

opcode_table:
	WORD	zero,add,sub,mul,div,mod,incr,decr 		# 00 02 04 06 08 0A 0C 0E
	WORD	neg,comp,band,ior,xor,shl,shr,idxw		# 10 12 14 16 18 1A 1C 1E
	WORD	lnot,lor,land,la,lla,cb,cw,cs			# 20 22 24 26 28 2A 2C 2E
	WORD	drop,dup,pushep,pullep,brgt,brlt,breq,brne	# 30 32 34 36 38 3A 3C 3E
	WORD	iseq,isne,isgt,islt,isge,isle,brfls,brtru	# 40 42 44 46 48 4A 4C 4E
	WORD	brnch,ibrnch,call,ical,enter,leave,ret,cffb	# 50 52 54 56 58 5A 5C 5E
	WORD	lb,lw,llb,llw,lab,law,dlb,dlw			# 60 62 64 66 68 6A 6C 6E
	WORD	sb,sw,slb,slw,sab,saw,dab,daw			# 70 72 74 76 78 7A 7C 7E

zero:
	push rlink, rsp
	push r0, restk
	; TODO: Probably better to use macro than subroutine
	jsr rlink, r0, inc_ip
	pop pc, rsp

add:
	push rlink, rsp
	pop r10, restk
	pop r11, restk
	add r10, r11
	push r10, restk
	jsr rlink, r0, inc_ip
	pop pc, rsp

cb:
	push rlink, rsp
	jsr rlink, r0, get_byte_operand
	push r10, restk
	pop pc, rsp

cw:
	push rlink, rsp
	; TODO: Might be better to use a macro to handle operand decoding but let's
	; favour simplicity over performance for now.
	jsr rlink, r0, get_word_operand
	push r10, restk
	pop pc, rsp

sab:
	push rlink, rsp
	jsr rlink, r0, get_word_operand
	pop r11, restk
	jsr rlink, r0, store_plasma_byte
	pop pc, rsp

saw:
	push rlink, rsp
	jsr rlink, r0, get_word_operand
	pop r11, restk
	; TODO: Macro instead of subroutine?
	jsr rlink, r0, store_plasma_word
	pop pc, rsp

lab:
	push rlink, rsp
	jsr rlink, r0, get_word_operand
	jsr rlink, r0, load_plasma_byte
	push r11, restk
	pop pc, rsp

law:
	push rlink, rsp
	jsr rlink, r0, get_word_operand
	; TODO: Macro instead of subroutine?
	jsr rlink, r0, load_plasma_word
	push r11, restk
	pop pc, rsp

ret:
	pop pc, rsp

	; Advance ripw/ripb by one byte.
inc_ip:
	add ripb, r0, 1
	cmp ripb, r0, 2
	nz.mov pc, rlink
	mov ripb, r0, 0
	add ripw, r0, 1
	mov pc, rlink

	; TODO: A lot of these subroutines are very free with their register use; this
	; is done to aid debugging, later on it may be useful to compress them.

	; ripw/ripb point at an opcode with a one-byte operand.
	; Advance ripw/ripb by 2 bytes and return with r10 containing the byte operand.
get_byte_operand:
	mov ripb, ripb
	z.mov pc, r0, get_byte_operand_high
	; ripb == 1, so the byte operand is the low byte of the OPC word at ripw+1
	add ripw, r0, 1
	ld r10, ripw
	and r10, r0, 0x00ff
	mov pc, rlink
get_byte_operand_high:
	; ripb == 0, so the byte operand is the high byte of the OPC word at ripw
	ld r10, ripw
	and r10, r0, 0xff00
	bswp r10, r10
	add ripw, r0, r1
	mov pc, rlink

	; ripw/ripb point at an opcode with a two-byte operand.
	; Advance ripw/ripb by 3 bytes and return with r10 containing the two-byte operand.
get_word_operand:
	mov ripb, ripb
	z.mov pc, r0, get_word_operand_split
	; ripb == 1, so the word operand is the OPC word at ripw+1
	add ripw, r0, 1
	ld r10, ripw
	add ripw, r0, 1
	mov ripb, r0, 0
	mov pc, rlink
get_word_operand_split:
	; ripb == 0, so the word operand low byte is the high byte of OPC word at ripw...
	ld r10, ripw
	and r10, r0, 0xff00
	; ... and the word operand high byte is the low byte of the OPC word at ripw+1
	add ripw, r0, 1
	ld r11, ripw
	and r11, r0, 0x00ff
	; Combine the two bytes into r10.
	or r10, r11
	bswp r10, r10
	mov ripb, r0, 1
	mov pc, rlink

	; Store byte in r11 at offset r10 in plasma_data
store_plasma_byte:
	lsr r12, r10
	ld r9, r12, plasma_data
	nc.mov pc, r0, store_plasma_byte_even
	bswp r9, r9
store_plasma_byte_even:
	and r11, r0, 0x00ff
	and r9, r0, 0xff00
	or r9, r11
	nc.mov pc, r0, store_plasma_byte_even2
	bswp r9, r9
store_plasma_byte_even2:
	sto r9, r12, plasma_data
	mov pc, rlink

	; Store word in r11 at offset r10 in plasma_data
store_plasma_word:
	lsr r12, r10
	c.mov pc, r0, store_plasma_word_split
	; TODO: We could make the next two instructions conditional on carry clear
	; and avoid the branch; not sure if that would be a performance gain or not.
	; r10 is even, so we can simply write to OPC word plasma_data[r12]
	sto r11, r12, plasma_data
	mov pc, rlink
store_plasma_word_split:
	; r10 is odd, so we need to split the write across two OPC words.
	; Write the low byte of r11 to the high byte of OPC word plasma_data[r12]
	ld r9, r12, plasma_data
	bswp r9, r9
	and r9, r0, 0xff00
	mov r8, r11
	and r8, r0, 0x00ff
	or r9, r8
	bswp r9, r9
	sto r9, r12, plasma_data
	; Write the high byte of r11 to the low byte of OPC word plasma_data[r12+1]
	add r12, r0, 1
	ld r9, r12, plasma_data
	bswp r9, r9
	and r9, r0, 0x00ff
	and r11, r0, 0xff00
	or r9, r11
	bswp r9, r9
	sto r9, r12, plasma_data
	mov pc, rlink

	; Load byte at offset r10 in plasma_data, returning it in r11
load_plasma_byte:
	lsr r12, r10
	c.mov pc, r0, load_plasma_byte_odd
	ld r11, r12, plasma_data
	and r11, r0, 0x00ff
	mov pc, rlink
load_plasma_byte_odd:
	ld r11, r12, plasma_data+1
	bswp r11, r11
	and r11, r0, 0x00ff
	mov pc, rlink

	; Load word at offset r10 in plasma_data, returning it in r11
load_plasma_word:
	lsr r12, r10
	c.mov pc, r0, load_plasma_word_split
	; TODO: Make next two instructions conditional to avoid branch?
	ld r11, r12, plasma_data
	mov pc, rlink
load_plasma_word_split:
	; r10 is odd, so we need to split the read across two OPC words.
	ld r9, r12, plasma_data
	and r9, r0, 0xff00
	; TODO: Not just here - can we merge next two into 'ld r11, r12, plasma_data+1'?
	add r12, r0, 1
	ld r11, r12, plasma_data
	and r11, r0, 0x00ff
	or r11, r9
	bswp r11, r11
	mov pc, rlink

sub:
mul:
div:
mod:
incr:
decr:
neg:
comp:
band:
ior:
xor:
shl:
shr:
idxw:
lnot:
lor:
land:
la:
lla:
cs:
drop:
dup:
pushep:
pullep:
brgt:
brlt:
breq:
brne:
iseq:
isne:
isgt:
islt:
isge:
isle:
brfls:
brtru:
brnch:
ibrnch:
call:
ical:
enter:
leave:
cffb:
lb:
lw:
llb:
llw:
dlb:
dlw:
sb:
sw:
slb:
slw:
dab:
daw:
	halt r0, r0, 0xffff


; Start executing compiled PLASMA code here
a1cmd:
	jsr ripw, r0, interp
	; !BYTE	$2C,$34,$12		; CW	4660
	; !BYTE	$7A,$00,$40		; SAW	16384
	; !BYTE	$2C,$89,$67		; CW	26505
	; !BYTE	$7A,$03,$40		; SAW	16387
	; !BYTE	$6A,$00,$40		; LAW	16384
	; !BYTE	$6A,$03,$40		; LAW	16387
	; !BYTE	$02			; ADD
	; !BYTE	$7A,$00,$40		; SAW	16384
	; !BYTE	$68,$00,$40		; LAB	16384
	; !BYTE	$2A,$0A			; CB	10
	; !BYTE	$02			; ADD
	; !BYTE	$78,$05,$40		; SAB	16389
	; !BYTE	$00			; ZERO
	; !BYTE	$5C			; RET
	; TODO: For the moment, all but the last BYTE directive must have an even
	; TODO: number of bytes in it to avoid padding.
	BYTE 0x2c, 0x34, 0x12, 0x7a, 0x00, 0x40, 0x2c, 0x89, 0x67, 0x7a, 0x03, 0x40
	BYTE 0x6a, 0x00, 0x40, 0x6a, 0x03, 0x40, 0x02, 0x7a, 0x00, 0x40, 0x68, 0x00
	BYTE 0x40, 0x2a, 0x0a, 0x02, 0x78, 0x05, 0x40, 0x00, 0x5c

heap_start:
