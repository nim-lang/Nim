/*
  tre-compile.c - TRE regex compiler

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

/*
  TODO:
   - Fix tre_ast_to_tnfa() to recurse using a stack instead of recursive
     function calls.
*/


#ifdef HAVE_CONFIG_H
#include <config.h>
#endif /* HAVE_CONFIG_H */
#include <stdio.h>
#include <assert.h>
#include <string.h>

#include "tre-internal.h"
#include "tre-mem.h"
#include "tre-stack.h"
#include "tre-ast.h"
#include "tre-parse.h"
#include "tre-compile.h"
#include "regex.h"
#include "xmalloc.h"

/*
  Algorithms to setup tags so that submatch addressing can be done.
*/


/* Inserts a catenation node to the root of the tree given in `node'.
   As the left child a new tag with number `tag_id' to `node' is added,
   and the right child is the old root. */
static reg_errcode_t
tre_add_tag_left(tre_mem_t mem, tre_ast_node_t *node, int tag_id)
{
  tre_catenation_t *c;

  DPRINT(("add_tag_left: tag %d\n", tag_id));

  c = tre_mem_alloc(mem, sizeof(*c));
  if (c == NULL)
    return REG_ESPACE;
  c->left = tre_ast_new_literal(mem, TAG, tag_id, -1);
  if (c->left == NULL)
    return REG_ESPACE;
  c->right = tre_mem_alloc(mem, sizeof(tre_ast_node_t));
  if (c->right == NULL)
    return REG_ESPACE;

  c->right->obj = node->obj;
  c->right->type = node->type;
  c->right->nullable = -1;
  c->right->submatch_id = -1;
  c->right->firstpos = NULL;
  c->right->lastpos = NULL;
  c->right->num_tags = 0;
  node->obj = c;
  node->type = CATENATION;
  return REG_OK;
}

/* Inserts a catenation node to the root of the tree given in `node'.
   As the right child a new tag with number `tag_id' to `node' is added,
   and the left child is the old root. */
static reg_errcode_t
tre_add_tag_right(tre_mem_t mem, tre_ast_node_t *node, int tag_id)
{
  tre_catenation_t *c;

  DPRINT(("tre_add_tag_right: tag %d\n", tag_id));

  c = tre_mem_alloc(mem, sizeof(*c));
  if (c == NULL)
    return REG_ESPACE;
  c->right = tre_ast_new_literal(mem, TAG, tag_id, -1);
  if (c->right == NULL)
    return REG_ESPACE;
  c->left = tre_mem_alloc(mem, sizeof(tre_ast_node_t));
  if (c->left == NULL)
    return REG_ESPACE;

  c->left->obj = node->obj;
  c->left->type = node->type;
  c->left->nullable = -1;
  c->left->submatch_id = -1;
  c->left->firstpos = NULL;
  c->left->lastpos = NULL;
  c->left->num_tags = 0;
  node->obj = c;
  node->type = CATENATION;
  return REG_OK;
}

typedef enum {
  ADDTAGS_RECURSE,
  ADDTAGS_AFTER_ITERATION,
  ADDTAGS_AFTER_UNION_LEFT,
  ADDTAGS_AFTER_UNION_RIGHT,
  ADDTAGS_AFTER_CAT_LEFT,
  ADDTAGS_AFTER_CAT_RIGHT,
  ADDTAGS_SET_SUBMATCH_END
} tre_addtags_symbol_t;


typedef struct {
  int tag;
  int next_tag;
} tre_tag_states_t;

/* Adds tags to appropriate locations in the parse tree in `tree', so that
   subexpressions marked for submatch addressing can be traced. */
