/* Adapteva epiphany-core implementation of stdio support functions ()

   Copyright (c) 2011, Adapteva, Inc.
   All rights reserved.

   Redistribution and use in source and binary forms, with or without
   modification, are permitted provided that the following conditions are met:
 * Redistributions of source code must retain the above copyright notice,
      this list of conditions and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
 * Neither the name of Adapteva nor the names of its contributors may be
      used to endorse or promote products derived from this software without
      specific prior written permission.

   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
   AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
   IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
   ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
   LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
   CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
   SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
   INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
   CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
   ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
   POSSIBILITY OF SUCH DAMAGE.                                               */

#include <errno.h>
#undef errno
extern int errno;

/* simple include interface to EPIPHANY trap instruction. */

/*
 * The simulator uses a trap instruction to escape to the simulator to do file i/o
 */

/*      trapcode             r0            r1             r2  */
#define TRAP_write 0  /*    channel        addr           len */
#define TRAP_read 1   /*    channel        addr           len */
#define TRAP_open 2   /*    filepath       mode               */
#define TRAP_exit 3   /*    status                            */
#define TRAP_pass 4   /*     -                                */
#define TRAP_fail 5   /*     -                                */
#define TRAP_close 6  /*    channel                           */
#define TRAP_other 7  /*    subcode        r1              r2 */


#include "epiphany-syscalls.h"


/* prototypical inline asm */

int __attribute__ ((section ("libgloss_epiphany")))  asm_write (int CHAN, void* ADDR, int LEN) {
	register int chan asm("r0") = CHAN;
	register void* addr asm("r1") = ADDR;
	register int len asm("r2") = LEN;
	register int result asm("r0");
	register int error asm("r3");
	asm ("trap 0" : "=r" (result), "=r" (error) :
			"r" (chan), "r" (addr), "r" (len));
	if (error)
		errno = error;
	return result;
}

int __attribute__ ((section ("libgloss_epiphany")))  asm_read(int CHAN, void *ADDR, int LEN) {
	register int chan asm("r0") = CHAN;
	register void* addr asm("r1") = ADDR;
	register int len asm("r2") = LEN;
	register int result asm("r0");
	register int error asm("r3");
	asm ("trap 1" : "=r" (result), "=r" (error) :
			"r" (chan), "r" (addr), "r" (len));
	if (error)
		errno = error;
	return result;
}


int __attribute__ ((section ("libgloss_epiphany"))) asm_open(const char* FILE, int FLAGS, int MODE) {
	register const char* file asm("r0") = FILE;
	register int flags asm("r1") = FLAGS;
	register int result asm("r0");
	register int error asm("r3");
	asm ("trap 2" : "=r" (result), "=r" (error) : "r" (file), "r" (flags));
	if (error)
		errno = error;
	return result;
}


void __attribute__ ((section ("libgloss_epiphany")))  asm_exit(int STATUS)	{
	register int status asm("r0") = STATUS;
	asm("trap 3" :: "r" (status));
}

int __attribute__ ((section ("libgloss_epiphany")))  asm_close(int CHAN) {
	register int chan asm("r0") = CHAN;
	register int result asm("r0");
	register int error asm("r3");
	asm ("trap 6" : "=r" (result), "=r" (error) : "r" (chan));
	if (error)
		errno = error;
	return result;
}

int __attribute__ ((section ("libgloss_epiphany")))  asm_syscall(void *P1,void *P2, void *P3, int SUBFUN) {
	register void* p1 asm("r0") = (void*)P1;
	register void* p2 asm("r1") = (void*)P2;
	register void* p3 asm("r2") = (void*)P3;
	register int result asm("r0");
	register int subfun asm("r3") = SUBFUN;
	register int error asm("r3");
	asm ("trap 7" : "=r" (result), "=r" (error) :
			"r" (p1), "r" (p2), "r" (p3), "r" (subfun));
	if (error)
		errno = error;
	return result;
}
