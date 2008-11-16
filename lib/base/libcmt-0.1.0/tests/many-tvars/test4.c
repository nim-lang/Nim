/*
 * 'orElse' composition test.
 *
 * A simple test of one thread performing an alternative of two transactions
 * that will try to decrement the shared variables 'shared_i' and 'shared_j'
 * if they are greater than a fixed value, blocking otherwise, while other
 * threads are performing a transaction that try to increment the same shared
 * variables.
 */

#include <gtransaction.h>

#define NR_THREADS            3
#define MAX_SECONDS_TO_SLEEP  3
#define N                     3

#define G_COMPARE_FUNC(f)   ((gint(*)(gconstpointer,gconstpointer))(f))
#define G_TVAR_COPY_FUNC(f) ((void(*)(gpointer,gconstpointer))(f))

static gint shared_i, shared_j;
static GTVar *tvar_i, *tvar_j;
static GRand *random_sleep, *random_inc;

static void
copy_gint (gint *dst, gint *src)
{
  g_return_if_fail (dst != NULL && src != NULL);

  *dst = *src;
}

static gint
compare_gint (gint *i, gint *j)
{
  g_return_val_if_fail (i != NULL && j != NULL, -1);

  return (*i == *j ? 0 : (*i < *j ? -1 : 1));
}

static void
block_on_less_than_n (GTransaction *tr, gpointer user_data)
{
  gint *i, *j, n;

  g_assert (user_data != NULL);

  n = 2*(*(gint*)user_data);
  i = g_transaction_read_tvar (tr, tvar_i);
  j = g_transaction_read_tvar (tr, tvar_j);
  g_assert (i != NULL && j != NULL);
  while (*i < N+n || *j < N+n) {
    g_print ("block_on_less_than_%d blocks (shared_i == %d, shared_j == %d)\n", N+n, *i, *j);
    g_transaction_retry (tr);
  }
  *i -= (N+n);
  *j -= (N+n);
  g_print ("block_on_less_than_%d set shared_i == %d, shared_j == %d\n", N+n, *i, *j);
}

static void
increment_int (GTransaction *tr, gpointer user_data)
{
  gint *i, *j, inc, id;

  i = g_transaction_read_tvar (tr, tvar_i);
  g_assert (i != NULL);
  (*i)++;

  j = g_transaction_read_tvar (tr, tvar_j);
  g_assert (j != NULL);
  inc = g_rand_int_range (random_inc, 0, 2);
  *j += inc;

  g_print ("Incrementor thread set shared_i == %d, shared_j == %d\n", *i, *j);
}

static gpointer
worker_block (gpointer arg)
{
  GTransaction *tr[NR_THREADS-1], *trc;
  gint args[NR_THREADS-1];
  gchar *names[] = { "tr1", "tr2" };
  gint i;
  gint seconds;

  args[0] = 1;
  args[1] = 2;
  tr[0] = g_transaction_new (names[0], block_on_less_than_n, &args[0]);
  tr[1] = g_transaction_new (names[1], block_on_less_than_n, &args[1]);
  g_transaction_add_tvar (tr[0], tvar_i);
  g_transaction_add_tvar (tr[1], tvar_i);
  g_transaction_add_tvar (tr[0], tvar_j);
  g_transaction_add_tvar (tr[1], tvar_j);

  trc = g_transaction_or_else (tr[1], tr[0]);
  while (1) {
    g_transaction_do (trc);
    seconds = g_rand_int_range (random_sleep,
                                1,
                                MAX_SECONDS_TO_SLEEP);
    g_usleep (seconds*G_USEC_PER_SEC);
  }
}

static gpointer
worker_inc (gpointer arg)
{
  GTransaction *tr;
  gint id;
  gint seconds;

  tr = g_transaction_new ("Incrementor", increment_int, NULL);
  g_transaction_add_tvar (tr, tvar_i);
  g_transaction_add_tvar (tr, tvar_j);
  while (1) {
    g_transaction_do (tr);
    seconds = g_rand_int_range (random_sleep,
                                1,
                                MAX_SECONDS_TO_SLEEP);
    g_usleep (seconds*G_USEC_PER_SEC);
  }
}

int
main (int argc, char *argv[])
{
  GThread *threads[2];
  gint i;

  if (!g_thread_supported ())
    g_thread_init (NULL);

  tvar_i = g_transaction_var_new_contiguous (&shared_i,
				  sizeof(gint),
				  G_TVAR_COPY_FUNC(copy_gint),
				  G_COMPARE_FUNC(compare_gint));
  tvar_j = g_transaction_var_new_contiguous (&shared_j,
				  sizeof(gint),
				  G_TVAR_COPY_FUNC(copy_gint),
				  G_COMPARE_FUNC(compare_gint));
  random_sleep = g_rand_new ();
  random_inc = g_rand_new ();
  threads[0] = g_thread_create (worker_inc, NULL, TRUE, NULL);
  threads[1] = g_thread_create (worker_block, NULL, TRUE, NULL);
  (void) g_thread_join (threads[0]);
  (void) g_thread_join (threads[1]);

  return 0;
}