static reg_errcode_t
tre_add_tags(tre_mem_t mem, tre_stack_t *stack, tre_ast_node_t *tree,
	     tre_tnfa_t *tnfa)
{
  reg_errcode_t status = REG_OK;
  tre_addtags_symbol_t symbol;
  tre_ast_node_t *node = tree; /* Tree node we are currently looking at. */
  int bottom = tre_stack_num_objects(stack);
  /* True for first pass (counting number of needed tags) */
  int first_pass = (mem == NULL || tnfa == NULL);
  int *regset, *orig_regset;
  int num_tags = 0; /* Total number of tags. */
  int num_minimals = 0;	 /* Number of special minimal tags. */
  int tag = 0;	    /* The tag that is to be added next. */
  int next_tag = 1; /* Next tag to use after this one. */
  int *parents;	    /* Stack of submatches the current submatch is
		       contained in. */
  int minimal_tag = -1; /* Tag that marks the beginning of a minimal match. */
  tre_tag_states_t *saved_states;

  tre_tag_direction_t direction = TRE_TAG_MINIMIZE;
  if (!first_pass)
    {
      tnfa->end_tag = 0;
      tnfa->minimal_tags[0] = -1;
    }

  regset = xmalloc(sizeof(*regset) * ((tnfa->num_submatches + 1) * 2));
  if (regset == NULL)
    return REG_ESPACE;
  regset[0] = -1;
  orig_regset = regset;

  parents = xmalloc(sizeof(*parents) * (tnfa->num_submatches + 1));
  if (parents == NULL)
    {
      xfree(regset);
      return REG_ESPACE;
    }
  parents[0] = -1;

  saved_states = xmalloc(sizeof(*saved_states) * (tnfa->num_submatches + 1));
  if (saved_states == NULL)
    {
      xfree(regset);
      xfree(parents);
      return REG_ESPACE;
    }
  else
    {
      unsigned int i;
      for (i = 0; i <= tnfa->num_submatches; i++)
	saved_states[i].tag = -1;
    }

  STACK_PUSH(stack, voidptr, node);
  STACK_PUSH(stack, int, ADDTAGS_RECURSE);

  while (tre_stack_num_objects(stack) > bottom)
    {
      if (status != REG_OK)
	break;

      symbol = (tre_addtags_symbol_t)tre_stack_pop_int(stack);
      switch (symbol)
	{

	case ADDTAGS_SET_SUBMATCH_END:
	  {
	    int id = tre_stack_pop_int(stack);
	    int i;

	    /* Add end of this submatch to regset. */
	    for (i = 0; regset[i] >= 0; i++);
	    regset[i] = id * 2 + 1;
	    regset[i + 1] = -1;

	    /* Pop this submatch from the parents stack. */
	    for (i = 0; parents[i] >= 0; i++);
	    parents[i - 1] = -1;
	    break;
	  }

	case ADDTAGS_RECURSE:
	  node = tre_stack_pop_voidptr(stack);

	  if (node->submatch_id >= 0)
	    {
	      int id = node->submatch_id;
	      int i;


	      /* Add start of this submatch to regset. */
	      for (i = 0; regset[i] >= 0; i++);
	      regset[i] = id * 2;
	      regset[i + 1] = -1;

	      if (!first_pass)
		{
		  for (i = 0; parents[i] >= 0; i++);
		  tnfa->submatch_data[id].parents = NULL;
		  if (i > 0)
		    {
		      int *p = xmalloc(sizeof(*p) * (i + 1));
		      if (p == NULL)
			{
			  status = REG_ESPACE;
			  break;
			}
		      assert(tnfa->submatch_data[id].parents == NULL);
		      tnfa->submatch_data[id].parents = p;
		      for (i = 0; parents[i] >= 0; i++)
			p[i] = parents[i];
		      p[i] = -1;
		    }
		}

	      /* Add end of this submatch to regset after processing this
		 node. */
	      STACK_PUSHX(stack, int, node->submatch_id);
	      STACK_PUSHX(stack, int, ADDTAGS_SET_SUBMATCH_END);
	    }

	  switch (node->type)
	    {
	    case LITERAL:
	      {
		tre_literal_t *lit = node->obj;

		if (!IS_SPECIAL(lit) || IS_BACKREF(lit))
		  {
		    int i;
		    DPRINT(("Literal %d-%d\n",
			    (int)lit->code_min, (int)lit->code_max));
		    if (regset[0] >= 0)
		      {
			/* Regset is not empty, so add a tag before the
			   literal or backref. */
			if (!first_pass)
			  {
			    status = tre_add_tag_left(mem, node, tag);
			    tnfa->tag_directions[tag] = direction;
			    if (minimal_tag >= 0)
			      {
				DPRINT(("Minimal %d, %d\n", minimal_tag, tag));
				for (i = 0; tnfa->minimal_tags[i] >= 0; i++);
				tnfa->minimal_tags[i] = tag;
				tnfa->minimal_tags[i + 1] = minimal_tag;
				tnfa->minimal_tags[i + 2] = -1;
				minimal_tag = -1;
				num_minimals++;
			      }
			    /* Go through the regset and set submatch data for
			       submatches that are using this tag. */
			    for (i = 0; regset[i] >= 0; i++)
			      {
				int id = regset[i] / 2;
				int start = !(regset[i] % 2);
				DPRINT(("  Using tag %d for %s offset of "
					"submatch %d\n", tag,
					start ? "start" : "end", id));
				if (start)
				  tnfa->submatch_data[id].so_tag = tag;
				else
				  tnfa->submatch_data[id].eo_tag = tag;
			      }
			  }
			else
			  {
			    DPRINT(("  num_tags = 1\n"));
			    node->num_tags = 1;
			  }

			DPRINT(("  num_tags++\n"));
			regset[0] = -1;
			tag = next_tag;
			num_tags++;
			next_tag++;
		      }
		  }
		else
		  {
		    assert(!IS_TAG(lit));
		  }
		break;
	      }
	    case CATENATION:
	      {
		tre_catenation_t *cat = node->obj;
		tre_ast_node_t *left = cat->left;
		tre_ast_node_t *right = cat->right;
		int reserved_tag = -1;
		DPRINT(("Catenation, next_tag = %d\n", next_tag));


		/* After processing right child. */
		STACK_PUSHX(stack, voidptr, node);
		STACK_PUSHX(stack, int, ADDTAGS_AFTER_CAT_RIGHT);

		/* Process right child. */
		STACK_PUSHX(stack, voidptr, right);
		STACK_PUSHX(stack, int, ADDTAGS_RECURSE);

		/* After processing left child. */
		STACK_PUSHX(stack, int, next_tag + left->num_tags);
		DPRINT(("  Pushing %d for after left\n",
			next_tag + left->num_tags));
		if (left->num_tags > 0 && right->num_tags > 0)
		  {
		    /* Reserve the next tag to the right child. */
		    DPRINT(("  Reserving next_tag %d to right child\n",
			    next_tag));
		    reserved_tag = next_tag;
		    next_tag++;
		  }
		STACK_PUSHX(stack, int, reserved_tag);
		STACK_PUSHX(stack, int, ADDTAGS_AFTER_CAT_LEFT);

		/* Process left child. */
		STACK_PUSHX(stack, voidptr, left);
		STACK_PUSHX(stack, int, ADDTAGS_RECURSE);

		}
	      break;
	    case ITERATION:
	      {
		tre_iteration_t *iter = node->obj;
		DPRINT(("Iteration\n"));

		if (first_pass)
		  {
		    STACK_PUSHX(stack, int, regset[0] >= 0 || iter->minimal);
		  }
		else
		  {
		    STACK_PUSHX(stack, int, tag);
		    STACK_PUSHX(stack, int, iter->minimal);
		  }
		STACK_PUSHX(stack, voidptr, node);
		STACK_PUSHX(stack, int, ADDTAGS_AFTER_ITERATION);

		STACK_PUSHX(stack, voidptr, iter->arg);
		STACK_PUSHX(stack, int, ADDTAGS_RECURSE);

		/* Regset is not empty, so add a tag here. */
		if (regset[0] >= 0 || iter->minimal)
		  {
		    if (!first_pass)
		      {
			int i;
			status = tre_add_tag_left(mem, node, tag);
			if (iter->minimal)
			  tnfa->tag_directions[tag] = TRE_TAG_MAXIMIZE;
			else
			  tnfa->tag_directions[tag] = direction;
			if (minimal_tag >= 0)
			  {
			    DPRINT(("Minimal %d, %d\n", minimal_tag, tag));
			    for (i = 0; tnfa->minimal_tags[i] >= 0; i++);
			    tnfa->minimal_tags[i] = tag;
			    tnfa->minimal_tags[i + 1] = minimal_tag;
			    tnfa->minimal_tags[i + 2] = -1;
			    minimal_tag = -1;
			    num_minimals++;
			  }
			/* Go through the regset and set submatch data for
			   submatches that are using this tag. */
			for (i = 0; regset[i] >= 0; i++)
			  {
			    int id = regset[i] / 2;
			    int start = !(regset[i] % 2);
			    DPRINT(("  Using tag %d for %s offset of "
				    "submatch %d\n", tag,
				    start ? "start" : "end", id));
			    if (start)
			      tnfa->submatch_data[id].so_tag = tag;
			    else
			      tnfa->submatch_data[id].eo_tag = tag;
			  }
		      }

		    DPRINT(("  num_tags++\n"));
		    regset[0] = -1;
		    tag = next_tag;
		    num_tags++;
		    next_tag++;
		  }
		direction = TRE_TAG_MINIMIZE;
	      }
	      break;
	    case UNION:
	      {
		tre_union_t *uni = node->obj;
		tre_ast_node_t *left = uni->left;
		tre_ast_node_t *right = uni->right;
		int left_tag;
		int right_tag;

		if (regset[0] >= 0)
		  {
		    left_tag = next_tag;
		    right_tag = next_tag + 1;
		  }
		else
		  {
		    left_tag = tag;
		    right_tag = next_tag;
		  }

		DPRINT(("Union\n"));

		/* After processing right child. */
		STACK_PUSHX(stack, int, right_tag);
		STACK_PUSHX(stack, int, left_tag);
		STACK_PUSHX(stack, voidptr, regset);
		STACK_PUSHX(stack, int, regset[0] >= 0);
		STACK_PUSHX(stack, voidptr, node);
		STACK_PUSHX(stack, voidptr, right);
		STACK_PUSHX(stack, voidptr, left);
		STACK_PUSHX(stack, int, ADDTAGS_AFTER_UNION_RIGHT);

		/* Process right child. */
		STACK_PUSHX(stack, voidptr, right);
		STACK_PUSHX(stack, int, ADDTAGS_RECURSE);

		/* After processing left child. */
		STACK_PUSHX(stack, int, ADDTAGS_AFTER_UNION_LEFT);

		/* Process left child. */
		STACK_PUSHX(stack, voidptr, left);
		STACK_PUSHX(stack, int, ADDTAGS_RECURSE);

		/* Regset is not empty, so add a tag here. */
		if (regset[0] >= 0)
		  {
		    if (!first_pass)
		      {
			int i;
			status = tre_add_tag_left(mem, node, tag);
			tnfa->tag_directions[tag] = direction;
			if (minimal_tag >= 0)
			  {
			    DPRINT(("Minimal %d, %d\n", minimal_tag, tag));
			    for (i = 0; tnfa->minimal_tags[i] >= 0; i++);
			    tnfa->minimal_tags[i] = tag;
			    tnfa->minimal_tags[i + 1] = minimal_tag;
			    tnfa->minimal_tags[i + 2] = -1;
			    minimal_tag = -1;
			    num_minimals++;
			  }
			/* Go through the regset and set submatch data for
			   submatches that are using this tag. */
			for (i = 0; regset[i] >= 0; i++)
			  {
			    int id = regset[i] / 2;
			    int start = !(regset[i] % 2);
			    DPRINT(("  Using tag %d for %s offset of "
				    "submatch %d\n", tag,
				    start ? "start" : "end", id));
			    if (start)
			      tnfa->submatch_data[id].so_tag = tag;
			    else
			      tnfa->submatch_data[id].eo_tag = tag;
			  }
		      }

		    DPRINT(("  num_tags++\n"));
		    regset[0] = -1;
		    tag = next_tag;
		    num_tags++;
		    next_tag++;
		  }

		if (node->num_submatches > 0)
		  {
		    /* The next two tags are reserved for markers. */
		    next_tag++;
		    tag = next_tag;
		    next_tag++;
		  }

		break;
	      }
	    }

	  if (node->submatch_id >= 0)
	    {
	      int i;
	      /* Push this submatch on the parents stack. */
	      for (i = 0; parents[i] >= 0; i++);
	      parents[i] = node->submatch_id;
	      parents[i + 1] = -1;
	    }

	  break; /* end case: ADDTAGS_RECURSE */

	case ADDTAGS_AFTER_ITERATION:
	  {
	    int minimal = 0;
	    int enter_tag;
	    node = tre_stack_pop_voidptr(stack);
	    if (first_pass)
	      {
		node->num_tags = ((tre_iteration_t *)node->obj)->arg->num_tags
		  + tre_stack_pop_int(stack);
		minimal_tag = -1;
	      }
	    else
	      {
		minimal = tre_stack_pop_int(stack);
		enter_tag = tre_stack_pop_int(stack);
		if (minimal)
		  minimal_tag = enter_tag;
	      }

	    DPRINT(("After iteration\n"));
	    if (!first_pass)
	      {
		DPRINT(("  Setting direction to %s\n",
			minimal ? "minimize" : "maximize"));
		if (minimal)
		  direction = TRE_TAG_MINIMIZE;
		else
		  direction = TRE_TAG_MAXIMIZE;
	      }
	    break;
	  }

	case ADDTAGS_AFTER_CAT_LEFT:
	  {
	    int new_tag = tre_stack_pop_int(stack);
	    next_tag = tre_stack_pop_int(stack);
	    DPRINT(("After cat left, tag = %d, next_tag = %d\n",
		    tag, next_tag));
	    if (new_tag >= 0)
	      {
		DPRINT(("  Setting tag to %d\n", new_tag));
		tag = new_tag;
	      }
	    break;
	  }

	case ADDTAGS_AFTER_CAT_RIGHT:
	  DPRINT(("After cat right\n"));
	  node = tre_stack_pop_voidptr(stack);
	  if (first_pass)
	    node->num_tags = ((tre_catenation_t *)node->obj)->left->num_tags
	      + ((tre_catenation_t *)node->obj)->right->num_tags;
	  break;

	case ADDTAGS_AFTER_UNION_LEFT:
	  DPRINT(("After union left\n"));
	  /* Lift the bottom of the `regset' array so that when processing
	     the right operand the items currently in the array are
	     invisible.	 The original bottom was saved at ADDTAGS_UNION and
	     will be restored at ADDTAGS_AFTER_UNION_RIGHT below. */
	  while (*regset >= 0)
	    regset++;
	  break;

	case ADDTAGS_AFTER_UNION_RIGHT:
	  {
	    int added_tags, tag_left, tag_right;
	    tre_ast_node_t *left = tre_stack_pop_voidptr(stack);
	    tre_ast_node_t *right = tre_stack_pop_voidptr(stack);
	    DPRINT(("After union right\n"));
	    node = tre_stack_pop_voidptr(stack);
	    added_tags = tre_stack_pop_int(stack);
	    if (first_pass)
	      {
		node->num_tags = ((tre_union_t *)node->obj)->left->num_tags
		  + ((tre_union_t *)node->obj)->right->num_tags + added_tags
		  + ((node->num_submatches > 0) ? 2 : 0);
	      }
	    regset = tre_stack_pop_voidptr(stack);
	    tag_left = tre_stack_pop_int(stack);
	    tag_right = tre_stack_pop_int(stack);

	    /* Add tags after both children, the left child gets a smaller
	       tag than the right child.  This guarantees that we prefer
	       the left child over the right child. */
	    /* XXX - This is not always necessary (if the children have
	       tags which must be seen for every match of that child). */
	    /* XXX - Check if this is the only place where tre_add_tag_right
	       is used.	 If so, use tre_add_tag_left (putting the tag before
	       the child as opposed after the child) and throw away
	       tre_add_tag_right. */
	    if (node->num_submatches > 0)
	      {
		if (!first_pass)
		  {
		    status = tre_add_tag_right(mem, left, tag_left);
		    tnfa->tag_directions[tag_left] = TRE_TAG_MAXIMIZE;
		    status = tre_add_tag_right(mem, right, tag_right);
		    tnfa->tag_directions[tag_right] = TRE_TAG_MAXIMIZE;
		  }
		DPRINT(("  num_tags += 2\n"));
		num_tags += 2;
	      }
	    direction = TRE_TAG_MAXIMIZE;
	    break;
	  }

	default:
	  assert(0);
	  break;

	} /* end switch(symbol) */
    } /* end while(tre_stack_num_objects(stack) > bottom) */

  if (!first_pass)
    {
      int i;
      /* Go through the regset and set submatch data for
	 submatches that are using this tag. */
      for (i = 0; regset[i] >= 0; i++)
	{
	  int id = regset[i] / 2;
	  int start = !(regset[i] % 2);
	  DPRINT(("  Using tag %d for %s offset of "
		  "submatch %d\n", num_tags,
		  start ? "start" : "end", id));
	  if (start)
	    tnfa->submatch_data[id].so_tag = num_tags;
	  else
	    tnfa->submatch_data[id].eo_tag = num_tags;
	}
    }

  if (!first_pass && minimal_tag >= 0)
    {
      int i;
      DPRINT(("Minimal %d, %d\n", minimal_tag, tag));
      for (i = 0; tnfa->minimal_tags[i] >= 0; i++);
      tnfa->minimal_tags[i] = tag;
      tnfa->minimal_tags[i + 1] = minimal_tag;
      tnfa->minimal_tags[i + 2] = -1;
      minimal_tag = -1;
      num_minimals++;
    }

  DPRINT(("tre_add_tags: %s complete.  Number of tags %d.\n",
	  first_pass? "First pass" : "Second pass", num_tags));

  assert(tree->num_tags == num_tags);
  tnfa->end_tag = num_tags;
  tnfa->num_tags = num_tags;
  tnfa->num_minimals = num_minimals;
  xfree(orig_regset);
  xfree(parents);
  xfree(saved_states);
  return status;
}



