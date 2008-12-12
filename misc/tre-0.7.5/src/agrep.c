/*
  agrep.c - Approximate grep

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
#include <locale.h>
#include <string.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <errno.h>
#include <assert.h>
#include <limits.h>
#include <unistd.h>
#include "getopt.h"
#include "regex.h"
#include "gettext.h"
#define _(String) gettext(String)

#undef MAX
#undef MIN
#define MAX(a, b) (((a) >= (b)) ? (a) : (b))
#define MIN(a, b) (((a) <= (b)) ? (a) : (b))

/* Short options. */
static char const short_options[] =
"cd:e:hiklnqsvwyBD:E:HI:MS:V0123456789";

static int show_help;
char *program_name;

/* Long options that have no corresponding short equivalents. */
enum {
  COLOR_OPTION = CHAR_MAX + 1,
  SHOW_POSITION_OPTION
};

/* Long option equivalences. */
static struct option const long_options[] =
{
  {"best-match", no_argument, NULL, 'B'},
  {"color", no_argument, NULL, COLOR_OPTION},
  {"colour", no_argument, NULL, COLOR_OPTION},
  {"count", no_argument, NULL, 'c'},
  {"delete-cost", required_argument, NULL, 'D'},
  {"delimiter", no_argument, NULL, 'd'},
  {"delimiter-after", no_argument, NULL, 'M'},
  {"files-with-matches", no_argument, NULL, 'l'},
  {"help", no_argument, &show_help, 1},
  {"ignore-case", no_argument, NULL, 'i'},
  {"insert-cost", required_argument, NULL, 'I'},
  {"invert-match", no_argument, NULL, 'v'},
  {"line-number", no_argument, NULL, 'n'},
  {"literal", no_argument, NULL, 'k'},
  {"max-errors", required_argument, NULL, 'E'},
  {"no-filename", no_argument, NULL, 'h'},
  {"nothing", no_argument, NULL, 'y'},
  {"quiet", no_argument, NULL, 'q'},
  {"record-number", no_argument, NULL, 'n'},
  {"regexp", required_argument, NULL, 'e'},
  {"show-cost", no_argument, NULL, 's'},
  {"show-position", no_argument, NULL, SHOW_POSITION_OPTION},
  {"silent", no_argument, NULL, 'q'},
  {"substitute-cost", required_argument, NULL, 'S'},
  {"version", no_argument, NULL, 'V'},
  {"with-filename", no_argument, NULL, 'H'},
  {"word-regexp", no_argument, NULL, 'w'},
  {0, 0, 0, 0}
};

static void
tre_agrep_usage(int status)
{
  if (status != 0)
    {
      fprintf(stderr, _("Usage: %s [OPTION]... PATTERN [FILE]...\n"),
	      program_name);
      fprintf(stderr, _("Try `%s --help' for more information.\n"),
	      program_name);
    }
  else
    {
      printf(_("Usage: %s [OPTION]... PATTERN [FILE]...\n"), program_name);
      printf(_("\
Searches for approximate matches of PATTERN in each FILE or standard input.\n\
Example: `%s -2 optimize foo.txt' outputs all lines in file `foo.txt' that\n\
match \"optimize\" within two errors.  E.g. lines which contain \"optimise\",\n\
\"optmise\", and \"opitmize\" all match.\n"), program_name);
      printf("\n");
      printf(_("\
Regexp selection and interpretation:\n\
  -e, --regexp=PATTERN	    use PATTERN as a regular expression\n\
  -i, --ignore-case	    ignore case distinctions\n\
  -k, --literal		    PATTERN is a literal string\n\
  -w, --word-regexp	    force PATTERN to match only whole words\n\
\n\
Approximate matching settings:\n\
  -D, --delete-cost=NUM	    set cost of missing characters\n\
  -I, --insert-cost=NUM	    set cost of extra characters\n\
  -S, --substitute-cost=NUM set cost of wrong characters\n\
  -E, --max-errors=NUM	    select records that have at most NUM errors\n\
  -#			    select records that have at most # errors (# is a\n\
			    digit between 0 and 9)\n\
\n\
Miscellaneous:\n\
  -d, --delimiter=PATTERN   set the record delimiter regular expression\n\
  -v, --invert-match	    select non-matching records\n\
  -V, --version		    print version information and exit\n\
  -y, --nothing		    does nothing (for compatibility with the non-free\n\
			    agrep program)\n\
      --help		    display this help and exit\n\
\n\
Output control:\n\
  -B, --best-match	    only output records with least errors\n\
  -c, --count		    only print a count of matching records per FILE\n\
  -h, --no-filename	    suppress the prefixing filename on output\n\
  -H, --with-filename	    print the filename for each match\n\
  -l, --files-with-matches  only print FILE names containing matches\n\
  -M, --delimiter-after     print record delimiter after record if -d is used\n\
  -n, --record-number	    print record number with output\n\
      --line-number         same as -n\n\
  -q, --quiet, --silent	    suppress all normal output\n\
  -s, --show-cost	    print match cost with output\n\
      --colour, --color     use markers to distinguish the matching \
strings\n\
      --show-position       prefix each output record with start and end\n\
                            position of the first match within the record\n"));
      printf("\n");
      printf(_("\
With no FILE, or when FILE is -, reads standard input.  If less than two\n\
FILEs are given, -h is assumed.  Exit status is 0 if a match is found, 1 for\n\
no match, and 2 if there were errors.  If -E or -# is not specified, only\n\
exact matches are selected.\n"));
      printf("\n");
      printf(_("\
PATTERN is a POSIX extended regular expression (ERE) with the TRE extensions.\n\
See tre(7) for a complete description.\n"));
      printf("\n");
      printf(_("Report bugs to: "));
      printf("%s.\n", PACKAGE_BUGREPORT);
    }
  exit(status);
}

