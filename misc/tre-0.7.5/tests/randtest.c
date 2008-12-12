/*
  randtest.c - tests with random regexps

  Copyright (c) 2001-2006 Ville Laurikari <vl@iki.fi>.

  This software is free; you can redistribute it and/or modify it
  under the terms of the GNU Lesser General Public License as
  published by the Free Software Foundation; either version 2.1 of the
  License, or (at your option) any later version.

  This software is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
  Lesser General Public License for more details.

  You should have received a copy of the GNU Lesser General Public
  License along with this software; if not, write to the Free Software
  Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA

*/

#ifdef HAVE_CONFIG_H
#include <config.h>
#endif /* HAVE_CONFIG_H */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <regex.h>
#include <time.h>

#undef MALLOC_DEBUGGING
#ifdef MALLOC_DEBUGGING
#include "xmalloc.h"
#endif /* MALLOC_DEBUGGING */

#define REGEXP_MAX_LEN 16

int
main(int argc, char **argv)
{
  int len, i, flags, n;
  char regex[50];
  char *buf;
  regex_t preg;
  int status, seed;

  seed = time(NULL);
  seed = 1028358583;
  printf("seed = %d\n", seed);
  srand(seed);
  n = 0;

  for (n = 0; n < 0; n++)
    rand();

  while (1)
    {
      printf("*");
      fflush(stdout);

      printf("n = %d\n", n);
      len = 1 + (int)(REGEXP_MAX_LEN * (rand() / (RAND_MAX + 1.0)));
      n++;

      for (i = 0; i < len; i++)
	{
	  regex[i] = 1 + (int)(255 * (rand() / (RAND_MAX + 1.0)));
	  n++;
	}
      regex[i] = L'\0';

      printf("len = %d, regexp = \"%s\"\n", len, regex);

      for (flags = 0;
	   flags < (REG_EXTENDED | REG_ICASE | REG_NEWLINE | REG_NOSUB);
	   flags++)
	{
	  buf = malloc(sizeof(*buf) * len);
	  strncpy(buf, regex, len - 1);
	  status = regncomp(&preg, buf, len, flags);
	  if (status == REG_OK)
	    regfree(&preg);
	}
      printf("\n");
    }

  return 0;
}
