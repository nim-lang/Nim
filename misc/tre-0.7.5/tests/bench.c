/*
  bench.c - simple regex benchmark program

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
#ifdef HAVE_GETOPT_H
#include <getopt.h>
#endif /* HAVE_GETOPT_H */
#include <time.h>
#include <unistd.h>
#include <math.h>
#include <sys/types.h>

#if 0
#include <hackerlab/rx-posix/regex.h>
#else
#include <regex.h>
#endif

/* T distribution for alpha = 0.025 (for 95% confidence).  XXX - is
   this correct? */
double t_distribution[] = {
  12.71,
  4.303,
  3.182,
  2.776,
  2.571,
  2.447,
  2.365,
  2.306,
  2.262,
  2.228,
  2.201,
  2.179,
  2.160,
  2.145,
  2.131,
  2.120,
  2.110,
  2.101,
  2.093,
  2.086,
  2.080,
  2.074,
  2.069,
  2.064,
  2.060,
  2.056,
  2.052,
  2.048,
  2.045,
  2.042
};

void
stats(double *sample_data, int samples, int len)
{
  double mean, tmp1, tmp2, variance, stddev, error, percent;
  int i;

  mean = 0;
  for (i = 0; i < samples; i++)
    mean += sample_data[i];
  mean = mean/i;
  printf("# mean: %.5f\n", mean);

  tmp1 = 0;
  for (i = 0; i < samples; i++) {
    tmp2 = sample_data[i] - mean;
    tmp1 += tmp2*tmp2;
  }
  if (samples > 1)
    variance = tmp1 / (samples-1);
  else
    variance = 0;
  stddev = sqrt(variance);
  printf("# variance: %.16f\n", variance);
  printf("# standard deviation: %.16f\n", stddev);

  error = t_distribution[samples-1] * stddev / sqrt(samples);
  if (mean != 0)
    percent = 100*error/mean;
  else
    percent = 0;
  printf("# error: ±%.16f (±%.4f%%)\n", error, percent);

  printf("%d\t%.5f\t%.5f\n", len, mean, error);

  fflush(stdout);
}

void
run_tests(int len, int samples, double *sample_data, int repeats,
	  regex_t *reobj, char *str, char *tmpbuf)
{
  int i, j, errcode;
  clock_t c1, c2;
  regmatch_t pmatch[10];


  printf("# len = %d\n", len);
  fflush(stdout);
  for (i = 0; i < samples; i++) {
    c1 = clock();
    for (j = 0; j < repeats; j++)
      if ((errcode = regexec(reobj, str, 10, pmatch, 0))) {
	regerror(errcode, reobj, tmpbuf, 255);
	printf("error: %s\n", tmpbuf);
      }
    c2 = clock();

    sample_data[i] = (double)(c2-c1)/(CLOCKS_PER_SEC*repeats);

    printf("# sample: %.5f sec, clocks: %ld\n",
	   (double)(c2-c1)/(CLOCKS_PER_SEC*repeats),
	   (long)(c2-c1));
    fflush(stdout);
  }
  fflush(stdout);

  for (i = 0; i < 10; i += 2) {
    printf("# pmatch[%d].rm_so = %d\n", i/2, (int)pmatch[i/2].rm_so);
    printf("# pmatch[%d].rm_eo = %d\n", i/2, (int)pmatch[i/2].rm_eo);
  }
}