static regex_t preg;	  /* Compiled pattern to search for. */
static regex_t delim;	  /* Compiled record delimiter pattern. */

#define INITIAL_BUF_SIZE 10240	/* Initial size of the buffer. */
static char *buf;	   /* Buffer for scanning text. */
static int buf_size;	   /* Current size of the buffer. */
static int data_len;	   /* Amount of data in the buffer. */
static char *record;	   /* Start of current record. */
static char *next_record;  /* Start of next record. */
static int record_len;	   /* Length of current record. */
static int delim_len;      /* Length of delimiter before record. */
static int next_delim_len; /* Length of delimiter after record. */
static int delim_after = 1;/* If true, print the delimiter after the record. */
static int at_eof;
static int have_matches;   /* If true, matches have been found. */

static int invert_match;   /* Show only non-matching records. */
static int print_filename; /* Output filename. */
static int print_recnum;   /* Output record number. */
static int print_cost;	   /* Output match cost. */
static int count_matches;  /* Count matching records. */
static int list_files;	   /* List matching files. */
static int color_option;   /* Highlight matches. */
static int print_position;  /* Show start and end offsets for matches. */

static int best_match;	     /* Output only best matches. */
static int best_cost;	     /* Best match cost found so far. */
static int be_silent;	     /* Never output anything */

static regaparams_t match_params;

/* The color string used with the --color option.  If set, the
   environment variable GREP_COLOR overrides this default value. */
static char *highlight = "01;31";

/* Sets `record' to the next complete record from file `fd', and `record_len'
   to the length of the record.	 Returns 1 when there are no more records,
   0 otherwise. */
static inline int
tre_agrep_get_next_record(int fd, const char *filename)
{
  if (at_eof)
    return 1;

  while (1)
    {
      int errcode;
      regmatch_t pmatch[1];

      if (next_record == NULL)
	{
	  int r;
	  int read_size = buf_size - data_len;

	  if (read_size <= 0)
	    {
	      /* The buffer is full and no record delimiter found yet,
		 we need to grow the buffer.  We double the size to
		 avoid rescanning the data too many times when the
		 records are very large. */
	      buf_size *= 2;
	      buf = realloc(buf, buf_size);
	      if (buf == NULL)
		{
		  fprintf(stderr, "%s: %s\n", program_name, _("Out of memory"));
		  exit(2);
		}
	      read_size = buf_size - data_len;
	    }

	  r = read(fd, buf + data_len, read_size);
	  if (r < 0)
	    {
	      /* Read error. */
	      char *err;
	      if (errno == EINTR)
		continue;
	      err = strerror(errno);
	      fprintf(stderr, "%s: ", program_name);
	      fprintf(stderr, _("Error reading from %s: %s\n"), filename, err);
	      return 1;
	    }

	  if (r == 0)
	    {
	      /* End of file.  Return the last record. */
	      record = buf;
	      record_len = data_len;
	      at_eof = 1;
	      /* The empty string after a trailing delimiter is not considered
		 to be a record. */
	      if (record_len == 0)
		return 1;
	      return 0;
	    }
	  data_len += r;
	  next_record = buf;
	}

      /* Find the next record delimiter. */
      errcode = regnexec(&delim, next_record, data_len - (next_record - buf),
			 1, pmatch, 0);


      switch (errcode)
	{
	case REG_OK:
	  /* Record delimiter found, now we know how long the current
	     record is. */
	  record = next_record;
	  record_len = pmatch[0].rm_so;
	  delim_len = next_delim_len;

	  next_delim_len = pmatch[0].rm_eo - pmatch[0].rm_so;
	  next_record = next_record + pmatch[0].rm_eo;
	  return 0;
	  break;

	case REG_NOMATCH:
	  if (next_record == buf)
	    {
	      next_record = NULL;
	      continue;
	    }

	  /* Move the data to start of the buffer and read more
	     data. */
	  memmove(buf, next_record, buf + data_len - next_record);
	  data_len = buf + data_len - next_record;
	  next_record = NULL;
	  continue;
	  break;

	case REG_ESPACE:
	  fprintf(stderr, "%s: %s\n", program_name, _("Out of memory"));
	  exit(2);
	  break;

	default:
	  assert(0);
	  break;
	}
    }
}


