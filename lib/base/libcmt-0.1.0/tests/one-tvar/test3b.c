#include <stdlib.h>
#include <gtransaction.h>

#define NR_THREADS 5
#define N 5

static gint shared_i;
static GTVar *tvar_i;

static void
copy_gint (gpointer dst, gconstpointer src)
{
  g_return_if_fail (dst != NULL && src != NULL);

  *(gint*)dst = *(gint*)src;
}

static gint
compare_gint (gconstpointer i, gconstpointer j)
{
  g_return_val_if_fail (i != NULL && j != NULL, -1);

  return (*(gint*)i == *(gint*)j ? 0 : (*(gint*)i < *(gint*)j ? -1 : 1));
}

static void
decrement_int_or_block (GTransaction *tr, gpointer user_data)
{
  int *i;

  i = g_transaction_read_tvar (tr, tvar_i);
  g_assert (i != NULL);
  while (*i < N) {
    g_print ("Decrementor thread retrying (i == %d)\n", *i);
    g_transaction_retry (tr);
  }
  *i -= N;
  g_print ("Decrementor thread set shared int to %d\n", *i);
}

static void
increment_int (GTransaction *tr, gpointer user_data)
{
  gint *i;
  gint *private, id;

  private = g_transaction_get_private (tr, gint);
  id = *private;

  i = g_transaction_read_tvar (tr, tvar_i);
  g_assert (i != NULL);
  (*i)++;
  if (id == NR_THREADS - 1)
    g_print ("Thread %d (composed) set shared int to %d\n", id, *i);
  else
    g_print ("Thread %d set shared int to %d\n", id, *i);
}

static gpointer
worker_dec (gpointer arg)
{
  GTransaction *tr;

  tr = g_transaction_new ("Dec", decrement_int_or_block, NULL);
  g_transaction_add_tvar (tr, tvar_i);
  while (1) {
    g_transaction_do (tr, NULL);
    sleep (1);
  }
}

static gpointer
worker_inc (gpointer arg)
{
  GTransaction *tr;
  int id;

  g_return_val_if_fail (arg != NULL, NULL);

  id = *(gint*)arg;

  tr = g_transaction_new ("Inc", increment_int, &id);
  g_transaction_add_tvar (tr, tvar_i);
  while (1) {
    g_transaction_do (tr, NULL);
    sleep (1);
  }
}

static gpointer
worker_inc_inc_inc (gpointer arg)
{
  GTransaction *tr1, *tr2, *trc;
  int id;

  id = NR_THREADS - 1;

  tr1 = g_transaction_new ("tr1", increment_int, &id);
  tr2 = g_transaction_new ("tr2", increment_int, &id);
  g_transaction_add_tvar (tr1, tvar_i);
  g_transaction_add_tvar (tr2, tvar_i);
  trc = g_transaction_sequence (tr1, tr2);
  trc = g_transaction_sequence (trc, trc);
  while (1) {
    g_transaction_do (trc, NULL);
    sleep (1);
  }
}

int
main (int argc, char *argv[])
{
  GThread *threads[NR_THREADS];
  gint i, args[NR_THREADS];

  if (!g_thread_supported ())
    g_thread_init (NULL);

  tvar_i = g_transaction_var_new_contiguous (&shared_i,
				  sizeof(gint),
				  copy_gint,
				  compare_gint);

  for (i = 0; i < NR_THREADS - 1; i++)
    args[i] = i+1;
  for (i = 0; i < NR_THREADS - 2; i++)
    threads[i] = g_thread_create (worker_inc, &args[i], TRUE, NULL);
  threads[NR_THREADS - 2] = g_thread_create (worker_inc_inc_inc, NULL, TRUE, NULL);
  threads[NR_THREADS - 1] = g_thread_create (worker_dec, NULL, TRUE, NULL);
  for (i = 0; i < NR_THREADS; i++)
    (void) g_thread_join (threads[i]);

  return 0;
}
