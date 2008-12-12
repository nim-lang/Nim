/*
  regexec.c - TRE POSIX compatible matching functions (and more).

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

#ifdef TRE_USE_ALLOCA
/* AIX requires this to be the first thing in the file.	 */
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

#include <assert.h>
#include <stdlib.h>
#include <string.h>
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
#include <limits.h>

#include "tre-internal.h"
#include "regex.h"
#include "xmalloc.h"


/* Fills the POSIX.2 regmatch_t array according to the TNFA tag and match
   endpoint values. */
void
tre_fill_pmatch(size_t nmatch, regmatch_t pmatch[], int cflags,
		const tre_tnfa_t *tnfa, int *tags, int match_eo)
{
  tre_submatch_data_t *submatch_data;
  unsigned int i, j;
  int *parents;

  i = 0;
  if (match_eo >= 0 && !(cflags & REG_NOSUB))
    {
      /* Construct submatch offsets from the tags. */
      DPRINT(("end tag = t%d = %d\n", tnfa->end_tag, match_eo));
      submatch_data = tnfa->submatch_data;
      while (i < tnfa->num_submatches && i < nmatch)
	{
	  if (submatch_data[i].so_tag == tnfa->end_tag)
	    pmatch[i].rm_so = match_eo;
	  else
	    pmatch[i].rm_so = tags[submatch_data[i].so_tag];

	  if (submatch_data[i].eo_tag == tnfa->end_tag)
	    pmatch[i].rm_eo = match_eo;
	  else
	    pmatch[i].rm_eo = tags[submatch_data[i].eo_tag];

	  /* If either of the endpoints were not used, this submatch
	     was not part of the match. */
	  if (pmatch[i].rm_so == -1 || pmatch[i].rm_eo == -1)
	    pmatch[i].rm_so = pmatch[i].rm_eo = -1;

	  DPRINT(("pmatch[%d] = {t%d = %d, t%d = %d}\n", i,
		  submatch_data[i].so_tag, pmatch[i].rm_so,
		  submatch_data[i].eo_tag, pmatch[i].rm_eo));
	  i++;
	}
      /* Reset all submatches that are not within all of their parent
	 submatches. */
      i = 0;
      while (i < tnfa->num_submatches && i < nmatch)
	{
	  if (pmatch[i].rm_eo == -1)
	    assert(pmatch[i].rm_so == -1);
	  assert(pmatch[i].rm_so <= pmatch[i].rm_eo);

	  parents = submatch_data[i].parents;
	  if (parents != NULL)
	    for (j = 0; parents[j] >= 0; j++)
	      {
		DPRINT(("pmatch[%d] parent %d\n", i, parents[j]));
		if (pmatch[i].rm_so < pmatch[parents[j]].rm_so
		    || pmatch[i].rm_eo > pmatch[parents[j]].rm_eo)
		  pmatch[i].rm_so = pmatch[i].rm_eo = -1;
	      }
	  i++;
	}
    }

  while (i < nmatch)
    {
      pmatch[i].rm_so = -1;
      pmatch[i].rm_eo = -1;
      i++;
    }
}


/*
  Wrapper functions for POSIX compatible regexp matching.
*/

int
tre_have_backrefs(const regex_t *preg)
{
  tre_tnfa_t *tnfa = (void *)preg->TRE_REGEX_T_FIELD;
  return tnfa->have_backrefs;
}

int
tre_have_approx(const regex_t *preg)
{
  tre_tnfa_t *tnfa = (void *)preg->TRE_REGEX_T_FIELD;
  return tnfa->have_approx;
}

static int
tre_match(const tre_tnfa_t *tnfa, const void *string, size_t len,
	  tre_str_type_t type, size_t nmatch, regmatch_t pmatch[],
	  int eflags)
{
  reg_errcode_t status;
  int *tags = NULL, eo;
  if (tnfa->num_tags > 0 && nmatch > 0)
    {
#ifdef TRE_USE_ALLOCA
      tags = alloca(sizeof(*tags) * tnfa->num_tags);
#else /* !TRE_USE_ALLOCA */
      tags = xmalloc(sizeof(*tags) * tnfa->num_tags);
#endif /* !TRE_USE_ALLOCA */
      if (tags == NULL)
	return REG_ESPACE;
    }

  /* Dispatch to the appropriate matcher. */
  if (tnfa->have_backrefs || eflags & REG_BACKTRACKING_MATCHER)
    {
      /* The regex has back references, use the backtracking matcher. */
      if (type == STR_USER)
	{
	  const tre_str_source *source = string;
	  if (source->rewind == NULL || source->compare == NULL)
	    /* The backtracking matcher requires rewind and compare
	       capabilities from the input stream. */
	    return REG_BADPAT;
	}
      status = tre_tnfa_run_backtrack(tnfa, string, len, type,
				      tags, eflags, &eo);
    }
#ifdef TRE_APPROX
  else if (tnfa->have_approx || eflags & REG_APPROX_MATCHER)
    {
      /* The regex uses approximate matching, use the approximate matcher. */
      regamatch_t match;
      regaparams_t params;
      regaparams_default(&params);
      params.max_err = 0;
      params.max_cost = 0;
      status = tre_tnfa_run_approx(tnfa, string, len, type, tags,
				   &match, params, eflags, &eo);
    }
#endif /* TRE_APPROX */
  else
    {
      /* Exact matching, no back references, use the parallel matcher. */
      status = tre_tnfa_run_parallel(tnfa, string, len, type,
				     tags, eflags, &eo);
    }

  if (status == REG_OK)
    /* A match was found, so fill the submatch registers. */
    tre_fill_pmatch(nmatch, pmatch, tnfa->cflags, tnfa, tags, eo);
#ifndef TRE_USE_ALLOCA
  if (tags)
    xfree(tags);
#endif /* !TRE_USE_ALLOCA */
  return status;
}

