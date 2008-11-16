/*
 * A solution to the classical problem of the dinning philosophers.
 *
 * Using CMT, this is trivially done, because the hard part of the problem
 * (the negotiation of a fork pair) is easily expressable using the orElse
 * construction: a transaction is built that try to pick a fixed fork pair,
 * blocking if the pair is not available. One of this transactions are build
 * for every possible fork pair.
 *
 * Then a whole transaction 'take_forks' is created, which is the orElse
 * combination of the previous ones: it will try to take a pair, if it 
 * can't do that, it will try to take the next pair, and so on, blocking if
 * no one pair is available.
 */
#include <stdlib.h>
#include <gtransaction.h>

#define NR_PHILO 5
#ifndef NR_ITER
# error "You must define NR_ITER=number-of-iterations"
#endif

#define G_COMPARE_FUNC(f)   ((gint(*)(gconstpointer,gconstpointer))(f))
#define G_TVAR_COPY_FUNC(f) ((void(*)(gpointer,gconstpointer))(f))

#define think()             (g_usleep (g_rand_int_range (random_think, 1, G_USEC_PER_SEC/2)))

typedef struct {
  guint    nr_usage;    /* Number of times it has been used */
  gboolean in_use;      /* Tells whether the fork is currently in use */
} Fork;

static Fork forks[NR_PHILO];
static GTVar *tforks[NR_PHILO];

static gchar *tnames[] = { "TakeFork0", "TakeFork1", "TakeFork2", "TakeFork3", "TakeFork4" };

static GRand *random_think, *random_eat;

static void
copy_fork (Fork *dst, const Fork *src)
{
  g_return_if_fail (src != NULL && dst != NULL);

  dst->nr_usage = src->nr_usage;
  dst->in_use = src->in_use;
}

static gint
compare_fork (const Fork *i, const Fork *j)
{
  g_return_val_if_fail (i != NULL && j != NULL, -1);

  return ((i->nr_usage == j->nr_usage) && (i->in_use == j->in_use) ? 0 : 1);
}

static void
take_pair (GTransaction *tr, gpointer user_data)
{
  Fork *fork1, *fork2;
  gint fork_index;
  gint *private;

  private = g_transaction_get_private (tr, gint);
  fork_index = *private;

  fork1 = g_transaction_read_tvar (tr, tforks[fork_index]);
  fork2 = g_transaction_read_tvar (tr, tforks[(fork_index+1) % NR_PHILO]);
  if ((fork1->in_use) || (fork2->in_use))
    g_transaction_retry (tr);

  fork1->in_use = fork2->in_use = TRUE;
    
  /* Remember which fork was found idle */
  *(gint*)user_data = fork_index;
}

static void
down_forks (GTransaction *tr, gpointer user_data)
{
  Fork *fork1, *fork2;
  gint fork_index;

  fork_index = *(gint*)user_data;

  fork1 = g_transaction_read_tvar (tr, tforks[fork_index]);
  fork2 = g_transaction_read_tvar (tr, tforks[(fork_index+1) % NR_PHILO]);
  fork1->in_use = fork2->in_use = FALSE;
}

static void
eat (gint id, gint which_fork)
{
  g_usleep (g_rand_int_range (random_eat, 1, G_USEC_PER_SEC/8));
  (forks[which_fork].nr_usage)++;
  (forks[(which_fork + 1) % NR_PHILO].nr_usage)++;
  g_print ("Philopher %d has eaten with forks %i and %i\n",
           id, which_fork, (which_fork + 1) % NR_PHILO);
}

static gpointer
philo (gpointer arg)
{
  GTransaction *take_pair_tr[NR_PHILO], *take_forks;
  GTransaction *down_forks_tr;
  GRand *random_fork;
  gint which_forks[NR_PHILO];
  gint which_fork;
  gint i, id;

  id = *(gint*)arg;

  /*
   * The first fork tried by a philosopher is a random one.
   */
  random_fork = g_rand_new ();
  which_fork = g_rand_int_range (random_fork, 0, NR_PHILO);
  for (i = 0; i < NR_PHILO; i ++) {
    which_forks[i]= which_fork;
    take_pair_tr[i] = g_transaction_new (tnames[i],
                                         take_pair,
                                         &which_forks[i]);
    g_transaction_add_tvar (take_pair_tr[i], tforks[i]);
    g_transaction_add_tvar (take_pair_tr[i], tforks[(i+1) % NR_PHILO]);
    which_fork = (which_fork+1) % NR_PHILO;
  }
  /*
   * Build the transaction that will try to take a fork pair, if it
   * cannot do that, it will try to take the next pair, and so on, 
   * blocking if any pair is available.
   */
  take_forks = take_pair_tr[0];
  for (i = 1; i < NR_PHILO; i ++)
    take_forks = g_transaction_or_else (take_forks, take_pair_tr[i]);

  down_forks_tr = g_transaction_new ("DownForks", down_forks, NULL);
  for (i = 0; i < NR_PHILO; i ++)
    g_transaction_add_tvar (down_forks_tr, tforks[i]);

  for (i = 0; i < NR_ITER; i++) {
    g_transaction_do (take_forks, &which_fork);
    eat (id, which_fork);
    g_transaction_do (down_forks_tr, &which_fork);
    think ();
  }
}

int
main (int argc, char *argv[])
{
  GThread *threads[NR_PHILO];
  gint ids[NR_PHILO];
  gint i;

  if (!g_thread_supported ())
    g_thread_init (NULL);

  for (i = 0; i < NR_PHILO; i++)
    tforks[i] = g_transaction_var_new_contiguous (&forks[i],
                                                  sizeof(Fork),
                                                  G_TVAR_COPY_FUNC(copy_fork),
                                                  G_COMPARE_FUNC(compare_fork));

  random_think = g_rand_new ();
  random_eat = g_rand_new ();
  for (i = 0; i < NR_PHILO; i++) {
    ids[i] = i+1;
    threads[i] = g_thread_create (philo, &ids[i], TRUE, NULL);
  }

  for (i = 0; i < NR_PHILO; i++)
    (void) g_thread_join (threads[i]);

  for (i = 0; i < NR_PHILO; i++)
    g_print ("Fork %i was used %i times\n", i, forks[i].nr_usage);

  return 0;
}