/*
  AST to TNFA compilation routines.
*/

typedef enum {
  COPY_RECURSE,
  COPY_SET_RESULT_PTR
} tre_copyast_symbol_t;

/* Flags for tre_copy_ast(). */
#define COPY_REMOVE_TAGS	 1
#define COPY_MAXIMIZE_FIRST_TAG	 2

static reg_errcode_t
tre_copy_ast(tre_mem_t mem, tre_stack_t *stack, tre_ast_node_t *ast,
	     int flags, int *pos_add, tre_tag_direction_t *tag_directions,
	     tre_ast_node_t **copy, int *max_pos)
{
  reg_errcode_t status = REG_OK;
  int bottom = tre_stack_num_objects(stack);
  int num_copied = 0;
  int first_tag = 1;
  tre_ast_node_t **result = copy;
  tre_copyast_symbol_t symbol;

  STACK_PUSH(stack, voidptr, ast);
  STACK_PUSH(stack, int, COPY_RECURSE);

  while (status == REG_OK && tre_stack_num_objects(stack) > bottom)
    {
      tre_ast_node_t *node;
      if (status != REG_OK)
	break;

      symbol = (tre_copyast_symbol_t)tre_stack_pop_int(stack);
      switch (symbol)
	{
	case COPY_SET_RESULT_PTR:
	  result = tre_stack_pop_voidptr(stack);
	  break;
	case COPY_RECURSE:
	  node = tre_stack_pop_voidptr(stack);
	  switch (node->type)
	    {
	    case LITERAL:
	      {
		tre_literal_t *lit = node->obj;
		int pos = lit->position;
		int min = lit->code_min;
		int max = lit->code_max;
		if (!IS_SPECIAL(lit) || IS_BACKREF(lit))
		  {
		    /* XXX - e.g. [ab] has only one position but two
		       nodes, so we are creating holes in the state space
		       here.  Not fatal, just wastes memory. */
		    pos += *pos_add;
		    num_copied++;
		  }
		else if (IS_TAG(lit) && (flags & COPY_REMOVE_TAGS))
		  {
		    /* Change this tag to empty. */
		    min = EMPTY;
		    max = pos = -1;
		  }
		else if (IS_TAG(lit) && (flags & COPY_MAXIMIZE_FIRST_TAG)
			 && first_tag)
		  {
		    /* Maximize the first tag. */
		    tag_directions[max] = TRE_TAG_MAXIMIZE;
		    first_tag = 0;
		  }
		*result = tre_ast_new_literal(mem, min, max, pos);
		if (*result == NULL)
		  status = REG_ESPACE;

		if (pos > *max_pos)
		  *max_pos = pos;
		break;
	      }
	    case UNION:
	      {
		tre_union_t *uni = node->obj;
		tre_union_t *tmp;
		*result = tre_ast_new_union(mem, uni->left, uni->right);
		if (*result == NULL)
		  {
		    status = REG_ESPACE;
		    break;
		  }
		tmp = (*result)->obj;
		result = &tmp->left;
		STACK_PUSHX(stack, voidptr, uni->right);
		STACK_PUSHX(stack, int, COPY_RECURSE);
		STACK_PUSHX(stack, voidptr, &tmp->right);
		STACK_PUSHX(stack, int, COPY_SET_RESULT_PTR);
		STACK_PUSHX(stack, voidptr, uni->left);
		STACK_PUSHX(stack, int, COPY_RECURSE);
		break;
	      }
	    case CATENATION:
	      {
		tre_catenation_t *cat = node->obj;
		tre_catenation_t *tmp;
		*result = tre_ast_new_catenation(mem, cat->left, cat->right);
		if (*result == NULL)
		  {
		    status = REG_ESPACE;
		    break;
		  }
		tmp = (*result)->obj;
		tmp->left = NULL;
		tmp->right = NULL;
		result = &tmp->left;

		STACK_PUSHX(stack, voidptr, cat->right);
		STACK_PUSHX(stack, int, COPY_RECURSE);
		STACK_PUSHX(stack, voidptr, &tmp->right);
		STACK_PUSHX(stack, int, COPY_SET_RESULT_PTR);
		STACK_PUSHX(stack, voidptr, cat->left);
		STACK_PUSHX(stack, int, COPY_RECURSE);
		break;
	      }
	    case ITERATION:
	      {
		tre_iteration_t *iter = node->obj;
		STACK_PUSHX(stack, voidptr, iter->arg);
		STACK_PUSHX(stack, int, COPY_RECURSE);
		*result = tre_ast_new_iter(mem, iter->arg, iter->min,
					   iter->max, iter->minimal);
		if (*result == NULL)
		  {
		    status = REG_ESPACE;
		    break;
		  }
		iter = (*result)->obj;
		result = &iter->arg;
		break;
	      }
	    default:
	      assert(0);
	      break;
	    }
	  break;
	}
    }
  *pos_add += num_copied;
  return status;
}

typedef enum {
  EXPAND_RECURSE,
  EXPAND_AFTER_ITER
} tre_expand_ast_symbol_t;

/* Expands each iteration node that has a finite nonzero minimum or maximum
   iteration count to a catenated sequence of copies of the node. */
