/*
  tre-stack.h: Stack definitions

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


#ifndef TRE_STACK_H
#define TRE_STACK_H 1

#include "regex.h"

typedef struct tre_stack_rec tre_stack_t;

/* Creates a new stack object.	`size' is initial size in bytes, `max_size'
   is maximum size, and `increment' specifies how much more space will be
   allocated with realloc() if all space gets used up.	Returns the stack
   object or NULL if out of memory. */
tre_stack_t *
tre_stack_new(int size, int max_size, int increment);

/* Frees the stack object. */
void
tre_stack_destroy(tre_stack_t *s);

/* Returns the current number of objects in the stack. */
int
tre_stack_num_objects(tre_stack_t *s);

/* Each tre_stack_push_*(tre_stack_t *s, <type> value) function pushes
   `value' on top of stack `s'.  Returns REG_ESPACE if out of memory.
   This tries to realloc() more space before failing if maximum size
   has not yet been reached.  Returns REG_OK if successful. */
#define declare_pushf(typetag, type)					      \
  reg_errcode_t tre_stack_push_ ## typetag(tre_stack_t *s, type value)

declare_pushf(voidptr, void *);
declare_pushf(int, int);

/* Each tre_stack_pop_*(tre_stack_t *s) function pops the topmost
   element off of stack `s' and returns it.  The stack must not be
   empty. */
#define declare_popf(typetag, type)		  \
  type tre_stack_pop_ ## typetag(tre_stack_t *s)

declare_popf(voidptr, void *);
declare_popf(int, int);

/* Just to save some typing. */
#define STACK_PUSH(s, typetag, value)					      \
  do									      \
    {									      \
      status = tre_stack_push_ ## typetag(s, value);			      \
    }									      \
  while (0)

#define STACK_PUSHX(s, typetag, value)					      \
  {									      \
    status = tre_stack_push_ ## typetag(s, value);			      \
    if (status != REG_OK)						      \
      break;								      \
  }

#define STACK_PUSHR(s, typetag, value)					      \
  {									      \
    reg_errcode_t _status;						      \
    _status = tre_stack_push_ ## typetag(s, value);			      \
    if (_status != REG_OK)						      \
      return _status;							      \
  }

#endif /* TRE_STACK_H */

/* EOF */
