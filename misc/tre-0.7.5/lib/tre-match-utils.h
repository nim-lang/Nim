/*
  tre-match-utils.h - TRE matcher helper definitions

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

#define str_source ((tre_str_source*)string)

#ifdef TRE_WCHAR

#ifdef TRE_MULTIBYTE

/* Wide character and multibyte support. */

#define GET_NEXT_WCHAR()						      \
  do {									      \
    prev_c = next_c;							      \
    if (type == STR_BYTE)						      \
      {									      \
	pos++;								      \
	if (len >= 0 && pos >= len)					      \
	  next_c = '\0';						      \
	else								      \
	  next_c = (unsigned char)(*str_byte++);			      \
      }									      \
    else if (type == STR_WIDE)						      \
      {									      \
	pos++;								      \
	if (len >= 0 && pos >= len)					      \
	  next_c = L'\0';						      \
	else								      \
	  next_c = *str_wide++;						      \
      }									      \
    else if (type == STR_MBS)						      \
      {									      \
        pos += pos_add_next;					      	      \
	if (str_byte == NULL)						      \
	  next_c = L'\0';						      \
	else								      \
	  {								      \
	    size_t w;							      \
	    int max;							      \
	    if (len >= 0)						      \
	      max = len - pos;						      \
	    else							      \
	      max = 32;							      \
	    if (max <= 0)						      \
	      {								      \
		next_c = L'\0';						      \
		pos_add_next = 1;					      \
	      }								      \
	    else							      \
	      {								      \
		w = tre_mbrtowc(&next_c, str_byte, max, &mbstate);	      \
		if (w == (size_t)-1 || w == (size_t)-2)			      \
		  return REG_NOMATCH;					      \
		if (w == 0 && len >= 0)					      \
		  {							      \
		    pos_add_next = 1;					      \
		    next_c = 0;						      \
		    str_byte++;						      \
		  }							      \
		else							      \
		  {							      \
		    pos_add_next = w;					      \
		    str_byte += w;					      \
		  }							      \
	      }								      \
	  }								      \
      }									      \
    else if (type == STR_USER)						      \
      {									      \
        pos += pos_add_next;					      	      \
	str_user_end = str_source->get_next_char(&next_c, &pos_add_next,      \
                                                 str_source->context);	      \
      }									      \
  } while(0)

#else /* !TRE_MULTIBYTE */

/* Wide character support, no multibyte support. */

#define GET_NEXT_WCHAR()						      \
  do {									      \
    prev_c = next_c;							      \
    if (type == STR_BYTE)						      \
      {									      \
	pos++;								      \
	if (len >= 0 && pos >= len)					      \
	  next_c = '\0';						      \
	else								      \
	  next_c = (unsigned char)(*str_byte++);			      \
      }									      \
    else if (type == STR_WIDE)						      \
      {									      \
	pos++;								      \
	if (len >= 0 && pos >= len)					      \
	  next_c = L'\0';						      \
	else								      \
	  next_c = *str_wide++;						      \
      }									      \
    else if (type == STR_USER)						      \
      {									      \
        pos += pos_add_next;					      	      \
	str_user_end = str_source->get_next_char(&next_c, &pos_add_next,      \
                                                 str_source->context);	      \
      }									      \
  } while(0)

#endif /* !TRE_MULTIBYTE */

#else /* !TRE_WCHAR */

/* No wide character or multibyte support. */

#define GET_NEXT_WCHAR()						      \
  do {									      \
    prev_c = next_c;							      \
    if (type == STR_BYTE)						      \
      {									      \
	pos++;								      \
	if (len >= 0 && pos >= len)					      \
	  next_c = '\0';						      \
	else								      \
	  next_c = (unsigned char)(*str_byte++);			      \
      }									      \
    else if (type == STR_USER)						      \
      {									      \
	pos += pos_add_next;						      \
	str_user_end = str_source->get_next_char(&next_c, &pos_add_next,      \
						 str_source->context);	      \
      }									      \
  } while(0)

#endif /* !TRE_WCHAR */



#define IS_WORD_CHAR(c)	 ((c) == L'_' || tre_isalnum(c))

#define CHECK_ASSERTIONS(assertions)					      \
  (((assertions & ASSERT_AT_BOL)					      \
    && (pos > 0 || reg_notbol)						      \
    && (prev_c != L'\n' || !reg_newline))				      \
   || ((assertions & ASSERT_AT_EOL)					      \
       && (next_c != L'\0' || reg_noteol)				      \
       && (next_c != L'\n' || !reg_newline))				      \
   || ((assertions & ASSERT_AT_BOW)					      \
       && (pos > 0 && (IS_WORD_CHAR(prev_c) || !IS_WORD_CHAR(next_c))))	      \
   || ((assertions & ASSERT_AT_EOW)					      \
       && (!IS_WORD_CHAR(prev_c) || IS_WORD_CHAR(next_c)))		      \
   || ((assertions & ASSERT_AT_WB)					      \
       && (pos != 0 && next_c != L'\0'					      \
	   && IS_WORD_CHAR(prev_c) == IS_WORD_CHAR(next_c)))		      \
   || ((assertions & ASSERT_AT_WB_NEG)					      \
       && (pos == 0 || next_c == L'\0'					      \
	   || IS_WORD_CHAR(prev_c) != IS_WORD_CHAR(next_c))))



/* Returns 1 if `t1' wins `t2', 0 otherwise. */
inline static int
tre_tag_order(int num_tags, tre_tag_direction_t *tag_directions,
	      int *t1, int *t2)
{
  int i;
  for (i = 0; i < num_tags; i++)
    {
      if (tag_directions[i] == TRE_TAG_MINIMIZE)
	{
	  if (t1[i] < t2[i])
	    return 1;
	  if (t1[i] > t2[i])
	    return 0;
	}
      else
	{
	  if (t1[i] > t2[i])
	    return 1;
	  if (t1[i] < t2[i])
	    return 0;
	}
    }
  /*  assert(0);*/
  return 0;
}

inline static int
tre_neg_char_classes_match(tre_ctype_t *classes, tre_cint_t wc, int icase)
{
  DPRINT(("neg_char_classes_test: %p, %d, %d\n", classes, wc, icase));
  while (*classes != (tre_ctype_t)0)
    if ((!icase && tre_isctype(wc, *classes))
	|| (icase && (tre_isctype(tre_toupper(wc), *classes)
		      || tre_isctype(tre_tolower(wc), *classes))))
      return 1; /* Match. */
    else
      classes++;
  return 0; /* No match. */
}