static reg_errcode_t
tre_expand_ast(tre_mem_t mem, tre_stack_t *stack, tre_ast_node_t *ast,
	       int *position, tre_tag_direction_t *tag_directions,
	       int *max_depth)
{
  reg_errcode_t status = REG_OK;
  int bottom = tre_stack_num_objects(stack);
  int pos_add = 0;
  int pos_add_total = 0;
  int max_pos = 0;
  /* Current approximate matching parameters. */
  int params[TRE_PARAM_LAST];
  /* Approximate parameter nesting level. */
  int params_depth = 0;
  int iter_depth = 0;
  int i;

  for (i = 0; i < TRE_PARAM_LAST; i++)
    params[i] = TRE_PARAM_DEFAULT;

  STACK_PUSHR(stack, voidptr, ast);
  STACK_PUSHR(stack, int, EXPAND_RECURSE);
  while (status == REG_OK && tre_stack_num_objects(stack) > bottom)
    {
      tre_ast_node_t *node;
      tre_expand_ast_symbol_t symbol;

      if (status != REG_OK)
	break;

      DPRINT(("pos_add %d\n", pos_add));

      symbol = (tre_expand_ast_symbol_t)tre_stack_pop_int(stack);
      node = tre_stack_pop_voidptr(stack);
      switch (symbol)
	{
	case EXPAND_RECURSE:
	  switch (node->type)
	    {
	    case LITERAL:
	      {
		tre_literal_t *lit= node->obj;
		if (!IS_SPECIAL(lit) || IS_BACKREF(lit))
		  {
		    lit->position += pos_add;
		    if (lit->position > max_pos)
		      max_pos = lit->position;
		  }
		break;
	      }
	    case UNION:
	      {
		tre_union_t *uni = node->obj;
		STACK_PUSHX(stack, voidptr, uni->right);
		STACK_PUSHX(stack, int, EXPAND_RECURSE);
		STACK_PUSHX(stack, voidptr, uni->left);
		STACK_PUSHX(stack, int, EXPAND_RECURSE);
		break;
	      }
	    case CATENATION:
	      {
		tre_catenation_t *cat = node->obj;
		STACK_PUSHX(stack, voidptr, cat->right);
		STACK_PUSHX(stack, int, EXPAND_RECURSE);
		STACK_PUSHX(stack, voidptr, cat->left);
		STACK_PUSHX(stack, int, EXPAND_RECURSE);
		break;
	      }
	    case ITERATION:
	      {
		tre_iteration_t *iter = node->obj;
		STACK_PUSHX(stack, int, pos_add);
		STACK_PUSHX(stack, voidptr, node);
		STACK_PUSHX(stack, int, EXPAND_AFTER_ITER);
		STACK_PUSHX(stack, voidptr, iter->arg);
		STACK_PUSHX(stack, int, EXPAND_RECURSE);
		/* If we are going to expand this node at EXPAND_AFTER_ITER
		   then don't increase the `pos' fields of the nodes now, it
		   will get done when expanding. */
		if (iter->min > 1 || iter->max > 1)
		  pos_add = 0;
		iter_depth++;
		DPRINT(("iter\n"));
		break;
	      }
	    default:
	      assert(0);
	      break;
	    }
	  break;
	case EXPAND_AFTER_ITER:
	  {
	    tre_iteration_t *iter = node->obj;
	    int pos_add_last;
	    pos_add = tre_stack_pop_int(stack);
	    pos_add_last = pos_add;
	    if (iter->min > 1 || iter->max > 1)
	      {
		tre_ast_node_t *seq1 = NULL, *seq2 = NULL;
		int i;
		int pos_add_save = pos_add;

		/* Create a catenated sequence of copies of the node. */
		for (i = 0; i < iter->min; i++)
		  {
		    tre_ast_node_t *copy;
		    /* Remove tags from all but the last copy. */
		    int flags = ((i + 1 < iter->min)
				 ? COPY_REMOVE_TAGS
				 : COPY_MAXIMIZE_FIRST_TAG);
		    DPRINT(("  pos_add %d\n", pos_add));
		    pos_add_save = pos_add;
		    status = tre_copy_ast(mem, stack, iter->arg, flags,
					  &pos_add, tag_directions, &copy,
					  &max_pos);
		    if (status != REG_OK)
		      return status;
		    if (seq1 != NULL)
		      seq1 = tre_ast_new_catenation(mem, seq1, copy);
		    else
		      seq1 = copy;
		    if (seq1 == NULL)
		      return REG_ESPACE;
		  }

		if (iter->max == -1)
		  {
		    /* No upper limit. */
		    pos_add_save = pos_add;
		    status = tre_copy_ast(mem, stack, iter->arg, 0,
					  &pos_add, NULL, &seq2, &max_pos);
		    if (status != REG_OK)
		      return status;
		    seq2 = tre_ast_new_iter(mem, seq2, 0, -1, 0);
		    if (seq2 == NULL)
		      return REG_ESPACE;
		  }
		else
		  {
		    for (i = iter->min; i < iter->max; i++)
		      {
			tre_ast_node_t *tmp, *copy;
			pos_add_save = pos_add;
			status = tre_copy_ast(mem, stack, iter->arg, 0,
					      &pos_add, NULL, &copy, &max_pos);
			if (status != REG_OK)
			  return status;
			if (seq2 != NULL)
			  seq2 = tre_ast_new_catenation(mem, copy, seq2);
			else
			  seq2 = copy;
			if (seq2 == NULL)
			  return REG_ESPACE;
			tmp = tre_ast_new_literal(mem, EMPTY, -1, -1);
			if (tmp == NULL)
			  return REG_ESPACE;
			seq2 = tre_ast_new_union(mem, tmp, seq2);
			if (seq2 == NULL)
			  return REG_ESPACE;
		      }
		  }

		pos_add = pos_add_save;
		if (seq1 == NULL)
		  seq1 = seq2;
		else if (seq2 != NULL)
		  seq1 = tre_ast_new_catenation(mem, seq1, seq2);
		if (seq1 == NULL)
		  return REG_ESPACE;
		node->obj = seq1->obj;
		node->type = seq1->type;
	      }

	    iter_depth--;
	    pos_add_total += pos_add - pos_add_last;
	    if (iter_depth == 0)
	      pos_add = pos_add_total;

	    /* If approximate parameters are specified, surround the result
	       with two parameter setting nodes.  The one on the left sets
	       the specified parameters, and the one on the right restores
	       the old parameters. */
	    if (iter->params)
	      {
		tre_ast_node_t *tmp_l, *tmp_r, *tmp_node, *node_copy;
		int *old_params;

		tmp_l = tre_ast_new_literal(mem, PARAMETER, 0, -1);
		if (!tmp_l)
		  return REG_ESPACE;
		((tre_literal_t *)tmp_l->obj)->u.params = iter->params;
		iter->params[TRE_PARAM_DEPTH] = params_depth + 1;
		tmp_r = tre_ast_new_literal(mem, PARAMETER, 0, -1);
		if (!tmp_r)
		  return REG_ESPACE;
		old_params = tre_mem_alloc(mem, sizeof(*old_params)
					   * TRE_PARAM_LAST);
		if (!old_params)
		  return REG_ESPACE;
		for (i = 0; i < TRE_PARAM_LAST; i++)
		  old_params[i] = params[i];
		((tre_literal_t *)tmp_r->obj)->u.params = old_params;
		old_params[TRE_PARAM_DEPTH] = params_depth;
		/* XXX - this is the only place where ast_new_node is
		   needed -- should be moved inside AST module. */
		node_copy = tre_ast_new_node(mem, ITERATION,
					     sizeof(tre_iteration_t));
		if (!node_copy)
		  return REG_ESPACE;
		node_copy->obj = node->obj;
		tmp_node = tre_ast_new_catenation(mem, tmp_l, node_copy);
		if (!tmp_node)
		  return REG_ESPACE;
		tmp_node = tre_ast_new_catenation(mem, tmp_node, tmp_r);
		if (!tmp_node)
		  return REG_ESPACE;
		/* Replace the contents of `node' with `tmp_node'. */
		memcpy(node, tmp_node, sizeof(*node));
		node->obj = tmp_node->obj;
		node->type = tmp_node->type;
		params_depth++;
		if (params_depth > *max_depth)
		  *max_depth = params_depth;
	      }
	    break;
	  }
	default:
	  assert(0);
	  break;
	}
    }

  *position += pos_add_total;

  /* `max_pos' should never be larger than `*position' if the above
     code works, but just an extra safeguard let's make sure
     `*position' is set large enough so enough memory will be
     allocated for the transition table. */
  if (max_pos > *position)
    *position = max_pos;

#ifdef TRE_DEBUG
  DPRINT(("Expanded AST:\n"));
  tre_ast_print(ast);
  DPRINT(("*position %d, max_pos %d\n", *position, max_pos));
#endif

  return status;
}

static tre_pos_and_tags_t *
tre_set_empty(tre_mem_t mem)
{
  tre_pos_and_tags_t *new_set;

  new_set = tre_mem_calloc(mem, sizeof(*new_set));
  if (new_set == NULL)
    return NULL;

  new_set[0].position = -1;
  new_set[0].code_min = -1;
  new_set[0].code_max = -1;

  return new_set;
}

static tre_pos_and_tags_t *
tre_set_one(tre_mem_t mem, int position, int code_min, int code_max,
	    tre_ctype_t class, tre_ctype_t *neg_classes, int backref)
{
  tre_pos_and_tags_t *new_set;

  new_set = tre_mem_calloc(mem, sizeof(*new_set) * 2);
  if (new_set == NULL)
    return NULL;

  new_set[0].position = position;
  new_set[0].code_min = code_min;
  new_set[0].code_max = code_max;
  new_set[0].class = class;
  new_set[0].neg_classes = neg_classes;
  new_set[0].backref = backref;
  new_set[1].position = -1;
  new_set[1].code_min = -1;
  new_set[1].code_max = -1;

  return new_set;
}

