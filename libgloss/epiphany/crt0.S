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

.macro	movw	rd,constant
	mov	\rd,%low(\constant)
	movt	\rd,%high(\constant)
.endm

.section IVT_RESET,"a",@progbits     ;
        .global _start;
        .type   _start, %function;
_start:
		.balign 4 ;
         b .normal_start

.size  _start, .-_start

.section RESERVED_CRT0,"a",@progbits     ;

#The "main" C caller can be located in the externa memory
#  _epiphany_start should be called by register to avoid linker problem
.global .normal_start;
.balign 4
.type   .normal_start, %function
.normal_start:
	mov  r3,%low(_epiphany_start)
	movt r3,%high(_epiphany_start)
	jalr r3
.size  .normal_start, .-.normal_start


.section .text;
	.org    0x0000                  ; Relative to start of text section
	.global SYM(_epiphany_start)
	.type   SYM(_epiphany_start), %function
SYM(_epiphany_start):

	.align  4

	;; Initialise the stack pointer and frame pointer. Hopefully __stack
	;; is somewhere meaningful.
	movw	sp,__stack
	;; Save replace for now incase overlay test fails
	;; 	mov	fp,sp
	mov fp, #0

	;; Zero the data space
	;; TODO: Everyone else have use __bss_start
	mov	r0,%low(___bss_start)
	movt	r0,%high(___bss_start)
	mov	r1,%low(_end)
	movt	r1,%high(_end)
	mov	r2,#0
	mov	r3,#0
.L0_init_:
	strd	r2,[r0],+#1
	sub	r5,r1,r0
	bne	.L0_init_

	;;  Setup destructors to be called from exit if main never returns
#if 0
	mov	r0,%low(SYM(_fini))
	movt	r0,%high(SYM(_fini))
	mov r2,%low(_atexit)
	movt r2,%high(_atexit)
	jalr r2
#else
	; calling atexit drags in malloc, so instead poke the function
	; address directly into the reent structure
	mov	r2,%low(SYM(_impure_ptr))
	movt	r2,%high(SYM(_impure_ptr))
	ldr	r2,[r2]
	mov	r1,%low(SYM(_fini))
	movt	r1,%high(SYM(_fini))
	add	r3, r2, offsetof__reent__atexit0
	add	r0, r2, offsetof__reent__atexit
	str	r3, [r0]
	mov	r0, 1
	mov	r2, r3
	add	r3, r2, offsetof__atexit__ind
	str	r0, [r3]
	add	r3, r2, offsetof__atexit__fns
	str	r1, [r3]

#endif /* !0 */
	;; Call global and static constructors
	mov r2,%low(SYM(_init))
	movt r2,%high(SYM(_init))
	jalr r2

	;;mask all Interrupts
	mov R0,#0xfffe
	movts IMASK,R0

	;;return from reset ISR
	mov R0,%low(RDS)
	movt R0,%high(RDS)
	movts iret,r0
	rti
RDS:

	;;  Initialise argc, argv and envp to empty and call main
	mov	r0,#0
	mov	r1,#0
	mov	r2,#0
	mov r3,%low(SYM(main))
	movt r3,%high(SYM(main))
	jalr r3
	;;bl	_main

	;; Call exit
	mov r3,%low(SYM(exit))
	movt r3,%high(SYM(exit))
	jalr r3
	;;bl	_exit

	;; Should never reach here
	idle

.size   SYM(_epiphany_start), .-SYM(_epiphany_start)
