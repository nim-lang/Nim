/*
  tre-match-approx.c - TRE approximate regex matching engine

  Copyright (c) 2001-2006 Ville Laurikari <vl@iki.fi>.

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

#ifdef HAVE_CONFIG_H
#include <config.h>
#endif /* HAVE_CONFIG_H */

/* AIX requires this to be the first thing in the file.	 */
#ifdef TRE_USE_ALLOCA
#ifndef __GNUC__
# if HAVE_ALLOCA_H
#  include <alloca.h>
# else
#  ifdef _AIX
 #pragma alloca
#  else
#   ifndef alloca /* predefined by HP cc +Olibcalls */
char *alloca ();
#   endif
#  endif
# endif
#endif
#endif /* TRE_USE_ALLOCA */

#define __USE_STRING_INLINES
#undef __NO_INLINE__

#include <assert.h>
#include <stdlib.h>
#include <string.h>
#include <limits.h>
#ifdef HAVE_WCHAR_H
#include <wchar.h>
#endif /* HAVE_WCHAR_H */
#ifdef HAVE_WCTYPE_H
#include <wctype.h>
#endif /* HAVE_WCTYPE_H */
#ifndef TRE_WCHAR
#include <ctype.h>
#endif /* !TRE_WCHAR */
#ifdef HAVE_MALLOC_H
#include <malloc.h>
#endif /* HAVE_MALLOC_H */

#include "tre-internal.h"
#include "tre-match-utils.h"
#include "regex.h"
#include "xmalloc.h"

#define TRE_M_COST	0
#define TRE_M_NUM_INS	1
#define TRE_M_NUM_DEL	2
#define TRE_M_NUM_SUBST 3
#define TRE_M_NUM_ERR	4
#define TRE_M_LAST	5

#define TRE_M_MAX_DEPTH 3

typedef struct {
  /* State in the TNFA transition table. */
  tre_tnfa_transition_t *state;
  /* Position in input string. */
  int pos;
  /* Tag values. */
  int *tags;
  /* Matching parameters. */
  regaparams_t params;
  /* Nesting depth of parameters.  This is used as an index in
     the `costs' array. */
  int depth;
  /* Costs and counter values for different parameter nesting depths. */
  int costs[TRE_M_MAX_DEPTH + 1][TRE_M_LAST];
} tre_tnfa_approx_reach_t;


#ifdef TRE_DEBUG
/* Prints the `reach' array in a readable fashion with DPRINT. */
static void
tre_print_reach(const tre_tnfa_t *tnfa, tre_tnfa_approx_reach_t *reach,
		int pos, int num_tags)
{
  int id;

  /* Print each state on one line. */
  DPRINT(("  reach:\n"));
  for (id = 0; id < tnfa->num_states; id++)
    {
      int i, j;
      if (reach[id].pos < pos)
	continue;  /* Not reached. */
      DPRINT(("	 %03d, costs ", id));
      for (i = 0; i <= reach[id].depth; i++)
	{
	  DPRINT(("["));
	  for (j = 0; j < TRE_M_LAST; j++)
	    {
	      DPRINT(("%2d", reach[id].costs[i][j]));
	      if (j + 1 < TRE_M_LAST)
		DPRINT((","));
	    }
	  DPRINT(("]"));
	  if (i + 1 <= reach[id].depth)
	    DPRINT((", "));
	}
      DPRINT(("\n	tags "));
      for (i = 0; i < num_tags; i++)
	{
	  DPRINT(("%02d", reach[id].tags[i]));
	  if (i + 1 < num_tags)
	    DPRINT((","));
	}
      DPRINT(("\n"));
    }
  DPRINT(("\n"));
}
#endif /* TRE_DEBUG */


/* Sets the matching parameters in `reach' to the ones defined in the `pa'
   array.  If `pa' specifies default values, they are taken from
   `default_params'. */