static tre_pos_and_tags_t *
tre_set_union(tre_mem_t mem, tre_pos_and_tags_t *set1, tre_pos_and_tags_t *set2,
	      int *tags, int assertions, int *params)
{
  int s1, s2, i, j;
  tre_pos_and_tags_t *new_set;
  int *new_tags;
  int num_tags;

  for (num_tags = 0; tags != NULL && tags[num_tags] >= 0; num_tags++);
  for (s1 = 0; set1[s1].position >= 0; s1++);
  for (s2 = 0; set2[s2].position >= 0; s2++);
  new_set = tre_mem_calloc(mem, sizeof(*new_set) * (s1 + s2 + 1));
  if (!new_set )
    return NULL;

  for (s1 = 0; set1[s1].position >= 0; s1++)
    {
      new_set[s1].position = set1[s1].position;
      new_set[s1].code_min = set1[s1].code_min;
      new_set[s1].code_max = set1[s1].code_max;
      new_set[s1].assertions = set1[s1].assertions | assertions;
      new_set[s1].class = set1[s1].class;
      new_set[s1].neg_classes = set1[s1].neg_classes;
      new_set[s1].backref = set1[s1].backref;
      if (set1[s1].tags == NULL && tags == NULL)
	new_set[s1].tags = NULL;
      else
	{
	  for (i = 0; set1[s1].tags != NULL && set1[s1].tags[i] >= 0; i++);
	  new_tags = tre_mem_alloc(mem, (sizeof(*new_tags)
					 * (i + num_tags + 1)));
	  if (new_tags == NULL)
	    return NULL;
	  for (j = 0; j < i; j++)
	    new_tags[j] = set1[s1].tags[j];
	  for (i = 0; i < num_tags; i++)
	    new_tags[j + i] = tags[i];
	  new_tags[j + i] = -1;
	  new_set[s1].tags = new_tags;
	}
      if (set1[s1].params)
	new_set[s1].params = set1[s1].params;
      if (params)
	{
	  if (!new_set[s1].params)
	    new_set[s1].params = params;
	  else
	    {
	      new_set[s1].params = tre_mem_alloc(mem, sizeof(*params) *
						 TRE_PARAM_LAST);
	      if (!new_set[s1].params)
		return NULL;
	      for (i = 0; i < TRE_PARAM_LAST; i++)
		if (params[i] != TRE_PARAM_UNSET)
		  new_set[s1].params[i] = params[i];
	    }
	}
    }

  for (s2 = 0; set2[s2].position >= 0; s2++)
    {
      new_set[s1 + s2].position = set2[s2].position;
      new_set[s1 + s2].code_min = set2[s2].code_min;
      new_set[s1 + s2].code_max = set2[s2].code_max;
      /* XXX - why not | assertions here as well? */
      new_set[s1 + s2].assertions = set2[s2].assertions;
      new_set[s1 + s2].class = set2[s2].class;
      new_set[s1 + s2].neg_classes = set2[s2].neg_classes;
      new_set[s1 + s2].backref = set2[s2].backref;
      if (set2[s2].tags == NULL)
	new_set[s1 + s2].tags = NULL;
      else
	{
	  for (i = 0; set2[s2].tags[i] >= 0; i++);
	  new_tags = tre_mem_alloc(mem, sizeof(*new_tags) * (i + 1));
	  if (new_tags == NULL)
	    return NULL;
	  for (j = 0; j < i; j++)
	    new_tags[j] = set2[s2].tags[j];
	  new_tags[j] = -1;
	  new_set[s1 + s2].tags = new_tags;
	}
      if (set2[s2].params)
	new_set[s1 + s2].params = set2[s2].params;
      if (params)
	{
	  if (!new_set[s1 + s2].params)
	    new_set[s1 + s2].params = params;
	  else
	    {
	      new_set[s1 + s2].params = tre_mem_alloc(mem, sizeof(*params) *
						      TRE_PARAM_LAST);
	      if (!new_set[s1 + s2].params)
		return NULL;
	      for (i = 0; i < TRE_PARAM_LAST; i++)
		if (params[i] != TRE_PARAM_UNSET)
		  new_set[s1 + s2].params[i] = params[i];
	    }
	}
    }
  new_set[s1 + s2].position = -1;
  return new_set;
}

/* Finds the empty path through `node' which is the one that should be
   taken according to POSIX.2 rules, and adds the tags on that path to
   `tags'.   `tags' may be NULL.  If `num_tags_seen' is not NULL, it is
   set to the number of tags seen on the path. */
static reg_errcode_t
tre_match_empty(tre_stack_t *stack, tre_ast_node_t *node, int *tags,
		int *assertions, int *params, int *num_tags_seen,
		int *params_seen)
{
  tre_literal_t *lit;
  tre_union_t *uni;
  tre_catenation_t *cat;
  tre_iteration_t *iter;
  int i;
  int bottom = tre_stack_num_objects(stack);
  reg_errcode_t status = REG_OK;
  if (num_tags_seen)
    *num_tags_seen = 0;
  if (params_seen)
    *params_seen = 0;

  status = tre_stack_push_voidptr(stack, node);

  /* Walk through the tree recursively. */
  while (status == REG_OK && tre_stack_num_objects(stack) > bottom)
    {
      node = tre_stack_pop_voidptr(stack);

      switch (node->type)
	{
	case LITERAL:
	  lit = (tre_literal_t *)node->obj;
	  switch (lit->code_min)
	    {
	    case TAG:
	      if (lit->code_max >= 0)
		{
		  if (tags != NULL)
		    {
		      /* Add the tag to `tags'. */
		      for (i = 0; tags[i] >= 0; i++)
			if (tags[i] == lit->code_max)
			  break;
		      if (tags[i] < 0)
			{
			  tags[i] = lit->code_max;
			  tags[i + 1] = -1;
			}
		    }
		  if (num_tags_seen)
		    (*num_tags_seen)++;
		}
	      break;
	    case ASSERTION:
	      assert(lit->code_max >= 1
		     || lit->code_max <= ASSERT_LAST);
	      if (assertions != NULL)
		*assertions |= lit->code_max;
	      break;
	    case PARAMETER:
	      if (params != NULL)
		for (i = 0; i < TRE_PARAM_LAST; i++)
		  params[i] = lit->u.params[i];
	      if (params_seen != NULL)
		*params_seen = 1;
	      break;
	    case EMPTY:
	      break;
	    default:
	      assert(0);
	      break;
	    }
	  break;

	case UNION:
	  /* Subexpressions starting earlier take priority over ones
	     starting later, so we prefer the left subexpression over the
	     right subexpression. */
	  uni = (tre_union_t *)node->obj;
	  if (uni->left->nullable)
	    STACK_PUSHX(stack, voidptr, uni->left)
	  else if (uni->right->nullable)
	    STACK_PUSHX(stack, voidptr, uni->right)
	  else
	    assert(0);
	  break;

	case CATENATION:
	  /* The path must go through both children. */
	  cat = (tre_catenation_t *)node->obj;
	  assert(cat->left->nullable);
	  assert(cat->right->nullable);
	  STACK_PUSHX(stack, voidptr, cat->left);
	  STACK_PUSHX(stack, voidptr, cat->right);
	  break;

	case ITERATION:
	  /* A match with an empty string is preferred over no match at
	     all, so we go through the argument if possible. */
	  iter = (tre_iteration_t *)node->obj;
	  if (iter->arg->nullable)
	    STACK_PUSHX(stack, voidptr, iter->arg);
	  break;

	default:
	  assert(0);
	  break;
	}
    }

  return status;
}


typedef enum {
  NFL_RECURSE,
  NFL_POST_UNION,
  NFL_POST_CATENATION,
  NFL_POST_ITERATION
} tre_nfl_stack_symbol_t;


/* Computes and fills in the fields `nullable', `firstpos', and `lastpos' for
   the nodes of the AST `tree'. */