int
regnexec(const regex_t *preg, const char *str, size_t len,
	 size_t nmatch, regmatch_t pmatch[], int eflags)
{
  tre_tnfa_t *tnfa = (void *)preg->TRE_REGEX_T_FIELD;
  tre_str_type_t type = (TRE_MB_CUR_MAX == 1) ? STR_BYTE : STR_MBS;

  return tre_match(tnfa, str, len, type, nmatch, pmatch, eflags);
}

int
regexec(const regex_t *preg, const char *str,
	size_t nmatch, regmatch_t pmatch[], int eflags)
{
  return regnexec(preg, str, -1, nmatch, pmatch, eflags);
}


#ifdef TRE_WCHAR

int
regwnexec(const regex_t *preg, const wchar_t *str, size_t len,
	  size_t nmatch, regmatch_t pmatch[], int eflags)
{
  tre_tnfa_t *tnfa = (void *)preg->TRE_REGEX_T_FIELD;
  return tre_match(tnfa, str, len, STR_WIDE, nmatch, pmatch, eflags);
}

int
regwexec(const regex_t *preg, const wchar_t *str,
	 size_t nmatch, regmatch_t pmatch[], int eflags)
{
  return regwnexec(preg, str, -1, nmatch, pmatch, eflags);
}

#endif /* TRE_WCHAR */

int
reguexec(const regex_t *preg, const tre_str_source *str,
	 size_t nmatch, regmatch_t pmatch[], int eflags)
{
  tre_tnfa_t *tnfa = (void *)preg->TRE_REGEX_T_FIELD;
  return tre_match(tnfa, str, -1, STR_USER, nmatch, pmatch, eflags);
}


#ifdef TRE_APPROX

/*
  Wrapper functions for approximate regexp matching.
*/

static int
tre_match_approx(const tre_tnfa_t *tnfa, const void *string, size_t len,
		 tre_str_type_t type, regamatch_t *match, regaparams_t params,
		 int eflags)
{
  reg_errcode_t status;
  int *tags = NULL, eo;

  /* If the regexp does not use approximate matching features, the
     maximum cost is zero, and the approximate matcher isn't forced,
     use the exact matcher instead. */
  if (params.max_cost == 0 && !tnfa->have_approx
      && !(eflags & REG_APPROX_MATCHER))
    return tre_match(tnfa, string, len, type, match->nmatch, match->pmatch,
		     eflags);

  /* Back references are not supported by the approximate matcher. */
  if (tnfa->have_backrefs)
    return REG_BADPAT;

  if (tnfa->num_tags > 0 && match->nmatch > 0)
    {
#if TRE_USE_ALLOCA
      tags = alloca(sizeof(*tags) * tnfa->num_tags);
#else /* !TRE_USE_ALLOCA */
      tags = xmalloc(sizeof(*tags) * tnfa->num_tags);
#endif /* !TRE_USE_ALLOCA */
      if (tags == NULL)
	return REG_ESPACE;
    }
  status = tre_tnfa_run_approx(tnfa, string, len, type, tags,
			       match, params, eflags, &eo);
  if (status == REG_OK)
    tre_fill_pmatch(match->nmatch, match->pmatch, tnfa->cflags, tnfa, tags, eo);
#ifndef TRE_USE_ALLOCA
  if (tags)
    xfree(tags);
#endif /* !TRE_USE_ALLOCA */
  return status;
}

int
reganexec(const regex_t *preg, const char *str, size_t len,
	  regamatch_t *match, regaparams_t params, int eflags)
{
  tre_tnfa_t *tnfa = (void *)preg->TRE_REGEX_T_FIELD;
  tre_str_type_t type = (TRE_MB_CUR_MAX == 1) ? STR_BYTE : STR_MBS;

  return tre_match_approx(tnfa, str, len, type, match, params, eflags);
}

int
regaexec(const regex_t *preg, const char *str,
	 regamatch_t *match, regaparams_t params, int eflags)
{
  return reganexec(preg, str, -1, match, params, eflags);
}

#ifdef TRE_WCHAR

int
regawnexec(const regex_t *preg, const wchar_t *str, size_t len,
	   regamatch_t *match, regaparams_t params, int eflags)
{
  tre_tnfa_t *tnfa = (void *)preg->TRE_REGEX_T_FIELD;
  return tre_match_approx(tnfa, str, len, STR_WIDE,
			  match, params, eflags);
}

int
regawexec(const regex_t *preg, const wchar_t *str,
	  regamatch_t *match, regaparams_t params, int eflags)
{
  return regawnexec(preg, str, -1, match, params, eflags);
}

#endif /* TRE_WCHAR */

void
regaparams_default(regaparams_t *params)
{
  memset(params, 0, sizeof(*params));
  params->cost_ins = 1;
  params->cost_del = 1;
  params->cost_subst = 1;
  params->max_cost = INT_MAX;
  params->max_ins = INT_MAX;
  params->max_del = INT_MAX;
  params->max_subst = INT_MAX;
  params->max_err = INT_MAX;
}

#endif /* TRE_APPROX */

/* EOF */
