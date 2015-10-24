# C Startup for EPIPHANY

# Copyright (c) 2011, Adapteva, Inc.
# All rights reserved.

# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#  * Redistributions of source code must retain the above copyright notice,
#    this list of conditions and the following disclaimer.
#  * Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
#  * Neither the name of Adapteva nor the names of its contributors may be
#    used to endorse or promote products derived from this software without
#    specific prior written permission.

# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

#include <machine/epiphany-asm.h>
#include "epiphany-asm-offsets.h"

// TODO: These should be defined in common header file
#define LOADER_BSS_CLEARED_FLAG 1
#define LOADER_CUSTOM_ARGS_FLAG 2

.macro	movw	rd,constant
	mov	\rd,%low(\constant)
	movt	\rd,%high(\constant)
.endm

.data
.section RESERVED_CRT0_DATA

.weak	SYM(__loader_flags)
.type	SYM(__loader_flags), @object
.balign 8
SYM(__loader_flags):
	.word	0
.size  SYM(__loader_flags), .-SYM(__loader_flags)

.weak	SYM(__loader_args_ptr)
.type	SYM(__loader_args_ptr), @object
.balign 8
SYM(__loader_args_ptr):
	.word	0
.size  SYM(__loader_args_ptr), .-SYM(__loader_args_ptr)

;; structure
;;	.word	0 ;; r0
;;	.word	0 ;; r1
;;	.word	0 ;; r2
;;	.word	0 ;; r3
;;	.word	SYM(main) ;; function
;;	.word	0 ;; upper 32 bits
;;	.word	0 ;; stack spill size (8-byte aligned)
;;	.word	0 ;; __pad
;;	.word	0 ;; stack spill ptr  (8-byte aligned)
;;	.word	0 ;; upper 32 bits
;;	TODO: Need to store return value

.text
.section IVT_RESET,"a",@progbits     ;
        .global _start;
        .type   _start, %function;
_start:
	b.l	_normal_start

.size  _start, .-_start


.section RESERVED_CRT0,"a",@progbits     ;

#The "main" C caller can be located in the externa memory
#  _epiphany_start should be called by register to avoid linker problem
.balign 4
.type   _normal_start, %function
_normal_start:
	movw	r3, _epiphany_start
	jalr	r3
.size  _normal_start, .-_normal_start


.section .text;
	.type   SYM(_epiphany_start), %function
	.balign  8
SYM(_epiphany_start):

	;; Initialise the stack pointer and frame pointer. Hopefully __stack
	;; is somewhere meaningful.
	movw	sp,__stack
	;; Save replace for now incase overlay test fails
	;; 	mov	fp,sp
	mov	fp, #0

	;; Check if we need to zero the data space. This is racy so normally the
	;; loader should do it.
	movw	r0,SYM(__loader_flags)
	ldr	r0,[r0]
	movw	r1,#LOADER_BSS_CLEARED_FLAG
	and	r0,r0,r1
	bne	bss_done

	movw	r0,__bss_start
	movw	r1,_end
	mov	r2,#0
	mov	r3,#0

	sub	r4,r1,r0
	blte	bss_done

bss_loop:
	strd	r2,[r0],+#1
	sub	r4,r1,r0
	bgt	bss_loop
bss_done:

	;;  Setup destructors to be called from exit if main never returns
#if 0
	movw	r0,SYM(_fini)
	movw	r2,_atexit
	jalr r2
#else
	; calling atexit drags in malloc, so instead poke the function
	; address directly into the reent structure
	movw	r2,SYM(_impure_ptr)
	ldr	r2,[r2]
	movw	r1,SYM(_fini)
	add	r3,r2,#offsetof__reent__atexit0
	add	r0,r2,#offsetof__reent__atexit
	str	r3,[r0]
	mov	r0,#1
	mov	r2,r3
	add	r3,r2,#offsetof__atexit__ind
	str	r0,[r3]
	add	r3,r2,#offsetof__atexit__fns
	str	r1,[r3]
#endif /* !0 */

	;;mask all interrupts except sync
	mov	r0,#0xfffe
	movts	imask,r0

	;;return from reset ISR
	movw	r0,RDS
	movts	iret,r0
	rti
RDS:

	;; Call global and static constructors
	movw	r2,SYM(_init)
	jalr	r2

	;; Check if the loader has custom args
	movw	r0,SYM(__loader_flags)
	ldr	r0,[r0]
	movw	r1,#LOADER_CUSTOM_ARGS_FLAG
	and	r0,r0,r1
	beq	std_call
custom_call:
	movw	r8,SYM(__loader_args_ptr)
	ldr	r8,[r8]
	ldr	r0,[r8],+#1 ;; r0
	ldr	r1,[r8],+#1 ;; r1
	ldr	r2,[r8],+#1 ;; r2
	ldr	r3,[r8],+#1 ;; r3
	ldr	r4,[r8],+#1 ;; function ptr
	add	r8,r8,#4    ;;     upper 32 bits
	ldr	r5,[r8],+#1 ;; stack spill size (8-byte aligned)
	add	r8,r8,#4    ;;     padding (reserved, must be 0)
	ldr	r6,[r8],+#1 ;; stack spill ptr  (8-byte aligned)
	add	r8,r8,#4    ;;     upper 32 bits

	sub	r5,r5,#0
	beq	go
	sub	sp,sp,r5
	mov	r7,sp
	sub	sp,sp,#8 ;; ???: seem right
stack_args_loop:
	ldrd	r8,[r6],+#1
	sub	r5,r5,#8
	strd	r8,[r7],+#1
	bgt	stack_args_loop
	b go

std_call:
	;;  Initialise argc, argv and envp to empty and call main
	mov	r0,#0
	mov	r1,#0
	mov	r2,#0
	mov	r3,#0
	movw	r4,SYM(main)
go:
	jalr	r4
	;;bl	_main

	;; Call exit
	movw	r4,SYM(exit)
	jalr	r4
	;;bl	SYM(exit)

	;; Should never reach here
	idle

.size   SYM(_epiphany_start), .-SYM(_epiphany_start)
