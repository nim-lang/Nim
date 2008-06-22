#include <unistd.h>
#include <stdlib.h>
#include <stdio.h>

/* A very simple profiler.  Note that it should be possible to	*/
/* get function level information by concatenating this with nm	*/
/* output and running the result through the sort utility.	*/
/* This assumes that all interesting parts of the executable	*/
/* are statically linked.					*/

static size_t buf_size;
static u_short *profil_buf;

# ifdef __i386__
#   ifndef COMPRESSION
#     define COMPRESSION 1
#   endif
#   define TEXT_START 0x08000000
#   define PTR_DIGS 8
# endif
# ifdef __ia64__
#   ifndef COMPRESSION
#     define COMPRESSION 8
#   endif
#   define TEXT_START 0x4000000000000000
#   define PTR_DIGS 16 
# endif

extern int etext;

/*
 * Note that the ith entry in the profile buffer corresponds to
 * a PC value of TEXT_START + i * COMPRESSION * 2.
 * The extra factor of 2 is not apparent from the documentation,
 * but it is explicit in the glibc source.
 */

void init_profiling()
{
    buf_size = ((size_t)(&etext) - TEXT_START + 0x10)/COMPRESSION/2;
    profil_buf = calloc(buf_size, sizeof(u_short));
    if (profil_buf == 0) {
	fprintf(stderr, "Could not allocate profile buffer\n");
    }
    profil(profil_buf, buf_size * sizeof(u_short),
	   TEXT_START, 65536/COMPRESSION);
}

void dump_profile()
{
    size_t i;
    size_t sum = 0;
    for (i = 0; i < buf_size; ++i) {
	if (profil_buf[i] != 0) {
	    fprintf(stderr, "%0*lx\t%d !PROF!\n",
		    PTR_DIGS,
		    TEXT_START + i * COMPRESSION * 2,
		    profil_buf[i]);
	    sum += profil_buf[i];
	}
    }
    fprintf(stderr, "Total number of samples was %ld !PROF!\n", sum);
}