inline static void
tre_set_params(tre_tnfa_approx_reach_t *reach,
	       int *pa, regaparams_t default_params)
{
  int value;

  /* If depth is increased reset costs and counters to zero for the
     new levels. */
  value = pa[TRE_PARAM_DEPTH];
  assert(value <= TRE_M_MAX_DEPTH);
  if (value > reach->depth)
    {
      int i, j;
      for (i = reach->depth + 1; i <= value; i++)
	for (j = 0; j < TRE_M_LAST; j++)
	  reach->costs[i][j] = 0;
    }
  reach->depth = value;

  /* Set insert cost. */
  value = pa[TRE_PARAM_COST_INS];
  if (value == TRE_PARAM_DEFAULT)
    reach->params.cost_ins = default_params.cost_ins;
  else if (value != TRE_PARAM_UNSET)
    reach->params.cost_ins = value;

  /* Set delete cost. */
  value = pa[TRE_PARAM_COST_DEL];
  if (value == TRE_PARAM_DEFAULT)
    reach->params.cost_del = default_params.cost_del;
  else if (value != TRE_PARAM_UNSET)
    reach->params.cost_del = value;

  /* Set substitute cost. */
  value = pa[TRE_PARAM_COST_SUBST];
  if (value == TRE_PARAM_DEFAULT)
    reach->params.cost_subst = default_params.cost_subst;
  else
    reach->params.cost_subst = value;

  /* Set maximum cost. */
  value = pa[TRE_PARAM_COST_MAX];
  if (value == TRE_PARAM_DEFAULT)
    reach->params.max_cost = default_params.max_cost;
  else if (value != TRE_PARAM_UNSET)
    reach->params.max_cost = value;

  /* Set maximum inserts. */
  value = pa[TRE_PARAM_MAX_INS];
  if (value == TRE_PARAM_DEFAULT)
    reach->params.max_ins = default_params.max_ins;
  else if (value != TRE_PARAM_UNSET)
    reach->params.max_ins = value;

  /* Set maximum deletes. */
  value = pa[TRE_PARAM_MAX_DEL];
  if (value == TRE_PARAM_DEFAULT)
    reach->params.max_del = default_params.max_del;
  else if (value != TRE_PARAM_UNSET)
    reach->params.max_del = value;

  /* Set maximum substitutes. */
  value = pa[TRE_PARAM_MAX_SUBST];
  if (value == TRE_PARAM_DEFAULT)
    reach->params.max_subst = default_params.max_subst;
  else if (value != TRE_PARAM_UNSET)
    reach->params.max_subst = value;

  /* Set maximum number of errors. */
  value = pa[TRE_PARAM_MAX_ERR];
  if (value == TRE_PARAM_DEFAULT)
    reach->params.max_err = default_params.max_err;
  else if (value != TRE_PARAM_UNSET)
    reach->params.max_err = value;
}