static reg_errcode_t
tre_compute_nfl(tre_mem_t mem, tre_stack_t *stack, tre_ast_node_t *tree)
{
  int bottom = tre_stack_num_objects(stack);

  STACK_PUSHR(stack, voidptr, tree);
  STACK_PUSHR(stack, int, NFL_RECURSE);

  while (tre_stack_num_objects(stack) > bottom)
    {
      tre_nfl_stack_symbol_t symbol;
      tre_ast_node_t *node;

      symbol = (tre_nfl_stack_symbol_t)tre_stack_pop_int(stack);
      node = tre_stack_pop_voidptr(stack);
      switch (symbol)
	{
	case NFL_RECURSE:
	  switch (node->type)
	    {
	    case LITERAL:
	      {
		tre_literal_t *lit = (tre_literal_t *)node->obj;
		if (IS_BACKREF(lit))
		  {
		    /* Back references: nullable = false, firstpos = {i},
		       lastpos = {i}. */
		    node->nullable = 0;
		    node->firstpos = tre_set_one(mem, lit->position, 0,
					     TRE_CHAR_MAX, 0, NULL, -1);
		    if (!node->firstpos)
		      return REG_ESPACE;
		    node->lastpos = tre_set_one(mem, lit->position, 0,
						TRE_CHAR_MAX, 0, NULL,
						lit->code_max);
		    if (!node->lastpos)
		      return REG_ESPACE;
		  }
		else if (lit->code_min < 0)
		  {
		    /* Tags, empty strings, params, and zero width assertions:
		       nullable = true, firstpos = {}, and lastpos = {}. */
		    node->nullable = 1;
		    node->firstpos = tre_set_empty(mem);
		    if (!node->firstpos)
		      return REG_ESPACE;
		    node->lastpos = tre_set_empty(mem);
		    if (!node->lastpos)
		      return REG_ESPACE;
		  }
		else
		  {
		    /* Literal at position i: nullable = false, firstpos = {i},
		       lastpos = {i}. */
		    node->nullable = 0;
		    node->firstpos =
		      tre_set_one(mem, lit->position, lit->code_min,
				  lit->code_max, 0, NULL, -1);
		    if (!node->firstpos)
		      return REG_ESPACE;
		    node->lastpos = tre_set_one(mem, lit->position,
						lit->code_min, lit->code_max,
						lit->u.class, lit->neg_classes,
						-1);
		    if (!node->lastpos)
		      return REG_ESPACE;
		  }
		break;
	      }

	    case UNION:
	      /* Compute the attributes for the two subtrees, and after that
		 for this node. */
	      STACK_PUSHR(stack, voidptr, node);
	      STACK_PUSHR(stack, int, NFL_POST_UNION);
	      STACK_PUSHR(stack, voidptr, ((tre_union_t *)node->obj)->right);
	      STACK_PUSHR(stack, int, NFL_RECURSE);
	      STACK_PUSHR(stack, voidptr, ((tre_union_t *)node->obj)->left);
	      STACK_PUSHR(stack, int, NFL_RECURSE);
	      break;

	    case CATENATION:
	      /* Compute the attributes for the two subtrees, and after that
		 for this node. */
	      STACK_PUSHR(stack, voidptr, node);
	      STACK_PUSHR(stack, int, NFL_POST_CATENATION);
	      STACK_PUSHR(stack, voidptr, ((tre_catenation_t *)node->obj)->right);
	      STACK_PUSHR(stack, int, NFL_RECURSE);
	      STACK_PUSHR(stack, voidptr, ((tre_catenation_t *)node->obj)->left);
	      STACK_PUSHR(stack, int, NFL_RECURSE);
	      break;

	    case ITERATION:
	      /* Compute the attributes for the subtree, and after that for
		 this node. */
	      STACK_PUSHR(stack, voidptr, node);
	      STACK_PUSHR(stack, int, NFL_POST_ITERATION);
	      STACK_PUSHR(stack, voidptr, ((tre_iteration_t *)node->obj)->arg);
	      STACK_PUSHR(stack, int, NFL_RECURSE);
	      break;
	    }
	  break; /* end case: NFL_RECURSE */

	case NFL_POST_UNION:
	  {
	    tre_union_t *uni = (tre_union_t *)node->obj;
	    node->nullable = uni->left->nullable || uni->right->nullable;
	    node->firstpos = tre_set_union(mem, uni->left->firstpos,
					   uni->right->firstpos, NULL, 0, NULL);
	    if (!node->firstpos)
	      return REG_ESPACE;
	    node->lastpos = tre_set_union(mem, uni->left->lastpos,
					  uni->right->lastpos, NULL, 0, NULL);
	    if (!node->lastpos)
	      return REG_ESPACE;
	    break;
	  }

	case NFL_POST_ITERATION:
	  {
	    tre_iteration_t *iter = (tre_iteration_t *)node->obj;

	    if (iter->min == 0 || iter->arg->nullable)
	      node->nullable = 1;
	    else
	      node->nullable = 0;
	    node->firstpos = iter->arg->firstpos;
	    node->lastpos = iter->arg->lastpos;
	    break;
	  }

	case NFL_POST_CATENATION:
	  {
	    int num_tags, *tags, assertions, params_seen;
	    int *params;
	    reg_errcode_t status;
	    tre_catenation_t *cat = node->obj;
	    node->nullable = cat->left->nullable && cat->right->nullable;

	    /* Compute firstpos. */
	    if (cat->left->nullable)
	      {
		/* The left side matches the empty string.  Make a first pass
		   with tre_match_empty() to get the number of tags and
		   parameters. */
		status = tre_match_empty(stack, cat->left,
					 NULL, NULL, NULL, &num_tags,
					 &params_seen);
		if (status != REG_OK)
		  return status;
		/* Allocate arrays for the tags and parameters. */
		tags = xmalloc(sizeof(*tags) * (num_tags + 1));
		if (!tags)
		  return REG_ESPACE;
		tags[0] = -1;
		assertions = 0;
		params = NULL;
		if (params_seen)
		  {
		    params = tre_mem_alloc(mem, sizeof(*params)
					   * TRE_PARAM_LAST);
		    if (!params)
		      {
			xfree(tags);
			return REG_ESPACE;
		      }
		  }
		/* Second pass with tre_mach_empty() to get the list of
		   tags and parameters. */
		status = tre_match_empty(stack, cat->left, tags,
					 &assertions, params, NULL, NULL);
		if (status != REG_OK)
		  {
		    xfree(tags);
		    return status;
		  }
		node->firstpos =
		  tre_set_union(mem, cat->right->firstpos, cat->left->firstpos,
				tags, assertions, params);
		xfree(tags);
		if (!node->firstpos)
		  return REG_ESPACE;
	      }
	    else
	      {
		node->firstpos = cat->left->firstpos;
	      }

	    /* Compute lastpos. */
	    if (cat->right->nullable)
	      {
		/* The right side matches the empty string.  Make a first pass
		   with tre_match_empty() to get the number of tags and
		   parameters. */
		status = tre_match_empty(stack, cat->right,
					 NULL, NULL, NULL, &num_tags,
					 &params_seen);
		if (status != REG_OK)
		  return status;
		/* Allocate arrays for the tags and parameters. */
		tags = xmalloc(sizeof(int) * (num_tags + 1));
		if (!tags)
		  return REG_ESPACE;
		tags[0] = -1;
		assertions = 0;
		params = NULL;
		if (params_seen)
		  {
		    params = tre_mem_alloc(mem, sizeof(*params)
					   * TRE_PARAM_LAST);
		    if (!params)
		      {
			xfree(tags);
			return REG_ESPACE;
		      }
		  }
		/* Second pass with tre_mach_empty() to get the list of
		   tags and parameters. */
		status = tre_match_empty(stack, cat->right, tags,
					 &assertions, params, NULL, NULL);
		if (status != REG_OK)
		  {
		    xfree(tags);
		    return status;
		  }
		node->lastpos =
		  tre_set_union(mem, cat->left->lastpos, cat->right->lastpos,
				tags, assertions, params);
		xfree(tags);
		if (!node->lastpos)
		  return REG_ESPACE;
	      }
	    else
	      {
		node->lastpos = cat->right->lastpos;
	      }
	    break;
	  }

	default:
	  assert(0);
	  break;
	}
    }

  return REG_OK;
}


/* Adds a transition from each position in `p1' to each position in `p2'. */
static reg_errcode_t
tre_make_trans(tre_pos_and_tags_t *p1, tre_pos_and_tags_t *p2,
	       tre_tnfa_transition_t *transitions,
	       int *counts, int *offs)
{
  tre_pos_and_tags_t *orig_p2 = p2;
  tre_tnfa_transition_t *trans;
  int i, j, k, l, dup, prev_p2_pos;

  if (transitions != NULL)
    while (p1->position >= 0)
      {
	p2 = orig_p2;
	prev_p2_pos = -1;
	while (p2->position >= 0)
	  {
	    /* Optimization: if this position was already handled, skip it. */
	    if (p2->position == prev_p2_pos)
	      {
		p2++;
		continue;
	      }
	    prev_p2_pos = p2->position;
	    /* Set `trans' to point to the next unused transition from
	       position `p1->position'. */
	    trans = transitions + offs[p1->position];
	    while (trans->state != NULL)
	      {
#if 0
		/* If we find a previous transition from `p1->position' to
		   `p2->position', it is overwritten.  This can happen only
		   if there are nested loops in the regexp, like in "((a)*)*".
		   In POSIX.2 repetition using the outer loop is always
		   preferred over using the inner loop.	 Therefore the
		   transition for the inner loop is useless and can be thrown
		   away. */
		/* XXX - The same position is used for all nodes in a bracket
		   expression, so this optimization cannot be used (it will
		   break bracket expressions) unless I figure out a way to
		   detect it here. */
		if (trans->state_id == p2->position)
		  {
		    DPRINT(("*"));
		    break;
		  }
#endif
		trans++;
	      }

	    if (trans->state == NULL)
	      (trans + 1)->state = NULL;
	    /* Use the character ranges, assertions, etc. from `p1' for
	       the transition from `p1' to `p2'. */
	    trans->code_min = p1->code_min;
	    trans->code_max = p1->code_max;
	    trans->state = transitions + offs[p2->position];
	    trans->state_id = p2->position;
	    trans->assertions = p1->assertions | p2->assertions
	      | (p1->class ? ASSERT_CHAR_CLASS : 0)
	      | (p1->neg_classes != NULL ? ASSERT_CHAR_CLASS_NEG : 0);
	    if (p1->backref >= 0)
	      {
		assert((trans->assertions & ASSERT_CHAR_CLASS) == 0);
		assert(p2->backref < 0);
		trans->u.backref = p1->backref;
		trans->assertions |= ASSERT_BACKREF;
	      }
	    else
	      trans->u.class = p1->class;
	    if (p1->neg_classes != NULL)
	      {
		for (i = 0; p1->neg_classes[i] != (tre_ctype_t)0; i++);
		trans->neg_classes =
		  xmalloc(sizeof(*trans->neg_classes) * (i + 1));
		if (trans->neg_classes == NULL)
		  return REG_ESPACE;
		for (i = 0; p1->neg_classes[i] != (tre_ctype_t)0; i++)
		  trans->neg_classes[i] = p1->neg_classes[i];
		trans->neg_classes[i] = (tre_ctype_t)0;
	      }
	    else
	      trans->neg_classes = NULL;

	    /* Find out how many tags this transition has. */
	    i = 0;
	    if (p1->tags != NULL)
	      while(p1->tags[i] >= 0)
		i++;
	    j = 0;
	    if (p2->tags != NULL)
	      while(p2->tags[j] >= 0)
		j++;

	    /* If we are overwriting a transition, free the old tag array. */
	    if (trans->tags != NULL)
	      xfree(trans->tags);
	    trans->tags = NULL;

	    /* If there were any tags, allocate an array and fill it. */
	    if (i + j > 0)
	      {
		trans->tags = xmalloc(sizeof(*trans->tags) * (i + j + 1));
		if (!trans->tags)
		  return REG_ESPACE;
		i = 0;
		if (p1->tags != NULL)
		  while(p1->tags[i] >= 0)
		    {
		      trans->tags[i] = p1->tags[i];
		      i++;
		    }
		l = i;
		j = 0;
		if (p2->tags != NULL)
		  while (p2->tags[j] >= 0)
		    {
		      /* Don't add duplicates. */
		      dup = 0;
		      for (k = 0; k < i; k++)
			if (trans->tags[k] == p2->tags[j])
			  {
			    dup = 1;
			    break;
			  }
		      if (!dup)
			trans->tags[l++] = p2->tags[j];
		      j++;
		    }
		trans->tags[l] = -1;
	      }

	    /* Set the parameter array.	 If both `p2' and `p1' have same
	       parameters, the values in `p2' override those in `p1'. */
	    if (p1->params || p2->params)
	      {
		if (!trans->params)
		  trans->params = xmalloc(sizeof(*trans->params)
					  * TRE_PARAM_LAST);
		if (!trans->params)
		  return REG_ESPACE;
		for (i = 0; i < TRE_PARAM_LAST; i++)
		  {
		    trans->params[i] = TRE_PARAM_UNSET;
		    if (p1->params && p1->params[i] != TRE_PARAM_UNSET)
		      trans->params[i] = p1->params[i];
		    if (p2->params && p2->params[i] != TRE_PARAM_UNSET)
		      trans->params[i] = p2->params[i];
		  }
	      }
	    else
	      {
		if (trans->params)
		  xfree(trans->params);
		trans->params = NULL;
	      }


#ifdef TRE_DEBUG
	    {
	      int *tags;

	      DPRINT(("	 %2d -> %2d on %3d", p1->position, p2->position,
		      p1->code_min));
	      if (p1->code_max != p1->code_min)
		DPRINT(("-%3d", p1->code_max));
	      tags = trans->tags;
	      if (tags)
		{
		  DPRINT((", tags ["));
		  while (*tags >= 0)
		    {
		      DPRINT(("%d", *tags));
		      tags++;
		      if (*tags >= 0)
			DPRINT((","));
		    }
		  DPRINT(("]"));
		}
	      if (trans->assertions)
		DPRINT((", assert %d", trans->assertions));
	      if (trans->assertions & ASSERT_BACKREF)
		DPRINT((", backref %d", trans->u.backref));
	      else if (trans->u.class)
		DPRINT((", class %ld", (long)trans->u.class));
	      if (trans->neg_classes)
		DPRINT((", neg_classes %p", trans->neg_classes));
	      if (trans->params)
		{
		  DPRINT((", "));
		  tre_print_params(trans->params);
		}
	      DPRINT(("\n"));
	    }
#endif /* TRE_DEBUG */
	    p2++;
	  }
	p1++;
      }
  else
    /* Compute a maximum limit for the number of transitions leaving
       from each state. */
    while (p1->position >= 0)
      {
	p2 = orig_p2;
	while (p2->position >= 0)
	  {
	    counts[p1->position]++;
	    p2++;
	  }
	p1++;
      }
  return REG_OK;
}

