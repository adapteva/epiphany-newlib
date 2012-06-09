/* Adapteva epiphany-core implementation of ISR support functions ()

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



/*
 * Signal functions implementation
 *
 */

#include <machine/epiphany_config.h>


#define HW_RESET 0
#define SW_EXCEPTION_IVT_N 1
#define PAGE_MISS_IVT_N 2
#define TIMER0_IVT_N 3
#define TIMER1_IVT_N 4
#define MESSAGE_IVT_N 5
#define DMA0_IVT_N 6
#define DMA1_IVT_N 7
#define WAND_IVT_N 8
#define USR_SOFT_IVT_N 9


typedef void (*sighandler_t)(int);
void DEFAULT_ISR_CALLBACK(int signum) {
	//do nothing
}
inline void TRAP_FAIL(int signum) {
	__asm__ __volatile__ ("trap 5");
}


extern void epiphany_start(int);

sighandler_t ISR_VECTOR[] __attribute__ ((section ("reserved_crt0"))) = {
		epiphany_start,
		TRAP_FAIL,
		DEFAULT_ISR_CALLBACK,
		DEFAULT_ISR_CALLBACK,
		DEFAULT_ISR_CALLBACK,
		DEFAULT_ISR_CALLBACK,
		DEFAULT_ISR_CALLBACK,
		DEFAULT_ISR_CALLBACK,
		DEFAULT_ISR_CALLBACK,
		DEFAULT_ISR_CALLBACK
};

void __attribute__ ((section ("RESERVED_CRT0"))) __attribute__((interrupt("software_exception","page_miss","dma0","dma1","message","timer0","timer1","swi")))
		isr_dispatcher (void) {
	volatile register unsigned ipend_val;
	unsigned isr_num=0;

	__asm__ __volatile__ ("movfs  %0 , ipend"  : "=r" (ipend_val) : );

	//detect current ISR: lsb in ipend
	while(ipend_val!=0) {
		ipend_val = ipend_val << 1;
		isr_num++;
	}
	isr_num = 32 - isr_num;
	if(isr_num < ((sizeof(ISR_VECTOR))>>2)) {
		ISR_VECTOR[isr_num](isr_num);
	} else {
		TRAP_FAIL(isr_num);
	}
}


sighandler_t __attribute__ ((section ("libgloss_epiphany")))  signal(int signum, sighandler_t handler) {

	volatile register unsigned imask_val;
	//the crt0 masks all interrupts, the signal will unmask the corresponding bit
	__asm__ __volatile__ ("movfs  %0 , imask"  : "=r" (imask_val) : );

	switch( signum )
	{
	case SIG_DFL /* see signal.h */:
		//the default is ignore
		return 0;
	case SIG_IGN /* see signal.h */ :
		DEFAULT_ISR_CALLBACK(SIG_IGN);//just to make calling convention for providing the argument for sighandler_t
		return 0;
	case SIG_ERR :
		asm("trap 5");
		break;
	case SIG_RESET:
		ISR_VECTOR[HW_RESET] = handler;
		//non maskable
		break;
	case SIG_SW_EXCEPTION:
		ISR_VECTOR[SW_EXCEPTION_IVT_N] = handler;
		//non maskable
		break;
	case SIG_PAGE_MISS:
		ISR_VECTOR[PAGE_MISS_IVT_N] = handler;
		imask_val = imask_val & (~(1<<PAGE_MISS_IVT_N));
		break;
	case SIG_TIMER0:
		ISR_VECTOR[TIMER0_IVT_N] = handler;
		imask_val = imask_val & (~(1<<TIMER0_IVT_N));
		break;
	case SIG_TIMER1:
		ISR_VECTOR[TIMER1_IVT_N] = handler;
		imask_val = imask_val & (~(1<<TIMER1_IVT_N));
		break;
	case SIG_MESSAGE:
		ISR_VECTOR[MESSAGE_IVT_N] = handler;
		imask_val = imask_val & (~(1<<MESSAGE_IVT_N));
		break;
	case SIG_DMA0:
		ISR_VECTOR[DMA0_IVT_N] = handler;
		imask_val = imask_val & (~(1<<DMA0_IVT_N));
		break;
	case SIG_DMA1:
		ISR_VECTOR[DMA1_IVT_N] = handler;
		imask_val = imask_val & (~(1<<DMA1_IVT_N));
		break;
	case SIG_WAND:
		ISR_VECTOR[WAND_IVT_N] = handler;
		imask_val = imask_val & (~(1<<WAND_IVT_N));
		break;

	case SIG_USR1:
		ISR_VECTOR[USR_SOFT_IVT_N] = handler;
		imask_val = imask_val & (~(1<<USR_SOFT_IVT_N));

		break;
	default:
		//do nothing
		return 0;
	}
	__asm__ __volatile__ ("movts   imask , %0"  : : "r" (imask_val)  );

	return 0;
}