static int
tre_agrep_handle_file(const char *filename)
{
  int fd;
  int count = 0;
  int recnum = 0;

  /* Allocate the initial buffer. */
  if (buf == NULL)
    {
      buf = malloc(INITIAL_BUF_SIZE);
      if (buf == NULL)
	{
	  fprintf(stderr, "%s: %s\n", program_name, _("Out of memory"));
	  exit(2);
	}
      buf_size = INITIAL_BUF_SIZE;
    }

  /* Reset read buffer state. */
  next_record = NULL;
  data_len = 0;

  if (!filename || strcmp(filename, "-") == 0)
    {
      if (best_match)
	{
	  fprintf(stderr, "%s: %s\n", program_name,
		  _("Cannot use -B when reading from standard input."));
	  return 2;
	}
      fd = 0;
      filename = _("(standard input)");
    }
  else
    {
      fd = open(filename, O_RDONLY);
    }

  if (fd < 0)
    {
      fprintf(stderr, "%s: %s: %s\n", program_name, filename, strerror(errno));
      return 1;
    }


  /* Go through all records and output the matching ones, or the non-matching
     ones if `invert_match' is true. */
  at_eof = 0;
  while (!tre_agrep_get_next_record(fd, filename))
    {
      int errcode;
      regamatch_t match;
      regmatch_t pmatch[1];
      recnum++;
      memset(&match, 0, sizeof(match));
      if (best_match)
	match_params.max_cost = best_cost;
      if (color_option || print_position)
	{
	  match.pmatch = pmatch;
	  match.nmatch = 1;
	}

      /* Stop searching for better matches if an exact match is found. */
      if (best_match == 1 && best_cost == 0)
	break;

      /* See if the record matches. */
      errcode = reganexec(&preg, record, record_len, &match, match_params, 0);
      if ((!invert_match && errcode == REG_OK)
	  || (invert_match && errcode == REG_NOMATCH))
	{
	  if (be_silent)
	    exit(0);

	  count++;
	  have_matches = 1;
	  if (best_match)
	    {
	      if (best_match == 1)
		{
		  /* First best match pass. */
		  if (match.cost < best_cost)
		    best_cost = match.cost;
		  continue;
		}
	      /* Second best match pass. */
	      if (match.cost > best_cost)
		continue;
	    }

	  if (list_files)
	    {
	      printf("%s\n", filename);
	      break;
	    }
	  else if (!count_matches)
	    {
	      if (print_filename)
		printf("%s:", filename);
	      if (print_recnum)
		printf("%d:", recnum);
	      if (print_cost)
		printf("%d:", match.cost);
	      if (print_position)
		printf("%d-%d:",
		       invert_match ? 0 : (int)pmatch[0].rm_so,
		       invert_match ? record_len : (int)pmatch[0].rm_eo);

	      /* Adjust record boundaries so we print the delimiter
		 before or after the record. */
	      if (delim_after)
		{
		  record_len += next_delim_len;
		}
	      else
		{
		  record -= delim_len;
		  record_len += delim_len;
		  pmatch[0].rm_so += delim_len;
		  pmatch[0].rm_eo += delim_len;
		}

	      if (color_option && !invert_match)
		{
		  printf("%.*s", (int)pmatch[0].rm_so, record);
		  printf("\33[%sm", highlight);
		  printf("%.*s", (int)(pmatch[0].rm_eo - pmatch[0].rm_so),
			 record + pmatch[0].rm_so);
		  fputs("\33[00m", stdout);
		  printf("%.*s", (int)(record_len - pmatch[0].rm_eo),
			 record + pmatch[0].rm_eo);
		}
	      else
		{
		  printf("%.*s", record_len, record);
		}
	    }
	}
    }

  if (count_matches && !best_match && !be_silent)
    {
      if (print_filename)
	printf("%s:", filename);
      printf("%d\n", count);
    }

  if (fd)
    close(fd);

  return 0;
}



