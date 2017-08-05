; Register use:
; R1 = expression stack pointer (full descending)
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
	; this for now until things take shape.
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

cw:
	push rlink, rsp
	; TODO: Might be better to use a macro to handle operand decoding but let's
	; favour simplicity over performance for now.
	jsr rlink, r0, get_word_operand
	push r10, restk
	pop pc, rsp

saw:
	halt r0, r0, 0x400

	; ripw/ripb point at an opcode with a two-byte operand.
	; Advance ripw/ripb by 3 bytes and return with r10 containing the two-byte operand
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
	or r10, r11
	bswp r10, r10
	mov ripb, r0, 1
	mov pc, rlink

zero:
add:
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
cb:
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
ret:
cffb:
lb:
lw:
llb:
llw:
lab:
law:
dlb:
dlw:
sb:
sw:
slb:
slw:
sab:
dab:
daw:
	halt r0, r0, 0xffff


; Start executing compiled PLASMA code here
a1cmd:
	jsr ripw, r0, interp
	; TODO: Some sort of byte-oriented equivalent of assembler directive WORD
	; !BYTE	$2C,$34,$12		; CW	4660
	; !BYTE	$7A,$00,$40		; SAW	16384
	; !BYTE	$00			; ZERO
	; !BYTE	$5C			; RET
	WORD 0x342c, 0x7a12, 0x4000, 0x5c00 

heap_start:
