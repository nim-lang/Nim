/*
  test-str-source.c - Sample program for using reguexec()

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
#include "regex.h"

#define elementsof(x)	( sizeof(x) / sizeof(x[0]) )

/* Context structure for the tre_str_source wrappers.  */
typedef struct {
  /* Our string. */
  const char *str;
  /* Current position in the string. */
  size_t pos;
} str_handler_ctx;

/* The get_next_char() handler.  Sets `c' to the value of the next character,
   and increases `pos_add' by the number of bytes read.  Returns 1 if the
   string has ended, 0 if there are more characters. */
static int
str_handler_get_next(tre_char_t *c, unsigned int *pos_add, void *context)
{
  str_handler_ctx *ctx = context;
  unsigned char ch = ctx->str[ctx->pos];

  printf("str[%lu] = %d\n", (unsigned long)ctx->pos, ch);
  *c = ch;
  if (ch)
    ctx->pos++;
  *pos_add = 1;

  return c == '\0';
}

/* The rewind() handler.  Resets the current position in the input string. */
static void
str_handler_rewind(size_t pos, void *context)
{
  str_handler_ctx *ctx = context;

  printf("rewind to %lu\n", (unsigned long)pos);
  ctx->pos = pos;
}

/* The compare() handler.  Compares two substrings in the input and returns
   0 if the substrings are equal, and a nonzero value if not. */
static int
str_handler_compare(size_t pos1, size_t pos2, size_t len, void *context)
{
  str_handler_ctx *ctx = context;
  printf("comparing %lu-%lu and %lu-%lu\n",
	 (unsigned long)pos1, (unsigned long)pos1 + len,
	 (unsigned long)pos2, (unsigned long)pos2 + len);
  return strncmp(ctx->str + pos1, ctx->str + pos2, len);
}

/* Creates a tre_str_source wrapper around the string `str'.  Returns the
   tre_str_source object or NULL if out of memory. */
static tre_str_source *
make_str_source(const char *str)
{
  tre_str_source *s;
  str_handler_ctx *ctx;

  s = calloc(1, sizeof(*s));
  if (!s)
    return NULL;

  ctx = malloc(sizeof(str_handler_ctx));
  if (!ctx)
    {
      free(s);
      return NULL;
    }

  ctx->str = str;
  ctx->pos = 0;
  s->context = ctx;
  s->get_next_char = str_handler_get_next;
  s->rewind = str_handler_rewind;
  s->compare = str_handler_compare;

  return s;
}

/* Frees the memory allocated for `s'. */
static void
free_str_source(tre_str_source *s)
{
  free(s->context);
  free(s);
}

int
main(int argc, char **argv)
{
  regex_t preg;
  tre_str_source *source;
  regmatch_t pmatch[5];

  source = make_str_source("xfoofofoofoo");
  if (!source)
    return 1;

  regcomp(&preg, "(foo)\\1", REG_EXTENDED);
  if (reguexec(&preg, source, elementsof(pmatch), pmatch, 0) == 0)
    printf("Match: %d - %d\n", (int)pmatch[0].rm_so, (int)pmatch[0].rm_eo);

  free_str_source(source);

  return 0;
}