/* Converts the syntax tree to a TNFA.	All the transitions in the TNFA are
   labelled with one character range (there are no transitions on empty
   strings).  The TNFA takes O(n^2) space in the worst case, `n' is size of
   the regexp. */
static reg_errcode_t
tre_ast_to_tnfa(tre_ast_node_t *node, tre_tnfa_transition_t *transitions,
		int *counts, int *offs)
{
  tre_union_t *uni;
  tre_catenation_t *cat;
  tre_iteration_t *iter;
  reg_errcode_t errcode = REG_OK;

  /* XXX - recurse using a stack!. */
  switch (node->type)
    {
    case LITERAL:
      break;
    case UNION:
      uni = (tre_union_t *)node->obj;
      errcode = tre_ast_to_tnfa(uni->left, transitions, counts, offs);
      if (errcode != REG_OK)
	return errcode;
      errcode = tre_ast_to_tnfa(uni->right, transitions, counts, offs);
      break;

    case CATENATION:
      cat = (tre_catenation_t *)node->obj;
      /* Add a transition from each position in cat->left->lastpos
	 to each position in cat->right->firstpos. */
      errcode = tre_make_trans(cat->left->lastpos, cat->right->firstpos,
			       transitions, counts, offs);
      if (errcode != REG_OK)
	return errcode;
      errcode = tre_ast_to_tnfa(cat->left, transitions, counts, offs);
      if (errcode != REG_OK)
	return errcode;
      errcode = tre_ast_to_tnfa(cat->right, transitions, counts, offs);
      break;

    case ITERATION:
      iter = (tre_iteration_t *)node->obj;
      assert(iter->max == -1 || iter->max == 1);

      if (iter->max == -1)
	{
	  assert(iter->min == 0 || iter->min == 1);
	  /* Add a transition from each last position in the iterated
	     expression to each first position. */
	  errcode = tre_make_trans(iter->arg->lastpos, iter->arg->firstpos,
				   transitions, counts, offs);
	  if (errcode != REG_OK)
	    return errcode;
	}
      errcode = tre_ast_to_tnfa(iter->arg, transitions, counts, offs);
      break;
    }
  return errcode;
}


#define ERROR_EXIT(err)		  \
  do				  \
    {				  \
      errcode = err;		  \
      if (1) goto error_exit;	  \
    }				  \
 while (0)


