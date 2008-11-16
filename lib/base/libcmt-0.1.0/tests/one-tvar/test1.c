/*
 * A simple test of many threads performing a single (not compound)
 * transaction that will try to increment the shared variable 'shared_i'.
 */
#include <gtransaction.h>

#define NR_THREADS            3
#define MAX_SECONDS_TO_SLEEP  3

#define G_COMPARE_FUNC(f)   ((gint(*)(gconstpointer,gconstpointer))(f))
#define G_TVAR_COPY_FUNC(f) ((void(*)(gpointer,gconstpointer))(f))

/*
 * Shared variable accessed by different threads.
 */
static glong shared_i = 1;

/*
 * Transaction variable encapsulating the shared variable 'shared_i'.
 */
static GTVar *tvar_i;

static GRand *random_generator;

static void copy_glong (glong *dst, const glong *src)
{
  g_return_if_fail (dst != NULL && src != NULL);

  *dst = *src;
}

static gint compare_glong (const glong *i, const glong *j)
{
  g_assert (i != NULL && j != NULL);
  
  return (*i == *j ? 0 : (*i < *j ? -1 : 1));
}

/*
 * f() will perform the real job within the transaction.
 */
static void f (GTransaction *tr, gpointer user_data)
{
  glong *k;
  gint id;
  gint *private;

  private = g_transaction_get_private (tr, gint);
  id = *private;

  k = g_transaction_read_tvar (tr, tvar_i);
  /*
   * The value returned by read_tvar() can be written without worry
   * about synchronization, because it belongs to the thread's private
   * GTransaction log, it isn't the real shared variable.
   */
  if (*k < G_MAXLONG / 10)
    *k = 10 * (*k);
  else
    *k = 1;
  g_print ("Thread %d compute %ld\n", id, *k);
}

/*
 * This thread will try to perform the transaction all the time.
 */
static gpointer worker (gpointer data)
{
  GTransaction *tr;
  gchar *names[] = { "tr0", "tr1", "tr2", "tr3", "tr4", "tr5" };
  gint id;
  gint seconds;

  g_return_val_if_fail (data != NULL, NULL);

  id = *(gint*)data;

  /*
   * Every thread create its own GTransaction
   */
  tr = g_transaction_new (names[id], f, &id);
  g_transaction_add_tvar (tr, tvar_i);

  while (1) {
    g_transaction_do (tr, NULL);
    seconds = g_rand_int_range (random_generator,
                                1,
                                MAX_SECONDS_TO_SLEEP);
    g_usleep (seconds*G_USEC_PER_SEC);
  }

  return NULL;
}

int main (int argc, char *argv[])
{
  GThread *threads[NR_THREADS];
  gint i, args[NR_THREADS];

  if (!g_thread_supported())
    g_thread_init (NULL);

  /*
   * There is one transactional variable for every shared variable
   */
  tvar_i = g_transaction_var_new_contiguous (&shared_i,
                                             sizeof(glong),
                                             G_TVAR_COPY_FUNC(copy_glong),
                                             G_COMPARE_FUNC(compare_glong));
  random_generator = g_rand_new ();
  for (i = 0; i < NR_THREADS; i++) {
    args[i] = i+1;
    threads[i] = g_thread_create (worker, &args[i], TRUE, NULL);
  }
  for (i = 0; i < NR_THREADS; i++)
    g_thread_join (threads[i]);

  return 0;
}
