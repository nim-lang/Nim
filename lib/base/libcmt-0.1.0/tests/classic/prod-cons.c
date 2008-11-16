/*
 * A solution to the classical producers-consumers problem.
 *
 */
#include <stdlib.h>
#include <string.h>
#include <cmt.h>

#define BUFF_SIZE           10
#define NR_PRODUCERS        3
#define NR_CONSUMERS        3

#define G_COMPARE_FUNC(f)   ((gint(*)(gconstpointer,gconstpointer))(f))
#define G_TVAR_COPY_FUNC(f) ((void(*)(gpointer,gconstpointer))(f))

typedef struct {
  gint buffer[BUFF_SIZE];
  gint top;
} Buffer;

static Buffer *shared_buffer;

static GTVar *tvar_buffer;

#define buffer_empty(buf)   (((buf)->top) <= 0)
#define buffer_full(buf)    (((buf)->top) >= (BUFF_SIZE - 1))
#define buffer_place(buf,i) ((((buf)->buffer)[((buf)->top)++]) = (i))
#define buffer_take(buf)    (((buf)->buffer)[--((buf)->top)])

static GRand *random_sleep;

#define take_a_rest()       (g_usleep (g_rand_int_range (random_sleep, 1000, G_USEC_PER_SEC/2)))

static void
copy_buffer (Buffer *dst, const Buffer *src)
{
  g_return_if_fail (src != NULL && dst != NULL);

  memcpy (dst->buffer, src->buffer, src->top*sizeof(gint));
  dst->top = src->top;
}

static gint
compare_buffer (const Buffer *a, const Buffer *b)
{
  gint i;

  g_return_val_if_fail (a != NULL && b != NULL, -1);

  if (a->top != b->top)
    return 1;
  for (i = 0; i < a->top; i++)
    if ((a->buffer)[i] != (b->buffer)[i])
      return 1;

  return 0;
}

static void
produce_tx (GTransaction *tx, gpointer user_data)
{
  Buffer *buf;
  gint id;

  id = *(gint*)user_data;

  buf = g_transaction_read_tvar (tx, tvar_buffer);

  if (!buffer_full(buf))
    buffer_place (buf, id);
  else
    g_transaction_retry (tx);
}

static void
consume_tx (GTransaction *tx, gpointer user_data)
{
  Buffer *buf;
  gint *item;

  item = (gint*)user_data;

  buf = g_transaction_read_tvar (tx, tvar_buffer);

  if (!buffer_empty(buf))
    *item = buffer_take (buf);
  else
    g_transaction_retry (tx);
}

static gpointer
producer (gpointer arg)
{
  GTransaction *produce;
  gint id;

  id = *(gint*)arg;

  produce = g_transaction_new ("Produce", produce_tx, NULL);
  g_transaction_add_tvar (produce, tvar_buffer);

  for (;;) {
    g_transaction_do (produce, &id);
    g_print ("Placed on buffer: %d\n", id);
    take_a_rest ();
  }
}

static gpointer
consumer (gpointer arg)
{
  GTransaction *consume;
  gint item;

  consume = g_transaction_new ("Consume", consume_tx, NULL);
  g_transaction_add_tvar (consume, tvar_buffer);

  for (;;) {
    g_transaction_do (consume, &item);
    g_print ("Consumed from buffer: %d\n", item);
    take_a_rest ();
  }
}

int
main (int argc, char *argv[])
{
  GThread *producers[NR_PRODUCERS];
  GThread *consumers[NR_CONSUMERS];
  gint ids[NR_PRODUCERS];
  gint i;

  if (!g_thread_supported ())
    g_thread_init (NULL);

  shared_buffer = g_new0 (Buffer, 1);
  tvar_buffer = g_transaction_var_new_contiguous (shared_buffer,
                                                  sizeof(Buffer),
                                                  G_TVAR_COPY_FUNC(copy_buffer),
                                                  G_COMPARE_FUNC(compare_buffer));

  random_sleep = g_rand_new ();

  for (i = 0; i < NR_PRODUCERS; i++) {
    ids[i] = i+1;
    producers[i] = g_thread_create (producer, &ids[i], TRUE, NULL);
  }
  for (i = 0; i < NR_CONSUMERS; i++)
    consumers[i] = g_thread_create (consumer, NULL, TRUE, NULL);

  for (i = 0; i < NR_PRODUCERS; i++)
    (void) g_thread_join (producers[i]);
  for (i = 0; i < NR_CONSUMERS; i++)
    (void) g_thread_join (consumers[i]);

  return 0;
}
