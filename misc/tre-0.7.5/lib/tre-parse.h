/*
  tre-parse.c - Regexp parser definitions

  Copyright (c) 2001-2006 Ville Laurikari <vl@iki.fi>

  This library is free software; you can redistribute it and/or
  modify it under the terms of the GNU Lesser General Public
  License as published by the Free Software Foundation; either
  version 2.1 of the License, or (at your option) any later version.

  This library is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
  Lesser General Public License for more details.

  You should have received a copy of the GNU Lesser General Public
  License along with this library; if not, write to the Free Software
  Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA

*/

#ifndef TRE_PARSE_H
#define TRE_PARSE_H 1

/* Parse context. */
typedef struct {
  /* Memory allocator.	The AST is allocated using this. */
  tre_mem_t mem;
  /* Stack used for keeping track of regexp syntax. */
  tre_stack_t *stack;
  /* The parse result. */
  tre_ast_node_t *result;
  /* The regexp to parse and its length. */
  const tre_char_t *re;
  /* The first character of the entire regexp. */
  const tre_char_t *re_start;
  /* The first character after the end of the regexp. */
  const tre_char_t *re_end;
  int len;
  /* Current submatch ID. */
  int submatch_id;
  /* Current position (number of literal). */
  int position;
  /* The highest back reference or -1 if none seen so far. */
  int max_backref;
  /* This flag is set if the regexp uses approximate matching. */
  int have_approx;
  /* Compilation flags. */
  int cflags;
  /* If this flag is set the top-level submatch is not captured. */
  int nofirstsub;
  /* The currently set approximate matching parameters. */
  int params[TRE_PARAM_LAST];
} tre_parse_ctx_t;

/* Parses a wide character regexp pattern into a syntax tree.  This parser
   handles both syntaxes (BRE and ERE), including the TRE extensions. */
reg_errcode_t
tre_parse(tre_parse_ctx_t *ctx);

#endif /* TRE_PARSE_H */

/* EOF */