int
tre_compile(regex_t *preg, const tre_char_t *regex, size_t n, int cflags)
{
  tre_stack_t *stack;
  tre_ast_node_t *tree, *tmp_ast_l, *tmp_ast_r;
  tre_pos_and_tags_t *p;
  int *counts = NULL, *offs = NULL;
  int i, add = 0;
  tre_tnfa_transition_t *transitions, *initial;
  tre_tnfa_t *tnfa = NULL;
  tre_submatch_data_t *submatch_data;
  tre_tag_direction_t *tag_directions = NULL;
  reg_errcode_t errcode;
  tre_mem_t mem;

  /* Parse context. */
  tre_parse_ctx_t parse_ctx;

  /* Allocate a stack used throughout the compilation process for various
     purposes. */
  stack = tre_stack_new(512, 10240, 128);
  if (!stack)
    return REG_ESPACE;
  /* Allocate a fast memory allocator. */
  mem = tre_mem_new();
  if (!mem)
    {
      tre_stack_destroy(stack);
      return REG_ESPACE;
    }

  /* Parse the regexp. */
  memset(&parse_ctx, 0, sizeof(parse_ctx));
  parse_ctx.mem = mem;
  parse_ctx.stack = stack;
  parse_ctx.re = regex;
  parse_ctx.len = n;
  parse_ctx.cflags = cflags;
  parse_ctx.max_backref = -1;
  DPRINT(("tre_compile: parsing '%.*" STRF "'\n", (int)n, regex));
  errcode = tre_parse(&parse_ctx);
  if (errcode != REG_OK)
    ERROR_EXIT(errcode);
  preg->re_nsub = parse_ctx.submatch_id - 1;
  tree = parse_ctx.result;

  /* Back references and approximate matching cannot currently be used
     in the same regexp. */
  if (parse_ctx.max_backref >= 0 && parse_ctx.have_approx)
    ERROR_EXIT(REG_BADPAT);

#ifdef TRE_DEBUG
  tre_ast_print(tree);
#endif /* TRE_DEBUG */

  /* Referring to nonexistent subexpressions is illegal. */
  if (parse_ctx.max_backref > (int)preg->re_nsub)
    ERROR_EXIT(REG_ESUBREG);

  /* Allocate the TNFA struct. */
  tnfa = xcalloc(1, sizeof(tre_tnfa_t));
  if (tnfa == NULL)
    ERROR_EXIT(REG_ESPACE);
  tnfa->have_backrefs = parse_ctx.max_backref >= 0;
  tnfa->have_approx = parse_ctx.have_approx;
  tnfa->num_submatches = parse_ctx.submatch_id;

  /* Set up tags for submatch addressing.  If REG_NOSUB is set and the
     regexp does not have back references, this can be skipped. */
  if (tnfa->have_backrefs || !(cflags & REG_NOSUB))
    {
      DPRINT(("tre_compile: setting up tags\n"));

      /* Figure out how many tags we will need. */
      errcode = tre_add_tags(NULL, stack, tree, tnfa);
      if (errcode != REG_OK)
	ERROR_EXIT(errcode);
#ifdef TRE_DEBUG
      tre_ast_print(tree);
#endif /* TRE_DEBUG */

      if (tnfa->num_tags > 0)
	{
	  tag_directions = xmalloc(sizeof(*tag_directions)
				   * (tnfa->num_tags + 1));
	  if (tag_directions == NULL)
	    ERROR_EXIT(REG_ESPACE);
	  tnfa->tag_directions = tag_directions;
	  memset(tag_directions, -1,
		 sizeof(*tag_directions) * (tnfa->num_tags + 1));
	}
      tnfa->minimal_tags = xcalloc(tnfa->num_tags * 2 + 1,
				   sizeof(tnfa->minimal_tags));
      if (tnfa->minimal_tags == NULL)
	ERROR_EXIT(REG_ESPACE);

      submatch_data = xcalloc(parse_ctx.submatch_id, sizeof(*submatch_data));
      if (submatch_data == NULL)
	ERROR_EXIT(REG_ESPACE);
      tnfa->submatch_data = submatch_data;

      errcode = tre_add_tags(mem, stack, tree, tnfa);
      if (errcode != REG_OK)
	ERROR_EXIT(errcode);

#ifdef TRE_DEBUG
      for (i = 0; i < parse_ctx.submatch_id; i++)
	DPRINT(("pmatch[%d] = {t%d, t%d}\n",
		i, submatch_data[i].so_tag, submatch_data[i].eo_tag));
      for (i = 0; i < tnfa->num_tags; i++)
	DPRINT(("t%d is %s\n", i,
		tag_directions[i] == TRE_TAG_MINIMIZE ?
		"minimized" : "maximized"));
#endif /* TRE_DEBUG */
    }

  /* Expand iteration nodes. */
  errcode = tre_expand_ast(mem, stack, tree, &parse_ctx.position,
			   tag_directions, &tnfa->params_depth);
  if (errcode != REG_OK)
    ERROR_EXIT(errcode);

  /* Add a dummy node for the final state.
     XXX - For certain patterns this dummy node can be optimized away,
	   for example "a*" or "ab*".	Figure out a simple way to detect
	   this possibility. */
  tmp_ast_l = tree;
  tmp_ast_r = tre_ast_new_literal(mem, 0, 0, parse_ctx.position++);
  if (tmp_ast_r == NULL)
    ERROR_EXIT(REG_ESPACE);

  tree = tre_ast_new_catenation(mem, tmp_ast_l, tmp_ast_r);
  if (tree == NULL)
    ERROR_EXIT(REG_ESPACE);

#ifdef TRE_DEBUG
  tre_ast_print(tree);
  DPRINT(("Number of states: %d\n", parse_ctx.position));
#endif /* TRE_DEBUG */

  errcode = tre_compute_nfl(mem, stack, tree);
  if (errcode != REG_OK)
    ERROR_EXIT(errcode);

  counts = xmalloc(sizeof(int) * parse_ctx.position);
  if (counts == NULL)
    ERROR_EXIT(REG_ESPACE);

  offs = xmalloc(sizeof(int) * parse_ctx.position);
  if (offs == NULL)
    ERROR_EXIT(REG_ESPACE);

  for (i = 0; i < parse_ctx.position; i++)
    counts[i] = 0;
  tre_ast_to_tnfa(tree, NULL, counts, NULL);

  add = 0;
  for (i = 0; i < parse_ctx.position; i++)
    {
      offs[i] = add;
      add += counts[i] + 1;
      counts[i] = 0;
    }
  transitions = xcalloc(add + 1, sizeof(*transitions));
  if (transitions == NULL)
    ERROR_EXIT(REG_ESPACE);
  tnfa->transitions = transitions;
  tnfa->num_transitions = add;

  DPRINT(("Converting to TNFA:\n"));
  errcode = tre_ast_to_tnfa(tree, transitions, counts, offs);
  if (errcode != REG_OK)
    ERROR_EXIT(errcode);

  /* If in eight bit mode, compute a table of characters that can be the
     first character of a match. */
  tnfa->first_char = -1;
  if (TRE_MB_CUR_MAX == 1 && !tmp_ast_l->nullable)
    {
      int count = 0;
      int k;
      DPRINT(("Characters that can start a match:"));
      tnfa->firstpos_chars = xcalloc(256, sizeof(char));
      if (tnfa->firstpos_chars == NULL)
	ERROR_EXIT(REG_ESPACE);
      for (p = tree->firstpos; p->position >= 0; p++)
	{
	  tre_tnfa_transition_t *j = transitions + offs[p->position];
	  while (j->state != NULL)
	    {
	      for (k = j->code_min; k <= j->code_max && k < 256; k++)
		{
		  DPRINT((" %d", k));
		  tnfa->firstpos_chars[k] = 1;
		  count++;
		}
	      j++;
	    }
	}
      DPRINT(("\n"));
#define TRE_OPTIMIZE_FIRST_CHAR 1
#if TRE_OPTIMIZE_FIRST_CHAR
      if (count == 1)
	{
	  for (k = 0; k < 256; k++)
	    if (tnfa->firstpos_chars[k])
	      {
		DPRINT(("first char must be %d\n", k));
		tnfa->first_char = k;
		xfree(tnfa->firstpos_chars);
		tnfa->firstpos_chars = NULL;
		break;
	      }
	}
#endif

    }
  else
    tnfa->firstpos_chars = NULL;


  p = tree->firstpos;
  i = 0;
  while (p->position >= 0)
    {
      i++;

#ifdef TRE_DEBUG
      {
	int *tags;
	DPRINT(("initial: %d", p->position));
	tags = p->tags;
	if (tags != NULL)
	  {
	    if (*tags >= 0)
	      DPRINT(("/"));
	    while (*tags >= 0)
	      {
		DPRINT(("%d", *tags));
		tags++;
		if (*tags >= 0)
		  DPRINT((","));
	      }
	  }
	DPRINT((", assert %d", p->assertions));
	if (p->params)
	  {
	    DPRINT((", "));
	    tre_print_params(p->params);
	  }
	DPRINT(("\n"));
      }
#endif /* TRE_DEBUG */

      p++;
    }

  initial = xcalloc(i + 1, sizeof(tre_tnfa_transition_t));
  if (initial == NULL)
    ERROR_EXIT(REG_ESPACE);
  tnfa->initial = initial;

  i = 0;
  for (p = tree->firstpos; p->position >= 0; p++)
    {
      initial[i].state = transitions + offs[p->position];
      initial[i].state_id = p->position;
      initial[i].tags = NULL;
      /* Copy the arrays p->tags, and p->params, they are allocated
	 from a tre_mem object. */
      if (p->tags)
	{
	  int j;
	  for (j = 0; p->tags[j] >= 0; j++);
	  initial[i].tags = xmalloc(sizeof(*p->tags) * (j + 1));
	  if (!initial[i].tags)
	    ERROR_EXIT(REG_ESPACE);
	  memcpy(initial[i].tags, p->tags, sizeof(*p->tags) * (j + 1));
	}
      initial[i].params = NULL;
      if (p->params)
	{
	  initial[i].params = xmalloc(sizeof(*p->params) * TRE_PARAM_LAST);
	  if (!initial[i].params)
	    ERROR_EXIT(REG_ESPACE);
	  memcpy(initial[i].params, p->params,
		 sizeof(*p->params) * TRE_PARAM_LAST);
	}
      initial[i].assertions = p->assertions;
      i++;
    }
  initial[i].state = NULL;

  tnfa->num_transitions = add;
  tnfa->final = transitions + offs[tree->lastpos[0].position];
  tnfa->num_states = parse_ctx.position;
  tnfa->cflags = cflags;

  DPRINT(("final state %p\n", (void *)tnfa->final));

  tre_mem_destroy(mem);
  tre_stack_destroy(stack);
  xfree(counts);
  xfree(offs);

  preg->TRE_REGEX_T_FIELD = (void *)tnfa;
  return REG_OK;

 error_exit:
  /* Free everything that was allocated and return the error code. */
  tre_mem_destroy(mem);
  if (stack != NULL)
    tre_stack_destroy(stack);
  if (counts != NULL)
    xfree(counts);
  if (offs != NULL)
    xfree(offs);
  preg->TRE_REGEX_T_FIELD = (void *)tnfa;
  tre_free(preg);
  return errcode;
}




void
tre_free(regex_t *preg)
{
  tre_tnfa_t *tnfa;
  unsigned int i;
  tre_tnfa_transition_t *trans;

  tnfa = (void *)preg->TRE_REGEX_T_FIELD;
  if (!tnfa)
    return;

  for (i = 0; i < tnfa->num_transitions; i++)
    if (tnfa->transitions[i].state)
      {
	if (tnfa->transitions[i].tags)
	  xfree(tnfa->transitions[i].tags);
	if (tnfa->transitions[i].neg_classes)
	  xfree(tnfa->transitions[i].neg_classes);
	if (tnfa->transitions[i].params)
	  xfree(tnfa->transitions[i].params);
      }
  if (tnfa->transitions)
    xfree(tnfa->transitions);

  if (tnfa->initial)
    {
      for (trans = tnfa->initial; trans->state; trans++)
	{
	  if (trans->tags)
	    xfree(trans->tags);
	  if (trans->params)
	    xfree(trans->params);
	}
      xfree(tnfa->initial);
    }

  if (tnfa->submatch_data)
    {
      for (i = 0; i < tnfa->num_submatches; i++)
	if (tnfa->submatch_data[i].parents)
	  xfree(tnfa->submatch_data[i].parents);
      xfree(tnfa->submatch_data);
    }

  if (tnfa->tag_directions)
    xfree(tnfa->tag_directions);
  if (tnfa->firstpos_chars)
    xfree(tnfa->firstpos_chars);
  if (tnfa->minimal_tags)
    xfree(tnfa->minimal_tags);
  xfree(tnfa);
}

char *
tre_version(void)
{
  static char str[256];
  char *version;

  if (str[0] == 0)
    {
      tre_config(TRE_CONFIG_VERSION, &version);
      sprintf(str, "TRE %s (LGPL)", version);
    }
  return str;
}

int
tre_config(int query, void *result)
{
  int *int_result = result;
  char **string_result = result;

  switch (query)
    {
    case TRE_CONFIG_APPROX:
#ifdef TRE_APPROX
      *int_result = 1;
#else /* !TRE_APPROX */
      *int_result = 0;
#endif /* !TRE_APPROX */
      return REG_OK;

    case TRE_CONFIG_WCHAR:
#ifdef TRE_WCHAR
      *int_result = 1;
#else /* !TRE_WCHAR */
      *int_result = 0;
#endif /* !TRE_WCHAR */
      return REG_OK;

    case TRE_CONFIG_MULTIBYTE:
#ifdef TRE_MULTIBYTE
      *int_result = 1;
#else /* !TRE_MULTIBYTE */
      *int_result = 0;
#endif /* !TRE_MULTIBYTE */
      return REG_OK;

    case TRE_CONFIG_SYSTEM_ABI:
#ifdef TRE_CONFIG_SYSTEM_ABI
      *int_result = 1;
#else /* !TRE_CONFIG_SYSTEM_ABI */
      *int_result = 0;
#endif /* !TRE_CONFIG_SYSTEM_ABI */
      return REG_OK;

    case TRE_CONFIG_VERSION:
      *string_result = TRE_VERSION;
      return REG_OK;
    }

  return REG_NOMATCH;
}


/* EOF */