reg_errcode_t
tre_tnfa_run_approx(const tre_tnfa_t *tnfa, const void *string, int len,
		    tre_str_type_t type, int *match_tags,
		    regamatch_t *match, regaparams_t default_params,
		    int eflags, int *match_end_ofs)
{
  /* State variables required by GET_NEXT_WCHAR. */
  tre_char_t prev_c = 0, next_c = 0;
  const char *str_byte = string;
  int pos = -1;
  unsigned int pos_add_next = 1;
#ifdef TRE_WCHAR
  const wchar_t *str_wide = string;
#ifdef TRE_MBSTATE
  mbstate_t mbstate;
#endif /* !TRE_WCHAR */
#endif /* TRE_WCHAR */
  int reg_notbol = eflags & REG_NOTBOL;
  int reg_noteol = eflags & REG_NOTEOL;
  int reg_newline = tnfa->cflags & REG_NEWLINE;
  int str_user_end = 0;

  int prev_pos;

  /* Compilation flags for this regexp. */
  int cflags = tnfa->cflags;

  /* Number of tags. */
  int num_tags;
  /* The reach tables. */
  tre_tnfa_approx_reach_t *reach, *reach_next;
  /* Tag array for temporary use. */
  int *tmp_tags;

  /* End offset of best match so far, or -1 if no match found yet. */
  int match_eo = -1;
  /* Costs of the match. */
  int match_costs[TRE_M_LAST];

  /* Space for temporary data required for matching. */
  unsigned char *buf;

  int i, id;

  if (!match_tags)
    num_tags = 0;
  else
    num_tags = tnfa->num_tags;

#ifdef TRE_MBSTATE
  memset(&mbstate, '\0', sizeof(mbstate));
#endif /* TRE_MBSTATE */

  DPRINT(("tre_tnfa_run_approx, input type %d, len %d, eflags %d, "
	  "match_tags %p\n",
	  type, len, eflags,
	  match_tags));
  DPRINT(("max cost %d, ins %d, del %d, subst %d\n",
	  default_params.max_cost,
	  default_params.cost_ins,
	  default_params.cost_del,
	  default_params.cost_subst));

  /* Allocate memory for temporary data required for matching.	This needs to
     be done for every matching operation to be thread safe.  This allocates
     everything in a single large block from the stack frame using alloca()
     or with malloc() if alloca is unavailable. */
  {
    unsigned char *buf_cursor;
    /* Space needed for one array of tags. */
    int tag_bytes = sizeof(*tmp_tags) * num_tags;
    /* Space needed for one reach table. */
    int reach_bytes = sizeof(*reach_next) * tnfa->num_states;
    /* Total space needed. */
    int total_bytes = reach_bytes * 2 + (tnfa->num_states * 2 + 1 ) * tag_bytes;
    /* Add some extra to make sure we can align the pointers.  The multiplier
       used here must be equal to the number of ALIGN calls below. */
    total_bytes += (sizeof(long) - 1) * 3;

    /* Allocate the memory. */
#ifdef TRE_USE_ALLOCA
    buf = alloca(total_bytes);
#else /* !TRE_USE_ALLOCA */
    buf = xmalloc(total_bytes);
#endif /* !TRE_USE_ALLOCA */
    if (!buf)
      return REG_ESPACE;
    memset(buf, 0, total_bytes);

    /* Allocate `tmp_tags' from `buf'. */
    tmp_tags = (void *)buf;
    buf_cursor = buf + tag_bytes;
    buf_cursor += ALIGN(buf_cursor, long);

    /* Allocate `reach' from `buf'. */
    reach = (void *)buf_cursor;
    buf_cursor += reach_bytes;
    buf_cursor += ALIGN(buf_cursor, long);

    /* Allocate `reach_next' from `buf'. */
    reach_next = (void *)buf_cursor;
    buf_cursor += reach_bytes;
    buf_cursor += ALIGN(buf_cursor, long);

    /* Allocate tag arrays for `reach' and `reach_next' from `buf'. */
    for (i = 0; i < tnfa->num_states; i++)
      {
	reach[i].tags = (void *)buf_cursor;
	buf_cursor += tag_bytes;
	reach_next[i].tags = (void *)buf_cursor;
	buf_cursor += tag_bytes;
      }
    assert(buf_cursor <= buf + total_bytes);
  }

  for (i = 0; i < TRE_M_LAST; i++)
    match_costs[i] = INT_MAX;

  /* Mark the reach arrays empty. */
  for (i = 0; i < tnfa->num_states; i++)
    reach[i].pos = reach_next[i].pos = -2;

  prev_pos = pos;
  GET_NEXT_WCHAR();
  pos = 0;

  while (1)
    {
      DPRINT(("%03d:%2lc/%05d\n", pos, (tre_cint_t)next_c, (int)next_c));

      /* Add initial states to `reach_next' if an exact match has not yet
	 been found. */
      if (match_costs[TRE_M_COST] > 0)
	{
	  tre_tnfa_transition_t *trans;
	  DPRINT(("  init"));
	  for (trans = tnfa->initial; trans->state; trans++)
	    {
	      int id = trans->state_id;

	      /* If this state is not currently in `reach_next', add it
		 there. */
	      if (reach_next[id].pos < pos)
		{
		  if (trans->assertions && CHECK_ASSERTIONS(trans->assertions))
		    {
		      /* Assertions failed, don't add this state. */
		      DPRINT((" !%d (assert)", id));
		      continue;
		    }
		  DPRINT((" %d", id));
		  reach_next[id].state = trans->state;
		  reach_next[id].pos = pos;

		  /* Compute tag values after this transition. */
		  for (i = 0; i < num_tags; i++)
		    reach_next[id].tags[i] = -1;

		  if (trans->tags)
		    for (i = 0; trans->tags[i] >= 0; i++)
		      if (trans->tags[i] < num_tags)
			reach_next[id].tags[trans->tags[i]] = pos;

		  /* Set the parameters, depth, and costs. */
		  reach_next[id].params = default_params;
		  reach_next[id].depth = 0;
		  for (i = 0; i < TRE_M_LAST; i++)
		    reach_next[id].costs[0][i] = 0;
		  if (trans->params)
		    tre_set_params(&reach_next[id], trans->params,
				   default_params);

		  /* If this is the final state, mark the exact match. */
		  if (trans->state == tnfa->final)
		    {
		      match_eo = pos;
		      for (i = 0; i < num_tags; i++)
			match_tags[i] = reach_next[id].tags[i];
		      for (i = 0; i < TRE_M_LAST; i++)
			match_costs[i] = 0;
		    }
		}
	    }
	    DPRINT(("\n"));
	}


      /* Handle inserts.  This is done by pretending there's an epsilon
	 transition from each state in `reach' back to the same state.
	 We don't need to worry about the final state here; this will never
	 give a better match than what we already have. */
      for (id = 0; id < tnfa->num_states; id++)
	{
	  int depth;
	  int cost, cost0;

	  if (reach[id].pos != prev_pos)
	    {
	      DPRINT(("	 insert: %d not reached\n", id));
	      continue;	 /* Not reached. */
	    }

	  depth = reach[id].depth;

	  /* Compute and check cost at current depth. */
	  cost = reach[id].costs[depth][TRE_M_COST];
	  if (reach[id].params.cost_ins != TRE_PARAM_UNSET)
	    cost += reach[id].params.cost_ins;
	  if (cost > reach[id].params.max_cost)
	    continue;  /* Cost too large. */

	  /* Check number of inserts at current depth. */
	  if (reach[id].costs[depth][TRE_M_NUM_INS] + 1
	      > reach[id].params.max_ins)
	    continue;  /* Too many inserts. */

	  /* Check total number of errors at current depth. */
	  if (reach[id].costs[depth][TRE_M_NUM_ERR] + 1
	      > reach[id].params.max_err)
	    continue;  /* Too many errors. */

	  /* Compute overall cost. */
	  cost0 = cost;
	  if (depth > 0)
	    {
	      cost0 = reach[id].costs[0][TRE_M_COST];
	      if (reach[id].params.cost_ins != TRE_PARAM_UNSET)
		cost0 += reach[id].params.cost_ins;
	      else
		cost0 += default_params.cost_ins;
	    }

	  DPRINT(("  insert: from %d to %d, cost %d: ", id, id,
		  reach[id].costs[depth][TRE_M_COST]));
	  if (reach_next[id].pos == pos
	      && (cost0 >= reach_next[id].costs[0][TRE_M_COST]))
	    {
	      DPRINT(("lose\n"));
	      continue;
	    }
	  DPRINT(("win\n"));

	  /* Copy state, position, tags, parameters, and depth. */
	  reach_next[id].state = reach[id].state;
	  reach_next[id].pos = pos;
	  for (i = 0; i < num_tags; i++)
	    reach_next[id].tags[i] = reach[id].tags[i];
	  reach_next[id].params = reach[id].params;
	  reach_next[id].depth = reach[id].depth;

	  /* Set the costs after this transition. */
	  memcpy(reach_next[id].costs, reach[id].costs,
		 sizeof(reach_next[id].costs[0][0])
		 * TRE_M_LAST * (depth + 1));
	  reach_next[id].costs[depth][TRE_M_COST] = cost;
	  reach_next[id].costs[depth][TRE_M_NUM_INS]++;
	  reach_next[id].costs[depth][TRE_M_NUM_ERR]++;
	  if (depth > 0)
	    {
	      reach_next[id].costs[0][TRE_M_COST] = cost0;
	      reach_next[id].costs[0][TRE_M_NUM_INS]++;
	      reach_next[id].costs[0][TRE_M_NUM_ERR]++;
	    }

	}


      /* Handle deletes.  This is done by traversing through the whole TNFA
	 pretending that all transitions are epsilon transitions, until
	 no more states can be reached with better costs. */
      {
	/* XXX - dynamic ringbuffer size */
	tre_tnfa_approx_reach_t *ringbuffer[512];
	tre_tnfa_approx_reach_t **deque_start, **deque_end;

	deque_start = deque_end = ringbuffer;

	/* Add all states in `reach_next' to the deque. */
	for (id = 0; id < tnfa->num_states; id++)
	  {
	    if (reach_next[id].pos != pos)
	      continue;
	    *deque_end = &reach_next[id];
	    deque_end++;
	    assert(deque_end != deque_start);
	  }

	/* Repeat until the deque is empty. */
	while (deque_end != deque_start)
	  {
	    tre_tnfa_approx_reach_t *reach_p;
	    int id;
	    int depth;
	    int cost, cost0;
	    tre_tnfa_transition_t *trans;

	    /* Pop the first item off the deque. */
	    reach_p = *deque_start;
	    id = reach_p - reach_next;
	    depth = reach_p->depth;

	    /* Compute cost at current depth. */
	    cost = reach_p->costs[depth][TRE_M_COST];
	    if (reach_p->params.cost_del != TRE_PARAM_UNSET)
	      cost += reach_p->params.cost_del;

	    /* Check cost, number of deletes, and total number of errors
	       at current depth. */
	    if (cost > reach_p->params.max_cost
		|| (reach_p->costs[depth][TRE_M_NUM_DEL] + 1
		    > reach_p->params.max_del)
		|| (reach_p->costs[depth][TRE_M_NUM_ERR] + 1
		    > reach_p->params.max_err))
	      {
		/* Too many errors or cost too large. */
		DPRINT(("  delete: from %03d: cost too large\n", id));
		deque_start++;
		if (deque_start >= (ringbuffer + 512))
		  deque_start = ringbuffer;
		continue;
	      }

	    /* Compute overall cost. */
	    cost0 = cost;
	    if (depth > 0)
	      {
		cost0 = reach_p->costs[0][TRE_M_COST];
		if (reach_p->params.cost_del != TRE_PARAM_UNSET)
		  cost0 += reach_p->params.cost_del;
		else
		  cost0 += default_params.cost_del;
	      }

	    for (trans = reach_p->state; trans->state; trans++)
	      {
		int dest_id = trans->state_id;
		DPRINT(("  delete: from %03d to %03d, cost %d (%d): ",
			id, dest_id, cost0, reach_p->params.max_cost));

		if (trans->assertions && CHECK_ASSERTIONS(trans->assertions))
		  {
		    DPRINT(("assertion failed\n"));
		    continue;
		  }

		/* Compute tag values after this transition. */
		for (i = 0; i < num_tags; i++)
		  tmp_tags[i] = reach_p->tags[i];
		if (trans->tags)
		  for (i = 0; trans->tags[i] >= 0; i++)
		    if (trans->tags[i] < num_tags)
		      tmp_tags[trans->tags[i]] = pos;

		/* If another path has also reached this state, choose the one
		   with the smallest cost or best tags if costs are equal. */
		if (reach_next[dest_id].pos == pos
		    && (cost0 > reach_next[dest_id].costs[0][TRE_M_COST]
			|| (cost0 == reach_next[dest_id].costs[0][TRE_M_COST]
			    && (!match_tags
				|| !tre_tag_order(num_tags,
						  tnfa->tag_directions,
						  tmp_tags,
						  reach_next[dest_id].tags)))))
		  {
		    DPRINT(("lose, cost0 %d, have %d\n",
			    cost0, reach_next[dest_id].costs[0][TRE_M_COST]));
		    continue;
		  }
		DPRINT(("win\n"));

		/* Set state, position, tags, parameters, depth, and costs. */
		reach_next[dest_id].state = trans->state;
		reach_next[dest_id].pos = pos;
		for (i = 0; i < num_tags; i++)
		  reach_next[dest_id].tags[i] = tmp_tags[i];

		reach_next[dest_id].params = reach_p->params;
		if (trans->params)
		  tre_set_params(&reach_next[dest_id], trans->params,
				 default_params);

		reach_next[dest_id].depth = reach_p->depth;
		memcpy(&reach_next[dest_id].costs,
		       reach_p->costs,
		       sizeof(reach_p->costs[0][0])
		       * TRE_M_LAST * (depth + 1));
		reach_next[dest_id].costs[depth][TRE_M_COST] = cost;
		reach_next[dest_id].costs[depth][TRE_M_NUM_DEL]++;
		reach_next[dest_id].costs[depth][TRE_M_NUM_ERR]++;
		if (depth > 0)
		  {
		    reach_next[dest_id].costs[0][TRE_M_COST] = cost0;
		    reach_next[dest_id].costs[0][TRE_M_NUM_DEL]++;
		    reach_next[dest_id].costs[0][TRE_M_NUM_ERR]++;
		  }

		if (trans->state == tnfa->final
		    && (match_eo < 0
			|| match_costs[TRE_M_COST] > cost0
			|| (match_costs[TRE_M_COST] == cost0
			    && (num_tags > 0
				&& tmp_tags[0] <= match_tags[0]))))
		  {
		    DPRINT(("	 setting new match at %d, cost %d\n",
			    pos, cost0));
		    match_eo = pos;
		    memcpy(match_costs, reach_next[dest_id].costs[0],
			   sizeof(match_costs[0]) * TRE_M_LAST);
		    for (i = 0; i < num_tags; i++)
		      match_tags[i] = tmp_tags[i];
		  }

		/* Add to the end of the deque. */
		*deque_end = &reach_next[dest_id];
		deque_end++;
		if (deque_end >= (ringbuffer + 512))
		  deque_end = ringbuffer;
		assert(deque_end != deque_start);
	      }
	    deque_start++;
	    if (deque_start >= (ringbuffer + 512))
	      deque_start = ringbuffer;
	  }

      }

#ifdef TRE_DEBUG
      tre_print_reach(tnfa, reach_next, pos, num_tags);
#endif /* TRE_DEBUG */

      /* Check for end of string. */
      if (len < 0)
	{
	  if (type == STR_USER)
	    {
	      if (str_user_end)
		break;
	    }
	  else if (next_c == L'\0')
	    break;
	}
      else
	{
	  if (pos >= len)
	    break;
	}

      prev_pos = pos;
      GET_NEXT_WCHAR();

      /* Swap `reach' and `reach_next'. */
      {
	tre_tnfa_approx_reach_t *tmp;
	tmp = reach;
	reach = reach_next;
	reach_next = tmp;
      }

      /* Handle exact matches and substitutions. */
      for (id = 0; id < tnfa->num_states; id++)
	{
	  tre_tnfa_transition_t *trans;

	  if (reach[id].pos < prev_pos)
	    continue;  /* Not reached. */
	  for (trans = reach[id].state; trans->state; trans++)
	    {
	      int dest_id;
	      int depth;
	      int cost, cost0, err;

	      if (trans->assertions
		  && (CHECK_ASSERTIONS(trans->assertions)
		      /* Handle character class transitions. */
		      || ((trans->assertions & ASSERT_CHAR_CLASS)
			  && !(cflags & REG_ICASE)
			  && !tre_isctype((tre_cint_t)prev_c, trans->u.class))
		      || ((trans->assertions & ASSERT_CHAR_CLASS)
			  && (cflags & REG_ICASE)
			  && (!tre_isctype(tre_tolower((tre_cint_t)prev_c),
					   trans->u.class)
			      && !tre_isctype(tre_toupper((tre_cint_t)prev_c),
					      trans->u.class)))
		      || ((trans->assertions & ASSERT_CHAR_CLASS_NEG)
			  && tre_neg_char_classes_match(trans->neg_classes,
							(tre_cint_t)prev_c,
							cflags & REG_ICASE))))
		{
		  DPRINT(("  exact,  from %d: assert failed\n", id));
		  continue;
		}

	      depth = reach[id].depth;
	      dest_id = trans->state_id;

	      cost = reach[id].costs[depth][TRE_M_COST];
	      cost0 = reach[id].costs[0][TRE_M_COST];
	      err = 0;

	      if (trans->code_min > prev_c ||
		  trans->code_max < prev_c)
		{
		  /* Handle substitutes.  The required character was not in
		     the string, so match it in place of whatever was supposed
		     to be there and increase costs accordingly. */
		  err = 1;

		  /* Compute and check cost at current depth. */
		  cost = reach[id].costs[depth][TRE_M_COST];
		  if (reach[id].params.cost_subst != TRE_PARAM_UNSET)
		    cost += reach[id].params.cost_subst;
		  if (cost > reach[id].params.max_cost)
		    continue; /* Cost too large. */

		  /* Check number of substitutes at current depth. */
		  if (reach[id].costs[depth][TRE_M_NUM_SUBST] + 1
		      > reach[id].params.max_subst)
		    continue; /* Too many substitutes. */

		  /* Check total number of errors at current depth. */
		  if (reach[id].costs[depth][TRE_M_NUM_ERR] + 1
		      > reach[id].params.max_err)
		    continue; /* Too many errors. */

		  /* Compute overall cost. */
		  cost0 = cost;
		  if (depth > 0)
		    {
		      cost0 = reach[id].costs[0][TRE_M_COST];
		      if (reach[id].params.cost_subst != TRE_PARAM_UNSET)
			cost0 += reach[id].params.cost_subst;
		      else
			cost0 += default_params.cost_subst;
		    }
		  DPRINT(("  subst,  from %03d to %03d, cost %d: ",
			  id, dest_id, cost0));
		}
	      else
		DPRINT(("  exact,  from %03d to %03d, cost %d: ",
			id, dest_id, cost0));

	      /* Compute tag values after this transition. */
	      for (i = 0; i < num_tags; i++)
		tmp_tags[i] = reach[id].tags[i];
	      if (trans->tags)
		for (i = 0; trans->tags[i] >= 0; i++)
		  if (trans->tags[i] < num_tags)
		    tmp_tags[trans->tags[i]] = pos;

	      /* If another path has also reached this state, choose the
		 one with the smallest cost or best tags if costs are equal. */
	      if (reach_next[dest_id].pos == pos
		  && (cost0 > reach_next[dest_id].costs[0][TRE_M_COST]
		      || (cost0 == reach_next[dest_id].costs[0][TRE_M_COST]
			  && !tre_tag_order(num_tags, tnfa->tag_directions,
					    tmp_tags,
					    reach_next[dest_id].tags))))
		{
		  DPRINT(("lose\n"));
		  continue;
		}
	      DPRINT(("win %d %d\n",
		      reach_next[dest_id].pos,
		      reach_next[dest_id].costs[0][TRE_M_COST]));

	      /* Set state, position, tags, and depth. */
	      reach_next[dest_id].state = trans->state;
	      reach_next[dest_id].pos = pos;
	      for (i = 0; i < num_tags; i++)
		reach_next[dest_id].tags[i] = tmp_tags[i];
	      reach_next[dest_id].depth = reach[id].depth;

	      /* Set parameters. */
	      reach_next[dest_id].params = reach[id].params;
	      if (trans->params)
		tre_set_params(&reach_next[dest_id], trans->params,
			       default_params);

	      /* Set the costs after this transition. */
		memcpy(&reach_next[dest_id].costs,
		       reach[id].costs,
		       sizeof(reach[id].costs[0][0])
		       * TRE_M_LAST * (depth + 1));
	      reach_next[dest_id].costs[depth][TRE_M_COST] = cost;
	      reach_next[dest_id].costs[depth][TRE_M_NUM_SUBST] += err;
	      reach_next[dest_id].costs[depth][TRE_M_NUM_ERR] += err;
	      if (depth > 0)
		{
		  reach_next[dest_id].costs[0][TRE_M_COST] = cost0;
		  reach_next[dest_id].costs[0][TRE_M_NUM_SUBST] += err;
		  reach_next[dest_id].costs[0][TRE_M_NUM_ERR] += err;
		}

	      if (trans->state == tnfa->final
		  && (match_eo < 0
		      || cost0 < match_costs[TRE_M_COST]
		      || (cost0 == match_costs[TRE_M_COST]
			  && num_tags > 0 && tmp_tags[0] <= match_tags[0])))
		{
		  DPRINT(("    setting new match at %d, cost %d\n",
			  pos, cost0));
		  match_eo = pos;
		  for (i = 0; i < TRE_M_LAST; i++)
		    match_costs[i] = reach_next[dest_id].costs[0][i];
		  for (i = 0; i < num_tags; i++)
		    match_tags[i] = tmp_tags[i];
		}
	    }
	}
    }

  DPRINT(("match end offset = %d, match cost = %d\n", match_eo,
	  match_costs[TRE_M_COST]));

#ifndef TRE_USE_ALLOCA
  if (buf)
    xfree(buf);
#endif /* !TRE_USE_ALLOCA */

  match->cost = match_costs[TRE_M_COST];
  match->num_ins = match_costs[TRE_M_NUM_INS];
  match->num_del = match_costs[TRE_M_NUM_DEL];
  match->num_subst = match_costs[TRE_M_NUM_SUBST];
  *match_end_ofs = match_eo;

  return match_eo >= 0 ? REG_OK : REG_NOMATCH;
}