int
main(int argc, char **argv)
{
  int c, errcode;
  int comp_flags = REG_EXTENDED;
  char *tmp_str;
  char *regexp = NULL;
  char *delim_regexp = "\n";
  int word_regexp = 0;
  int literal_string = 0;
  int max_cost_set = 0;

  setlocale (LC_ALL, "");
  bindtextdomain (PACKAGE, LOCALEDIR);
  textdomain (PACKAGE);

  /* Get the program name without the path (for error messages etc). */
  program_name = argv[0];
  if (program_name)
    {
      tmp_str = strrchr(program_name, '/');
      if (tmp_str)
	program_name = tmp_str + 1;
    }

  /* Defaults. */
  print_filename = -1;
  print_cost = 0;
  be_silent = 0;
  regaparams_default(&match_params);
  match_params.max_cost = 0;

  /* Parse command line options. */
  while (1)
    {
      c = getopt_long(argc, argv, short_options, long_options, NULL);
      if (c == -1)
	break;

      switch (c)
	{
	case 'c':
	  /* Count number of matching records. */
	  count_matches = 1;
	  break;
	case 'd':
	  /* Set record delimiter regexp. */
	  delim_regexp = optarg;
	  if (delim_after == 1)
	    delim_after = 0;
	  break;
	case 'e':
	  /* Regexp to use. */
	  regexp = optarg;
	  break;
	case 'h':
	  /* Don't prefix filename on output if there are multiple files. */
	  print_filename = 0;
	  break;
	case 'i':
	  /* Ignore case. */
	  comp_flags |= REG_ICASE;
	  break;
	case 'k':
	  /* The pattern is a literal string. */
	  literal_string = 1;
	  break;
	case 'l':
	  /* Only print files that contain matches. */
	  list_files = 1;
	  break;
	case 'n':
	  /* Print record number of matching record. */
	  print_recnum = 1;
	  break;
	case 'q':
	  be_silent = 1;
	  break;
	case 's':
	  /* Print match cost of matching record. */
	  print_cost = 1;
	  break;
	case 'v':
	  /* Select non-matching records. */
	  invert_match = 1;
	  break;
	case 'w':
	  /* Match only whole words. */
	  word_regexp = 1;
	  break;
	case 'y':
	  /* Compatibility option, does nothing. */
	  break;
	case 'B':
	  /* Select only the records which have the best match. */
	  best_match = 1;
	  break;
	case 'D':
	  /* Set the cost of a deletion. */
	  match_params.cost_del = atoi(optarg);
	  break;
	case 'E':
	  /* Set the maximum number of errors allowed for a record to match. */
	  match_params.max_cost = atoi(optarg);
	  max_cost_set = 1;
	  break;
	case 'H':
	  /* Always print filename prefix on output. */
	  print_filename = 1;
	  break;
	case 'I':
	  /* Set the cost of an insertion. */
	  match_params.cost_ins = atoi(optarg);
	  break;
	case 'M':
	  /* Print delimiters after matches instead of before. */
	  delim_after = 2;
	  break;
	case 'S':
	  /* Set the cost of a substitution. */
	  match_params.cost_subst = atoi(optarg);
	  break;
	case 'V':
	  {
	    /* Print version string and exit. */
	    char *version;
	    tre_config(TRE_CONFIG_VERSION, &version);
	    printf("%s (TRE agrep) %s\n\n", program_name, version);
	    printf(_("Copyright (c) 2002-2006 Ville Laurikari.\n"));
	    printf(_("\
This is free software; see the source for copying conditions. There is NO\n\
warranty; not even for MERCHANTABILITY or FITNESS FOR A \
PARTICULAR PURPOSE.\n"));
	    printf("\n");
	    exit(0);
	    break;
	  }
	case '?':
	  /* Ambiguous match or extraneous parameter. */
	  break;
	case COLOR_OPTION:
	  color_option = 1;
	  break;
	case SHOW_POSITION_OPTION:
	  print_position = 1;
	  break;
	case 0:
	  /* Long options without corresponding short options. */
	  break;

	default:
	  if (c >= '0' && c <= '9')
	    match_params.max_cost = c - '0';
	  else
	    tre_agrep_usage(2);
	  max_cost_set = 1;
	  break;
	}
    }

  if (show_help)
    tre_agrep_usage(0);

  if (color_option)
    {
      char *user_highlight = getenv("GREP_COLOR");
      if (user_highlight && *user_highlight != '\0')
	highlight = user_highlight;
    }

  /* Get the pattern. */
  if (regexp == NULL)
    {
      if (optind >= argc)
	tre_agrep_usage(2);
      regexp = argv[optind++];
    }

  /* If -k is specified, make the regexp literal.  This uses
     the \Q and \E extensions.	If the string already contains
     occurrences of \E, we need to handle them separately.  This is a
     pain, but can't really be avoided if we want to create a regexp
     which works together with -w (see below). */
  if (literal_string)
    {
      char *next_pos = regexp;
      char *new_re, *new_re_end;
      int n = 0;
      int len;

      next_pos = regexp;
      while (next_pos)
	{
	  next_pos = strstr(next_pos, "\\E");
	  if (next_pos)
	    {
	      n++;
	      next_pos += 2;
	    }
	}

      len = strlen(regexp);
      new_re = malloc(len + 5 + n * 7);
      if (!new_re)
	{
	  fprintf(stderr, "%s: %s\n", program_name, _("Out of memory"));
	  return 2;
	}

      next_pos = regexp;
      new_re_end = new_re;
      strcpy(new_re_end, "\\Q");
      new_re_end += 2;
      while (next_pos)
	{
	  char *start = next_pos;
	  next_pos = strstr(next_pos, "\\E");
	  if (next_pos)
	    {
	      strncpy(new_re_end, start, next_pos - start);
	      new_re_end += next_pos - start;
	      strcpy(new_re_end, "\\E\\\\E\\Q");
	      new_re_end += 7;
	      next_pos += 2;
	    }
	  else
	    {
	      strcpy(new_re_end, start);
	      new_re_end += strlen(start);
	    }
	}
      strcpy(new_re_end, "\\E");
      regexp = new_re;
    }

  /* If -w is specified, prepend beginning-of-word and end-of-word
     assertions to the regexp before compiling. */
  if (word_regexp)
    {
      char *tmp = regexp;
      int len = strlen(tmp);
      regexp = malloc(len + 7);
      if (regexp == NULL)
	{
	  fprintf(stderr, "%s: %s\n", program_name, _("Out of memory"));
	  return 2;
	}
      strcpy(regexp, "\\<(");
      strcpy(regexp + 3, tmp);
      strcpy(regexp + len + 3, ")\\>");
    }

  /* Compile the pattern. */
  errcode = regcomp(&preg, regexp, comp_flags);
  if (errcode)
    {
      char errbuf[256];
      regerror(errcode, &preg, errbuf, sizeof(errbuf));
      fprintf(stderr, "%s: %s: %s\n",
	      program_name, _("Error in search pattern"), errbuf);
      return 2;
    }

  /* Compile the record delimiter pattern. */
  errcode = regcomp(&delim, delim_regexp, REG_EXTENDED | REG_NEWLINE);
  if (errcode)
    {
      char errbuf[256];
      regerror(errcode, &preg, errbuf, sizeof(errbuf));
      fprintf(stderr, "%s: %s: %s\n",
	      program_name, _("Error in record delimiter pattern"), errbuf);
      return 2;
    }

  if (regexec(&delim, "", 0, NULL, 0) == REG_OK)
    {
      fprintf(stderr, "%s: %s\n", program_name,
	      _("Record delimiter pattern must not match an empty string"));
      return 2;
    }

  /* The rest of the arguments are file(s) to match. */

  /* If -h or -H were not specified, print filenames if there are more
     than one files specified. */
  if (print_filename == -1)
    {
      if (argc - optind <= 1)
	print_filename = 0;
      else
	print_filename = 1;
    }

  if (optind >= argc)
    {
      /* There are no files specified, read from stdin. */
      tre_agrep_handle_file(NULL);
    }
  else if (best_match)
    {
      int first_ind = optind;

      /* Best match mode.  Set up the limits first. */
      if (!max_cost_set)
	match_params.max_cost = INT_MAX;
      best_cost = INT_MAX;

      /* Scan all files once without outputting anything, searching
	 for the best matches. */
      while (optind < argc)
	tre_agrep_handle_file(argv[optind++]);

      /* If there were no matches, bail out now. */
      if (best_cost == INT_MAX)
	return 1;

      /* Otherwise, rescan the files with max_cost set to the cost
	 of the best match found previously, this time outputting
	 the matches. */
      match_params.max_cost = best_cost;
      best_match = 2;
      optind = first_ind;
      while (optind < argc)
	tre_agrep_handle_file(argv[optind++]);
    }
  else
    {
      /* Normal mode. */
      while (optind < argc)
	tre_agrep_handle_file(argv[optind++]);
    }

  return have_matches == 0;
}
