/* EPIPHANY implementation of _isatty ()

   Copyright (c) 2011, Adapteva, Inc.
   All rights reserved.

   Contributor Jeremy Bennett <jeremy.bennett@embecosm.com> for Adapteva Inc

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


/* ------------------------------------------------------------------------- */
/*!Query whether output stream is a terminal

   This is a slightly more than minimal implementation. Really we would like
   the simulator to tell us the answer, but for now we don't have a system
   call number to use

   So we assume that file descriptors 0, 1 and 2 are TTY and everything else
   is not.

   @todo Add a system call number for isatty.

   @param[in] filedes  The file descriptor to query

   @return  1 (TRUE) if this is a descriptor for a TTY, 0 (FALSE) otherwise. */
/* ------------------------------------------------------------------------- */
int __attribute__ ((section ("libgloss_epiphany")))
_isatty (int filedes)
{
  return (0 <= filedes) && (filedes <=2);

}	/* _isatty () */
