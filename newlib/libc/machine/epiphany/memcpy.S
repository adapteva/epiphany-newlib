/*
 * Copyright (c) 2016 U.S. Army Research laboratory. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice,
 * this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 * this list of conditions and the following disclaimer in the documentation
 * and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 *
 * This software was developed by Brown Deer Technology, LLC. with Copyright
 * assigned to the US Army Research laboratory as required by contract.
 */

#include <machine/epiphany-asm.h>

	.file	"memcpy.S"
	.text
	.balign	8
	.global	SYM(memcpy)
	.type	SYM(memcpy), %function

SYM(memcpy):
	// @ r0: dst
	// @ r1: src
	// @ r2: nbytes
	mov	r54, r0
	mov	r55, r1 // this saves program space at cost of one instruction
	mov	r1, r2
	lsr	r3, r2, #3
	beq	.LByteHandler
	orr	r3, r0, r55
	lsl	r3, r3, #29 // No bytes, just double words
	beq	.LDwordHandler
	mov	r2, #8
	lsr	r3, r3, #29
	sub	r2, r2, r3 // Correction for misalignment (8-r3)
	eor	r3, r0, r55
	lsl	r3, r3, #29 // Can the array alignment be corrected?
	beq	.LByteHandler
	mov	r2, r1 // perform full misaligned copy (slow)
.LByteHandler:
	sub	r1, r1, r2
	b	.LSubtractByte
.LBloop:
	ldrb	r3, [r55], #1
	strb	r3, [r54], #1
.LSubtractByte:
	sub	r2, r2, #1
	bgte	.LBloop
.LDwordHandler:
	mov	r2, #7
	and	r2, r1, r2 // nbyte remainder
	lsr	r3, r1, #7 // Checking number dwords >= 16
	beq	.LDremainder
.LDstart:
	sub	r3, r3, #1
.rept	4 // Unroll loop 4 times
	ldrd	r56, [r55], #1
	ldrd	r58, [r55], #1
	ldrd	r60, [r55], #1
	ldrd	r62, [r55], #1
	strd	r56, [r54], #1
	strd	r58, [r54], #1
	strd	r60, [r54], #1
	strd	r62, [r54], #1
.endr
	bne	.LDstart
.LDremainder:
	lsl	r3, r1, #25
	lsr	r3, r3, #28
	beq	.LDdone
.LDloop:
	sub	r3, r3, #1
	ldrd	r56, [r55], #1
	strd	r56, [r54], #1
	bne	.LDloop
.LDdone:
	sub	r1, r2, #0
	bgt	.LByteHandler
	rts
	.size	SYM(memcpy), .-SYM(memcpy)
