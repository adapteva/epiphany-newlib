/* Idea from: http://blackfin.uclinux.org/doku.php?id=toolchain:gas:structs */
#include <stddef.h>
#include <sys/reent.h>

#undef offsetof
#define offsetof(TYPE, MEMBER) ((size_t) &((TYPE *)0)->MEMBER)
#define SIZEOF(TYPE, MEMBER) (sizeof(((TYPE *)0)->MEMBER))

#define _DEFINE(sym, val) asm("\n#define " #sym " %0\n" : : "i" (val))
#define DEFINE(s, m) \
		_DEFINE(offsetof_##s##_##m, offsetof(s, m)); \
	_DEFINE(sizeof_##s##_##m, SIZEOF(s, m));

int main()
{
	typedef struct _reent _reent;
	typedef struct _atexit _atexit;
	DEFINE(_reent, _atexit);
	DEFINE(_reent, _atexit0);
	DEFINE(_atexit, _ind)
	DEFINE(_atexit, _fns);

	return 0;
}