int
main(int argc, char **argv)
{
  regex_t reobj;
  char *str;
  char tmpbuf[256];
  int i, j;
  int max_len = 1024*1024*10;
  int steps = 20;
  int repeats = 10;
  int samples = 20;
  int len;
  clock_t c1, c2;
  int opt;
  double sample_data[30];

  int test_id = -1;

  while ((opt = getopt(argc, argv, "r:l:s:j:t:")) != -1) {
    switch (opt) {
    case 't':
      test_id = atoi(optarg);
      break;
    case 'l':
      max_len = atoi(optarg);
      break;
    case 'j':
      steps = atoi(optarg);
      break;
    case 's':
      samples = atoi(optarg);
      break;
    case 'r':
      repeats = atoi(optarg);
      break;
    default:
      printf("Pälli.\n");
      return 1;
    }
  }

  /* XXX - Check that the correct results are returned.  For example, GNU
           regex-0.12 returns incorrect results for very long strings in
	   test number 1. */

  switch (test_id) {
  case 0:
    printf("# pattern: \"a*\"\n");
    printf("# string:  \"aaaaaa...\"\n");
    len = 0;
    regcomp(&reobj, "a*", REG_EXTENDED);
    while (len <= max_len) {

      str = malloc(sizeof(char) * (len+1));
      for (i = 0; i < len; i++)
	str[i] = 'a';
      str[len-1] = '\0';

      run_tests(len, samples, sample_data, repeats, &reobj, str, tmpbuf);
      stats(sample_data, samples, len);
      len = len + (max_len/steps);
      free(str);
    }
    break;


  case 1:
    printf("# pattern: \"(a)*\"\n");
    printf("# string:  \"aaaaaa...\"\n");
    len = 0;
    regcomp(&reobj, "(a)*", REG_EXTENDED);
    while (len <= max_len) {

      str = malloc(sizeof(char) * (len+1));
      for (i = 0; i < len; i++)
	str[i] = 'a';
      str[len-1] = '\0';

      run_tests(len, samples, sample_data, repeats, &reobj, str, tmpbuf);
      stats(sample_data, samples, len);
      len = len + (max_len/steps);
      free(str);
    }
    break;


  case 2:
    printf("# pattern: \"(a*)\"\n");
    printf("# string:  \"aaaaaa...\"\n");    len = 0;
    regcomp(&reobj, "(a*)", REG_EXTENDED);
    while (len <= max_len) {

      str = malloc(sizeof(char) * (len+1));
      for (i = 0; i < len; i++)
	str[i] = 'a';
      str[len-1] = '\0';

      run_tests(len, samples, sample_data, repeats, &reobj, str, tmpbuf);
      stats(sample_data, samples, len);
      len = len + (max_len/steps);
      free(str);
    }
    break;

  case 3:
    printf("# pattern: \"(a*)*|b*\"\n");
    printf("# string:  \"aaaaaa...b\"\n");
    len = 0;
    regcomp(&reobj, "(a*)*|b*", REG_EXTENDED);
    while (len <= max_len) {
      str = malloc(sizeof(char) * (len+1));
      for (i = 0; i < len-1; i++)
	str[i] = 'a';
      if (len > 0)
	str[len-1] = 'b';
      str[len] = '\0';

      run_tests(len, samples, sample_data, repeats, &reobj, str, tmpbuf);
      stats(sample_data, samples, len);
      len = len + (max_len/steps);
      free(str);
    }
    break;

  case 4:
    printf("# pattern: \"(a|a|a|...|a)\"\n");
    printf("# string:  \"aaaaaa...\"\n");
    len = 1024*1024;
    str = malloc(sizeof(char) * (len+1));
    for (i = 0; i < len-1; i++)
      str[i] = 'a';
    str[len] = '\0';
    len = 0;
    while (len <= max_len) {
      tmpbuf[0] = '(';
      for (i = 1; i < (len*2); i++) {
	tmpbuf[i] = 'a';
	if (i < len*2-2) {
	  i++;
	  tmpbuf[i] = '|';
	}
      }
      printf("# i = %d\n", i);
      tmpbuf[i] = ')';
      tmpbuf[i+1] = '*';
      tmpbuf[i+2] = '\0';
      printf("# pat = %s\n", tmpbuf);
      regcomp(&reobj, tmpbuf, REG_EXTENDED);

      run_tests(len, samples, sample_data, repeats, &reobj, str, tmpbuf);
      stats(sample_data, samples, len);
      len = len + (max_len/steps);
      regfree(&reobj);
    }
    free(str);
    break;

  case 5:
    printf("# pattern: \"foobar\"\n");
    printf("# string:  \"aaaaaa...foobar\"\n");
    len = 0;
    regcomp(&reobj, "foobar", REG_EXTENDED);
    while (len <= max_len) {
      str = malloc(sizeof(char) * (len+7));
      for (i = 0; i < len; i++) {
	if (i*i % 3)
	  str[i] = 'a';
	else
	  str[i] = 'a';
      }
      str[len+0] = 'f';
      str[len+1] = 'o';
      str[len+2] = 'o';
      str[len+3] = 'b';
      str[len+4] = 'a';
      str[len+5] = 'r';
      str[len+6] = '\0';

      run_tests(len, samples, sample_data, repeats, &reobj, str, tmpbuf);
      stats(sample_data, samples, len);
      len = len + (max_len/steps);
      free(str);
    }
    break;


  case 6:
    printf("# pattern: \"a*foobar\"\n");
    printf("# string:  \"aaaaaa...foobar\"\n");
    len = 0;
    regcomp(&reobj, "a*foobar", REG_EXTENDED);
    while (len <= max_len) {
      str = malloc(sizeof(char) * (len+7));
      for (i = 0; i < len; i++) {
	str[i] = 'a';
      }
      str[len+0] = 'f';
      str[len+1] = 'o';
      str[len+2] = 'o';
      str[len+3] = 'b';
      str[len+4] = 'a';
      str[len+5] = 'r';
      str[len+6] = '\0';

      run_tests(len, samples, sample_data, repeats, &reobj, str, tmpbuf);
      stats(sample_data, samples, len);
      len = len + (max_len/steps);
      free(str);
    }
    break;


  case 7:
    printf("# pattern: \"(a)*foobar\"\n");
    printf("# string:  \"aaaaabbaaab...foobar\"\n");
    len = 0;
    regcomp(&reobj, "(a)*foobar", REG_EXTENDED);
    while (len <= max_len) {
      str = malloc(sizeof(char) * (len+7));
      for (i = 0; i < len; i++) {
	/* Without this GNU regex won't find a match! */
	if (i*(i-1) % 3)
	  str[i] = 'b';
	else
	  str[i] = 'a';
      }
      str[len+0] = 'f';
      str[len+1] = 'o';
      str[len+2] = 'o';
      str[len+3] = 'b';
      str[len+4] = 'a';
      str[len+5] = 'r';
      str[len+6] = '\0';

      run_tests(len, samples, sample_data, repeats, &reobj, str, tmpbuf);
      stats(sample_data, samples, len);
      len = len + (max_len/steps);
      free(str);
    }
    break;


  case 8:
    printf("# pattern: \"(a|b)*foobar\"\n");
    printf("# string:  \"aaaaabbaaab...foobar\"\n");
    len = 0;
    regcomp(&reobj, "(a|b)*foobar", REG_EXTENDED);
    while (len <= max_len) {
      str = malloc(sizeof(char) * (len+7));
      for (i = 0; i < len; i++) {
	if (i*(i-1) % 3)
	  str[i] = 'b';
	else
	  str[i] = 'a';
	/* Without this GNU regex won't find a match! */
	if (i % (1024*1024*10 - 100))
	  str[i] = 'f';
      }
      str[len+0] = 'f';
      str[len+1] = 'o';
      str[len+2] = 'o';
      str[len+3] = 'b';
      str[len+4] = 'a';
      str[len+5] = 'r';
      str[len+6] = '\0';

      run_tests(len, samples, sample_data, repeats, &reobj, str, tmpbuf);
      stats(sample_data, samples, len);
      len = len + (max_len/steps);
      free(str);
    }
    break;


  case 9:
    printf("# pattern: hand-coded a*\n");
    printf("# string:  \"aaaaaa...\"\n");
    len = 0;
    while (len <= max_len) {
      printf("# len = %d\n", len);

      str = malloc(sizeof(char)*(len+1));
      for (i = 0; i < len; i++)
	str[i] = 'a';
      str[len-1] = '\0';

      for (i = 0; i < samples; i++) {
	c1 = clock();
	for (j = 0; j < repeats; j++) {
	  char *s;
	  int l;

	  s = str;
	  l = 0;


	  while (s != '\0') {
	    if (*s == 'a') {
	      s++;
	      l++;
	    } else
	      break;
	  }
	}
      	c2 = clock();
	sample_data[i] = (double)(c2-c1)/(CLOCKS_PER_SEC*repeats);

	printf("# sample: %.5f sec, clocks: %ld\n",
	       (double)(c2-c1)/(CLOCKS_PER_SEC*repeats),
	       (long)(c2-c1));
	fflush(stdout);
      }
      fflush(stdout);

      stats(sample_data, samples, len);
      len = len + (max_len/steps);
      free(str);
    }
    break;


  default:
    printf("Pelle.\n");
    return 1;
  }

  regfree(&reobj);

  return 0;
}
