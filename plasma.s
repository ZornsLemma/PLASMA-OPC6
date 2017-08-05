; Register use:
; R1 = expression stack pointer (full descending)
; R2 = heap pointer
; R3 = frame pointer
; R4 = bytecode instruction pointer
; R13 = stack pointer
; R14 = link register
	EQU restk,  1
	EQU rheap,  2
	EQU rifp,   3
	EQU rip,    4
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
	ld r10, rip
	and r10, r0, 0xff
	mov r10, r10, opcode_table
	
	jsr rlink, r10, opcode_table
	halt r0, r0, 0x42
	ld r10, rip

	pop rlink, rsp
	mov pc, rlink

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
	halt r0, r0, 0x99

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
saw:
dab:
daw:
	halt r0, r0, 0xffff


; Start executing compiled PLASMA code here
a1cmd:
	jsr rip, r0, interp
	; TODO: Some sort of byte-oriented equivalent of assembler directive WORD
	; !BYTE	$2C,$34,$12		; CW	4660
	; !BYTE	$7A,$00,$40		; SAW	16384
	; !BYTE	$00			; ZERO
	; !BYTE	$5C			; RET
	WORD 0x342c, 0x7a12, 0x4000, 0x5c00 

heap_start:
