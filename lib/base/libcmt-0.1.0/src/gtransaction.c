/*
 * LibCMT - Composable Memory Transactions Library.
 * 
 * Copyright (C) 2005 Duilio Protti <dprotti@users.sourceforge.net>
 *
 * Author: Duilio Protti <dprotti@users.sourceforge.net>
 *
 * $Id:
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as
 * published by the Free Software Foundation; either version 2.1
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
 */

#if HAVE_CONFIG_H
#include <config.h>
#endif
#include <string.h>
#include <gtransaction.h>

typedef struct _GTVarEntry GTVarEntry;
struct _GTVarEntry
{
  GTVar *tvar;
  gpointer old_value;
  gpointer new_value;

  unsigned int was_readed : 1;
};

typedef struct _GTVarWaitQueue GTVarWaitQueue;
struct _GTVarWaitQueue
{
  /*< private >*/
  GCond *wait_queue;
  GTLog *parent_tlog;
};

#define G_TRANSACTION_RETURN_OK         0
#define G_TRANSACTION_RETURN_INVALID    1
#define G_TRANSACTION_RETURN_ABORTED    2
#define G_TRANSACTION_RETURN_ERROR      3

#ifdef LIBCMT_DEBUG
#define g_transaction_debug0(s)              g_print(s)
#define g_transaction_debug1(s,arg1)         g_print(s,arg1)
#define g_transaction_debug2(s,arg1,arg2)    g_print(s,arg1,arg2)
#else
#define g_transaction_debug0(s)
#define g_transaction_debug1(s,arg1)
#define g_transaction_debug2(s,arg1,arg2)
#endif /* LIBCMT_DEBUG*/

#define G_FUNC(f)                            ((void(*)(gpointer,gpointer))(f))
#define G_DESTROY_NOTIFY(f)                  ((void(*)(gpointer))(f))

#define gtvar_is_contiguous(tvar)            ((tvar)->copy != NULL)
#define gtvar_have_commit_callback(tvar)     ((tvar)->commit_cb != NULL)

#define g_transaction_is_sequence_part(tr)   (((tr)->flags) & G_TRANSACTION_SEQUENCE_PART)
#define g_transaction_is_or_else_part(tr)    (((tr)->flags) & G_TRANSACTION_OR_ELSE_PART)
#define g_transaction_is_top_level(tr)       (((tr)->flags) & G_TRANSACTION_TOP_LEVEL)

#define g_transaction_mark_sequence_part(tr) (((tr)->flags) |= G_TRANSACTION_SEQUENCE_PART)
#define g_transaction_mark_or_else_part(tr)  (((tr)->flags) |= G_TRANSACTION_OR_ELSE_PART)

#define g_transaction_mark_top_level(tr)     (((tr)->flags) |= G_TRANSACTION_TOP_LEVEL)
#define g_transaction_unmark_top_level(tr)   (g_transaction_is_top_level(tr) ?              \
                                               ((tr)->flags) ^= G_TRANSACTION_TOP_LEVEL :   \
                                               (tr)->flags)

#define g_transaction_mark_aborted(tr)       (((tr)->flags) |= G_TRANSACTION_WAS_ABORTED)
#define g_transaction_unmark_aborted(tr)     (g_transaction_was_aborted(tr) ?               \
                                               ((tr)->flags) ^= G_TRANSACTION_WAS_ABORTED : \
                                               (tr)->flags)

#define g_tlog_ref(tlog)                     (g_atomic_int_inc (&((tlog)->ref_count)))
#define g_transaction_ref(tr)                (g_atomic_int_inc (&((tr)->ref_count)))

#if (!HAVE_SIGLONGJMP)
#  define sigjmp_buf                         jmp_buf
#  define siglongjmp                         longjmp
#  define sigsetjmp(buf,savesig)             setjmp(buf) 
#endif

/*
 * This is a giant lock used on the validate-then-commit-or-reset cycle,
 * which must be done atomically.
 *
 * In the future probably would be better to have a transactional context
 * with his own lock, and transactions that access disjoint sets of shared
 * variables, will perform on different contexts, avoiding the bottle-neck
 * introduced by this giant lock.
 */
G_LOCK_DEFINE_STATIC (transaction_lock);

G_LOCK_DEFINE_STATIC (tvar_entry_memchunk);
static GMemChunk   *tvar_entry_memchunk = NULL;
static GTrashStack *free_tvar_entries = NULL;

static GTVarEntry*
g_tvar_entry_new (GTVar *tvar)
{
  GTVarEntry *tvar_entry;

  g_return_val_if_fail (tvar != NULL, NULL);

  G_LOCK (tvar_entry_memchunk);
  tvar_entry = g_trash_stack_pop (&free_tvar_entries);

  if (!tvar_entry)
    {
      if (!tvar_entry_memchunk)
	tvar_entry_memchunk = g_mem_chunk_new ("LibCMT GTVarEntry chunk",
                                               sizeof(GTVarEntry),
                                               sizeof(GTVarEntry) * 1024,
                                               G_ALLOC_ONLY);
      tvar_entry = g_chunk_new (GTVarEntry, tvar_entry_memchunk);
    }
  G_UNLOCK (tvar_entry_memchunk);

  tvar_entry->tvar = tvar;
  tvar_entry->was_readed = FALSE;

  if (gtvar_is_contiguous (tvar)) {
    tvar_entry->old_value = g_malloc (tvar->size);
    tvar->copy (tvar_entry->old_value, tvar->var);
    tvar_entry->new_value = g_malloc (tvar->size);
    tvar->copy (tvar_entry->new_value, tvar->var);
  } else {
    tvar_entry->old_value = tvar->dup (tvar->var);
    tvar_entry->new_value = tvar->dup (tvar->var);
  }

  return tvar_entry;
}

static void
g_tvar_entry_destroy (GTVarEntry *tvar_entry)
{
  G_LOCK (tvar_entry_memchunk);
  g_trash_stack_push (&free_tvar_entries, tvar_entry);
  G_UNLOCK (tvar_entry_memchunk);
}

static void
g_tvar_entry_destroy_as_gfunc (gpointer data, gpointer user_data)
{
  g_tvar_entry_destroy ((GTVarEntry*)data);
}

G_LOCK_DEFINE_STATIC (tlog_memchunk);
static GMemChunk   *tlog_memchunk = NULL;
static GTrashStack *free_tlogs = NULL;

static GTLog*
g_tlog_new (void)
{
  GTLog *tlog;

  G_LOCK (tlog_memchunk);
  tlog = g_trash_stack_pop (&free_tlogs);

  if (!tlog)
    {
      if (!tlog_memchunk)
	tlog_memchunk = g_mem_chunk_new ("LibCMT GTLog chunk",
                                         sizeof(GTLog),
                                         sizeof(GTLog) * 128,
                                         G_ALLOC_ONLY);
      tlog = g_chunk_new (GTLog, tlog_memchunk);
    }
  G_UNLOCK (tlog_memchunk);

  tlog->tvar_entries = NULL;
  tlog->ref_count = 0;

  return tlog;
}

static void
g_tlog_free (GTLog *tlog)
{
  g_return_if_fail (tlog != NULL);

  /* just in case... */
  tlog->ref_count = 0;
  G_LOCK (tlog_memchunk);
  g_trash_stack_push (&free_tlogs, tlog);
  G_UNLOCK (tlog_memchunk);
}

static void
g_tlog_unref (GTLog *tlog)
{
  g_return_if_fail (tlog != NULL);
  g_return_if_fail (g_atomic_int_get (&tlog->ref_count) > 0);

  if (g_atomic_int_dec_and_test (&tlog->ref_count)) {
    g_slist_foreach (tlog->tvar_entries,
                     g_tvar_entry_destroy_as_gfunc,
                     NULL);
    g_slist_free (tlog->tvar_entries);
    g_tlog_free (tlog);
  }
}

static void
g_tlog_add_tvar (GTLog *tlog, GTVar *tvar)
{
  GTVarEntry *tvar_entry;

  tvar_entry = g_tvar_entry_new (tvar);
  tvar_entry->was_readed = FALSE;
  tlog->tvar_entries = g_slist_append (tlog->tvar_entries, tvar_entry);
}

static gint
g_tvar_entry_compare_tvar (gconstpointer data,
                           gconstpointer user_data)
{
  GTVarEntry *tvar_entry = (GTVarEntry*)data;
  GTVar *tvar = (GTVar*)user_data;

  g_return_val_if_fail (tvar_entry != NULL, -1);

  return ((tvar_entry->tvar == tvar) ? 0 : 1);
}

static gpointer
g_tlog_read_tvar (GTLog *tlog, GTVar *tvar)
{
  GSList *link;
  GTVarEntry *tvar_entry;

  g_return_val_if_fail (tlog != NULL, NULL);
  g_return_val_if_fail (tvar != NULL, NULL);

  link = g_slist_find_custom (tlog->tvar_entries,
                              tvar,
                              g_tvar_entry_compare_tvar);
  if (link) {
    tvar_entry = (GTVarEntry*)(link->data);
    g_assert (tvar_entry != NULL);
    tvar_entry->was_readed = TRUE;
    return (tvar_entry->new_value);
  } else {
    return NULL;
  }
}

static void
g_tvar_entry_add_tvar_to_tlog (GTVarEntry *entry, GTLog* tlog)
{
  g_tlog_add_tvar (tlog, entry->tvar);
}

static GTLog*
g_tlog_copy (GTLog* tlog)
{
  GTLog *new_log;

  new_log = g_tlog_new ();
  g_slist_foreach (tlog->tvar_entries,
                   G_FUNC(g_tvar_entry_add_tvar_to_tlog),
                   new_log);

  return new_log;
}

static GTransaction*
g_transaction_new_impl (void)
{
  return (g_new0 (GTransaction, 1));
}

static void
g_transaction_unref (GTransaction *tr)
{
  g_return_if_fail (tr != NULL);
  g_return_if_fail (g_atomic_int_get (&tr->ref_count) > 0);

  if (g_atomic_int_dec_and_test (&tr->ref_count)) {
#ifdef LIBCMT_DEBUG
    if (tr->name)
      g_free (tr->name);
#endif
    g_tlog_unref (tr->log);
    g_free (tr);
  }
}

static gboolean
g_transaction_is_valid (GTransaction *transaction)
{
  GTLog *tlog;
  GTVarEntry *tvar_entry;
  GTVar *tvar;
  guint index;

  g_return_val_if_fail (transaction->log != NULL, FALSE);

  tlog = transaction->log;
  for (index = 0; index < g_slist_length (tlog->tvar_entries); index++) {
    tvar_entry = g_slist_nth_data (tlog->tvar_entries, index);
    g_return_val_if_fail (tvar_entry != NULL, FALSE);
    tvar = tvar_entry->tvar;
    if (tvar && (tvar->compare (tvar_entry->old_value, tvar->var) != 0)) {
      g_transaction_debug1 ("Transaction log for '%s' is not valid\n", transaction->name);
      return FALSE;
    }
  }

  g_transaction_debug1 ("Transaction log for '%s' is valid\n", transaction->name);
  return TRUE;
}

static void
g_transaction_foreach (GTransaction *tr,
                       GTransactionFunc func,
                       gpointer user_data)
{
  if (tr->nested)
    g_transaction_foreach (tr->nested, func, user_data);
  if (tr->next)
    g_transaction_foreach (tr->next, func, user_data);
  func (tr, user_data);
}

/*static void
g_transaction_mark_sequence_part_func (GTransaction *tr, gpointer user_data)
{
  g_transaction_mark_sequence_part (tr);
}*/

static void
g_transaction_mark_or_else_part_func (GTransaction *tr, gpointer user_data)
{
  g_transaction_mark_or_else_part (tr);
}

static void
g_transaction_sequence_foreach (GTransaction *tr,
                                GTransactionFunc func,
                                gpointer user_data)
{
  if (tr->next)
    g_transaction_sequence_foreach (tr->next, func, user_data);
  func (tr, user_data);
}

static void
g_transaction_sequence_composer (GTransaction *tr1, gpointer user_data)
{
  GTransaction *tr2 = user_data;

  if (!tr1->next) {
    tr1->next = tr2;
    g_transaction_ref (tr2);
  }
  g_transaction_mark_sequence_part (tr1);
}

static void
g_transaction_sequence_impl (GTransaction *tr1, GTransaction *tr2)
{
  g_transaction_sequence_foreach (tr1, g_transaction_sequence_composer, tr2);
  if (tr1->nested)
    g_transaction_sequence_impl (tr1->nested, tr2);
}

static void
g_transaction_or_else_composer (GTransaction *tr1, gpointer user_data)
{
  GTransaction *tr2 = user_data;

  if (!tr1->nested) {
    tr1->nested = tr2;
    g_transaction_ref (tr2);
  }
  g_transaction_mark_or_else_part (tr1);
}

static void
g_tvar_wakeup_listener (gpointer data, gpointer user_data)
{
  GTVarWaitQueue *wait_queue_entry;

  g_return_if_fail (data != NULL);

  wait_queue_entry = (GTVarWaitQueue*)data;

  /*
   * There will be always just one thread sleeping here (the one that 
   * created the wait queue), so a broadcast is not neccessary.
   */
  if (wait_queue_entry->wait_queue)
    g_cond_signal (wait_queue_entry->wait_queue);
#ifdef LIBCMT_DEBUG
  else
    g_transaction_debug0 ("Wait queue was destroyed\n");
#endif
}

static void
g_transaction_commit (GTransaction *transaction)
{
  GTLog *tlog;
  GTVarEntry *tvar_entry;
  GTVar *tvar;
  guint index;

  g_return_if_fail (transaction != NULL);

  g_transaction_debug1 ("Transaction '%s' commit\n", transaction->name);

  tlog = transaction->log;
  for (index = 0; index < g_slist_length (tlog->tvar_entries); index++) {
    tvar_entry = g_slist_nth_data (tlog->tvar_entries, index);
    g_return_if_fail (tvar_entry != NULL);
    g_return_if_fail (tvar_entry->tvar != NULL);
    tvar = tvar_entry->tvar;
    if (gtvar_have_commit_callback (tvar)) {
      /* the client want to manage things by himself */
      tvar->commit_cb (tvar->var, tvar_entry->new_value);
    } else {
      if (gtvar_is_contiguous (tvar)) {  
        tvar->copy (tvar->var, tvar_entry->new_value);
        /* FIXME this is really neccessary ? */
        tvar->copy (tvar_entry->old_value, tvar_entry->new_value);
      } else {
        tvar->destroy (tvar->var);
        tvar->var = tvar->dup (tvar_entry->new_value);
        /*
         * TODO think about this
         */
        tvar->destroy (tvar_entry->old_value);
        tvar_entry->old_value = tvar->dup (tvar->var);
      }
    }
    if (tvar->waiters) {
      /* Wake up everybody */
      g_slist_foreach (tvar->waiters,
		       g_tvar_wakeup_listener,
                       NULL);
    }
  }  
}

static GTVarWaitQueue*
g_tvar_wait_queue_new (GTLog *parent_tlog)
{
  GTVarWaitQueue *new_wq;

  g_return_val_if_fail (parent_tlog != NULL, NULL);

  if (!g_thread_supported())
    g_thread_init (NULL);

  new_wq = g_new0 (GTVarWaitQueue, 1);
  new_wq->wait_queue = g_cond_new();
  new_wq->parent_tlog = parent_tlog;

  return new_wq;
}

static void
g_tvar_wait_queue_destroy (GTVarWaitQueue *wait_queue)
{
  g_return_if_fail (wait_queue != NULL);

  g_cond_free (wait_queue->wait_queue);
  g_free (wait_queue);
}

/* Destructive on l1 and l2 */
static GSList*
g_tvar_entry_list_union_fast (GSList *l1, GSList* l2)
{
  GSList *l, *link_;
  GTVarEntry *tvar_entry, *repeated_tvar_entry;

  l = l1;
  while (l) {
    tvar_entry = (GTVarEntry*)l->data;
    g_assert (tvar_entry->tvar != NULL);
    link_ = g_slist_find_custom (l2,
                                 tvar_entry->tvar,
                                 g_tvar_entry_compare_tvar);
    if (link_) {
      repeated_tvar_entry = (GTVarEntry*)(link_->data);
      g_assert (repeated_tvar_entry != tvar_entry);
      g_tvar_entry_destroy (repeated_tvar_entry);
      l2 = g_slist_delete_link (l2, link_);
    }
    l = g_slist_next (l);
  }

  return g_slist_concat (l1, l2);
}

static void
g_tvar_entry_mark_unreaded (gpointer data, gpointer user_data)
{
  ((GTVarEntry*)data)->was_readed = FALSE;
}

/*
 * Copy the value of the shared variables into the transactional
 * variables of the transaction.
 *
 * Of course this function must be called atomically with respect
 * to other accesses to the same shared variables (for now we just
 * use a giant lock).
 */
static void
g_transaction_reset (GTransaction *transaction)
{
  GTLog *tlog;
  GTVarEntry *tvar_entry;
  GTVar *tvar;
  guint index;

  g_return_if_fail (transaction->log != NULL);

  g_transaction_debug1 ("Reset transaction log for '%s'\n", transaction->name);

  tlog = transaction->log;
  for (index = 0; index < g_slist_length (tlog->tvar_entries); index++) {
    tvar_entry = g_slist_nth_data (tlog->tvar_entries, index);
    g_return_if_fail (tvar_entry != NULL);
    g_return_if_fail (tvar_entry->tvar != NULL);
    tvar_entry->was_readed = FALSE;
    tvar = tvar_entry->tvar;
    if (gtvar_is_contiguous (tvar)) {
      tvar->copy (tvar_entry->old_value, tvar->var);
      tvar->copy (tvar_entry->new_value, tvar->var);
    } else {
      /* TODO think this */
      tvar->destroy (tvar_entry->new_value);
      tvar->destroy (tvar_entry->old_value);
      tvar_entry->old_value = tvar->dup (tvar->var);
      tvar_entry->new_value = tvar->dup (tvar->var);
    }
  }
}

/*
 * Restore the original values (the values at the beginning of the transaction)
 * of the transactional variables.
 *
 * This function doesn't need to be called atomically with respect to other
 * accesses to the same shared variables, as g_transaction_reset() does.
 */
static void
g_transaction_soft_reset (GTransaction *transaction)
{
  GTLog *tlog;
  GTVarEntry *tvar_entry;
  GTVar *tvar;
  guint index;

  g_return_if_fail (transaction->log != NULL);

  g_transaction_debug1 ("(Soft) Reset transaction log for '%s'\n", transaction->name);

  tlog = transaction->log;
  for (index = 0; index < g_slist_length (tlog->tvar_entries); index++) {
    tvar_entry = g_slist_nth_data (tlog->tvar_entries, index);
    g_return_if_fail (tvar_entry != NULL);
    g_return_if_fail (tvar_entry->tvar != NULL);
    tvar_entry->was_readed = FALSE;
    tvar = tvar_entry->tvar;
    if (gtvar_is_contiguous (tvar)) {
      tvar->copy (tvar_entry->new_value, tvar_entry->old_value);
    } else {
      tvar->destroy (tvar_entry->new_value);
      tvar_entry->new_value = tvar->dup (tvar_entry->old_value);
    }
  }
}

static void
g_transaction_set_log (GTransaction *transaction,
                       GTLog *tlog,
                       gboolean update_ref_count)
{
  GTransaction *tr;

  tr = transaction;
  while (tr) {
    if (update_ref_count)
      g_tlog_ref (tlog);
    tr->log = tlog;
    if (tr->nested)
      g_transaction_set_log (tr->nested, tlog, update_ref_count);
    tr = tr->next;
  }
}

static GTransaction*
g_transaction_copy_node (GTransaction *transaction,
                         GTLog *tlog,
                         gboolean update_ref_count)
{
  GTransaction *tr;

  tr = g_transaction_new_impl ();
  if (transaction->name)
    tr->name = transaction->name;
  g_transaction_set_log (tr, tlog, update_ref_count);
  tr->func = transaction->func;
  tr->user_data = transaction->user_data;
  tr->next = tr->nested = NULL;
  tr->flags = transaction->flags;

  return tr;
}

static GTransaction*
g_transaction_copy_impl (GTransaction *transaction,
                         GTLog *tlog,
                         gboolean update_log_ref_count)
{
  GTransaction *result;

  result = g_transaction_copy_node (transaction,
                                    tlog,
                                    update_log_ref_count);
  if (transaction->nested) {
    result->nested = g_transaction_copy_impl (transaction->nested,
                                              tlog,
                                              update_log_ref_count);
    g_transaction_ref (result->nested);
  }
  if (transaction->next) {
    result->next = g_transaction_copy_impl (transaction->next,
                                            tlog,
                                            update_log_ref_count);
    g_transaction_ref (result->next);
  }

  return result;
}

static void
add_wait_queue (gpointer data, gpointer user_data)
{
  GTVarEntry *tvar_entry;
  GTVarWaitQueue *wait_queue;
  GTVar *tvar;
  
  g_return_if_fail (data != NULL && user_data != NULL);

  tvar_entry = (GTVarEntry*)data;

  if (!(tvar_entry->was_readed))
    return;

  wait_queue = (GTVarWaitQueue*)user_data;
  tvar = tvar_entry->tvar;

  tvar->waiters = g_slist_prepend (tvar->waiters,
                                   wait_queue);
}

static void
remove_wait_queue (gpointer data, gpointer user_data)
{
  GTVarEntry *tvar_entry;
  const GTVarWaitQueue *wait_queue;
  GTVar *tvar;
  
  g_return_if_fail (data != NULL && user_data != NULL);

  tvar_entry = (GTVarEntry*)data;

  if (!(tvar_entry->was_readed))
    return;

  wait_queue = (GTVarWaitQueue*)user_data;
  tvar = tvar_entry->tvar;

  tvar->waiters = g_slist_remove (tvar->waiters,
                                  wait_queue);
}

/* This is needed because g_mutex_free() is a macro */
static void
g_mutex_free_as_func (GMutex *mutex)
{
  g_mutex_free (mutex);
}

static void
g_tlog_wait (GTLog *tlog, GTVarWaitQueue *wait_queue)
{
  static GStaticPrivate dummy_mutex_key = G_STATIC_PRIVATE_INIT;
  GMutex *dummy_mutex;

  g_slist_foreach (tlog->tvar_entries,
		   add_wait_queue,
		   wait_queue);

  G_UNLOCK(transaction_lock);

  dummy_mutex = g_static_private_get (&dummy_mutex_key);
  if (!dummy_mutex) {
    dummy_mutex = g_mutex_new();
    g_static_private_set (&dummy_mutex_key,
                          dummy_mutex,
                          G_DESTROY_NOTIFY(g_mutex_free_as_func));
  }

  g_mutex_lock (dummy_mutex);
  g_cond_wait (wait_queue->wait_queue, dummy_mutex);
  g_mutex_unlock (dummy_mutex);
}

/*
 * g_tlog_unwait() must be called with 'transaction_lock' held, because otherwise
 * g_transaction_commit() could get and invalid (destroyed) GTVarWaitQueue while
 * trying to wake up listeners, because the same wait_queue is added to many
 * lists (one on each tvar).
 */
static void
g_tlog_unwait (GTLog *tlog, GTVarWaitQueue *wait_queue)
{
  g_slist_foreach (tlog->tvar_entries,
		   remove_wait_queue,
		   wait_queue);
}

static void
g_transaction_set_name (GTransaction *transaction, gchar *name)
{
  GTransaction *tr;

  tr = transaction;
  while (tr) {
    tr->name = name;
    if (tr->nested)
      g_transaction_set_name (tr->nested, name);
    tr = tr->next;
  }
}

static void
g_transaction_destroy_node (GTransaction *tr, gpointer user_data)
{
  if (tr->nested)
    g_transaction_unref (tr->nested);
  if (tr->next)
    g_transaction_unref (tr->next);
}

static void
g_transaction_log_union (GTransaction *tr1, GTransaction *tr2)
{
  g_return_if_fail (tr1 != tr2);
  g_return_if_fail (tr1->log != tr2->log);

  tr1->log->tvar_entries = g_tvar_entry_list_union_fast (tr1->log->tvar_entries,
                                                         tr2->log->tvar_entries);
  g_tlog_free (tr2->log);

  g_transaction_set_log (tr2, tr1->log, TRUE);
}

static GStaticPrivate jmpbuf_key = G_STATIC_PRIVATE_INIT;

static sigjmp_buf*
g_trasaction_get_jmp_buf (void)
{
  sigjmp_buf *thread_jmp_buf;

  thread_jmp_buf = g_static_private_get (&jmpbuf_key);
  if (!thread_jmp_buf) {
    thread_jmp_buf = g_new0 (sigjmp_buf, 1);
    g_static_private_set (&jmpbuf_key, thread_jmp_buf, g_free);
  }

  return thread_jmp_buf;
}

#define g_transaction_commit_or_propagate(transaction) \
{                                                      \
  if (g_transaction_is_top_level (transaction))        \
    g_transaction_commit (transaction);                \
  G_UNLOCK (transaction_lock);                         \
  return G_TRANSACTION_RETURN_OK;                      \
}

#define g_transaction_commit_or_propagate_validating(transaction) \
{                                                                 \
  if (g_transaction_is_top_level (transaction)) {                 \
    G_LOCK (transaction_lock);                                    \
    if (g_transaction_is_valid (transaction)) {                   \
      g_transaction_commit (transaction);                         \
      G_UNLOCK (transaction_lock);                                \
      return G_TRANSACTION_RETURN_OK;                             \
    } else {                                                      \
      g_transaction_reset (transaction);                          \
      G_UNLOCK (transaction_lock);                                \
      return G_TRANSACTION_RETURN_INVALID;                        \
    }                                                             \
  } else {                                                        \
    return G_TRANSACTION_RETURN_OK;                               \
  }                                                               \
}

#define g_transaction_reset_or_propagate(transaction)  \
{                                                      \
  if (g_transaction_is_top_level (transaction))        \
    g_transaction_reset (transaction);                 \
  G_UNLOCK (transaction_lock);                         \
  return G_TRANSACTION_RETURN_INVALID;                 \
}

static gint
g_transaction_do_impl (GTransaction *transaction, gpointer user_data)
{
  GTVarWaitQueue *wait_queue;
  sigjmp_buf *jmp_buf, saved_jmp_buf;
  int setjmp_result;

  if (!transaction->nested) {
    if (g_transaction_is_top_level (transaction)) {
      /*
       * When unblock occurs, we must return to the beginning (the top level),
       * so the jmp_buf is set here.
       */
      jmp_buf = g_trasaction_get_jmp_buf();
      setjmp_result = sigsetjmp (*jmp_buf, LIBCMT_SAVE_SIGNAL_MASK);
      if (setjmp_result == G_TRANSACTION_RETURN_ABORTED)
        return G_TRANSACTION_RETURN_ABORTED;
      else
        ; /* Just the returning point was set */
    }
    g_transaction_debug1 ("Trying transaction '%s'\n", transaction->name);
    transaction->func (transaction, user_data);
    G_LOCK (transaction_lock);
    if (g_transaction_is_valid (transaction)) {
      if (transaction->next) {
        /* keep going with the secuence */
        G_UNLOCK (transaction_lock);
        g_transaction_debug0 ("Trying next transaction in the sequence\n");
        if (g_transaction_do_impl (transaction->next, user_data) == G_TRANSACTION_RETURN_OK) {
          /* 
           * It must be validated again because log could became invalid while
           * returning from the recursive call.
           */
          g_transaction_commit_or_propagate_validating (transaction);
        } else {
          g_transaction_reset_or_propagate (transaction);
        }
      } else {
        g_transaction_commit_or_propagate (transaction);
      }
    } else {
      g_transaction_reset_or_propagate (transaction);
    }
  } else {
    /*
     * It has a nested transaction.
     */
    jmp_buf = g_trasaction_get_jmp_buf();
    memcpy (saved_jmp_buf, *jmp_buf, sizeof(sigjmp_buf));
    setjmp_result = sigsetjmp (*jmp_buf, LIBCMT_SAVE_SIGNAL_MASK);
    if (setjmp_result == G_TRANSACTION_RETURN_ABORTED)
      return G_TRANSACTION_RETURN_ABORTED;
    else if (setjmp_result == G_TRANSACTION_RETURN_INVALID)
      goto trytr2;
    else
      ; /* Just the returning point was set */

    g_transaction_debug1 ("Trying first transaction of '%s'\n", transaction->name);
    transaction->func (transaction, user_data);
    G_LOCK (transaction_lock);
    if (g_transaction_is_valid (transaction)) {
      if (transaction->next) {
        /* keep going with the secuence */
        G_UNLOCK (transaction_lock);
        g_transaction_debug0 ("Trying next transaction in the sequence\n");
        if (g_transaction_do_impl (transaction->next, user_data) == G_TRANSACTION_RETURN_OK) {
          /* 
           * It must be validated again because log could became invalid while
           * returning from the recursive call.
           */
          g_transaction_commit_or_propagate_validating (transaction);
        } else {
          g_transaction_reset_or_propagate (transaction);
        }
      } else {
        g_transaction_commit_or_propagate (transaction);
      }
    } else {
      g_transaction_reset_or_propagate (transaction);
    }

  trytr2:
    g_transaction_debug1 ("First transaction of '%s' have blocked\n", transaction->name);
    jmp_buf = g_trasaction_get_jmp_buf();
    setjmp_result = sigsetjmp (*jmp_buf, LIBCMT_SAVE_SIGNAL_MASK);
    if (setjmp_result == G_TRANSACTION_RETURN_ABORTED)
      return G_TRANSACTION_RETURN_ABORTED;
    else if (setjmp_result == G_TRANSACTION_RETURN_INVALID)
      goto bothretry;
    else
      ; /* Just the returning point was set */

    g_transaction_soft_reset (transaction);
    g_transaction_debug1 ("Trying second transaction of '%s'\n", transaction->nested->name);
    if (g_transaction_do_impl (transaction->nested, user_data) == G_TRANSACTION_RETURN_OK) {
      /*
       * Nested was successful. We must leave the sequence, committing if this is
       * the top level transaction, propagating otherwise. We must validate again
       * because log could became invalid while returning from nested transaction.
       */
      g_transaction_commit_or_propagate_validating (transaction);
    } else {
      G_LOCK (transaction_lock);
      g_transaction_reset_or_propagate (transaction);
    }

  bothretry:
    g_transaction_debug1 ("Both transactions of '%s' have blocked\n", transaction->name);
    G_LOCK (transaction_lock);
    if (g_transaction_is_valid (transaction)) {
      if (g_transaction_is_top_level (transaction)) {
        /* Top level transaction goes to sleep */
        wait_queue = g_tvar_wait_queue_new (transaction->log);
        g_transaction_debug1 ("Transaction '%s' go to sleep\n", transaction->name);
        /* g_tlog_wait() will release 'transaction_lock' */
        g_tlog_wait (transaction->log, wait_queue);
        g_transaction_debug1 ("Transaction '%s' wake up\n", transaction->name);
        G_LOCK (transaction_lock);
        g_tlog_unwait (transaction->log, wait_queue);
        g_transaction_reset (transaction);
        G_UNLOCK (transaction_lock);
        g_tvar_wait_queue_destroy (wait_queue);
        return G_TRANSACTION_RETURN_INVALID;
      } else {
        /* Must jump looking for top level transaction */
        G_UNLOCK (transaction_lock);
        g_transaction_debug0 ("Jumping to the enclosing transaction\n");
        siglongjmp (saved_jmp_buf, G_TRANSACTION_RETURN_INVALID);
      }
    } else {
      g_transaction_reset_or_propagate (transaction);
    }
  }

  g_assert_not_reached ();

  return G_TRANSACTION_RETURN_ERROR;
}

G_LOCK_DEFINE_STATIC (tvar_memchunk);
static GMemChunk   *tvar_memchunk = NULL;
static GTrashStack *free_tvars = NULL;

/**
 * @defgroup GTransaction GTransaction
 * @{
 */

/**
 * Create a new transaction.
 *
 * The same transaction cannot be shared among different threads, every
 * transaction must be local to the thread that runs that transaction.
 * This is because the transaction contains the log where proposed memory 
 * changes are written, and this log must be private to the thread in 
 * question.
 *
 * @param name The name of the new transaction. This is useful only for 
 * debugging purposes. @a name can be NULL.
 *
 * @param func Pointer to the function that perform the transaction. It
 * cannot be NULL. Every GTVar referenced by @a func must be later added
 * to the transaction using g_transaction_add_tvar().
 *
 * @param _private Pointer to private data that can be be used by the
 * transaction function. Later @a _private can be obtained using
 * g_transaction_get_private().
 * LibCMT *never* touch this private data.
 * It could be used i.e. to customize the transaction function.
 * For an example of this usage, you can see the solution to the Dinning
 * Philosophers Problem using LibCMT on the 'tests/classic/philo.c' file on the
 * source tree.
 *
 * @note The @a _private pointer will be preserved on composition. It means
 * that i.e. after g_transaction_sequence (A, B), a call to
 * g_transaction_get_private() from any of the transaction functions of 'A'
 * or 'B' will still returning the @a _private pointer that was set on
 * creation of 'A' and 'B' respectively.
 *
 * @return A newly allocated transaction. After creation,
 * g_transaction_add_tvar() must be called to add every GTVar used by
 * @a func.
 *
 * You can see tests/one-tvar/test1.c program on the source tree of LibCMT
 * for a simple example of use.
 */
GTransaction*
g_transaction_new (const gchar *name,
                   GTransactionFunc func,
                   gpointer _private)
{
  GTransaction *tr;
  GTLog *log;

  g_return_val_if_fail (func != NULL, NULL);

  tr = g_transaction_new_impl ();

  if (name)
    tr->name = g_strdup (name);

  log = g_tlog_new ();
  g_transaction_set_log (tr, log, TRUE);

  tr->func = func;
  tr->flags = 0;
  g_transaction_mark_top_level (tr);

  tr->ref_count = 0;

  tr->user_data = _private;

  return tr;
}

/**
 * Destroy the given transaction.
 *
 * @todo It doesn't work for some transactions due to the new composition scheme.
 */
void
g_transaction_destroy (GTransaction *transaction)
{
  g_return_if_fail (transaction != NULL);
  g_return_if_fail (transaction->log != NULL);
  g_return_if_fail (g_transaction_is_top_level (transaction));

  g_transaction_foreach (transaction, g_transaction_destroy_node, NULL);

  g_tlog_unref (transaction->log);
  g_free (transaction);

#ifdef LIBCMT_DEBUG
  g_transaction_debug1 ("Destroyed transaction '%s'\n", transaction->name);
  if (transaction->name) {
    g_free (transaction->name);
#ifdef ENABLE_GC_FRIENDLY
    transaction->name = NULL;
#endif
  }
#endif /* LIBCMT_DEBUG */
}

/**
 * Creates a new GTVar.
 *
 * @param var Pointer to the shared variable.
 *
 * @param dup_func Pointer to a function which duplicates the shared
 * variable encapsulated by this transactional variable.
 *
 * @param destroyer Pointer to a function which destroys the duplicate
 * returned by @a dup_func.
 *
 * @param compare Pointer to a function which returns TRUE if the two given
 * shared variables are equal, and FALSE otherwise.
 *
 * @return A newly allocated GTVar.
 *
 * @note The types GCompareFunc and GDestroyNotify are from Glib:
 *   - gint (*GCompareFunc) (gconstpointer  a, gconstpointer  b)
 *   - void (*GDestroyNotify) (gpointer data)
 */
GTVar*
g_transaction_var_new (gpointer var,
                       GTVarDupFunc dup_func,
                       GDestroyNotify destroyer,
                       GCompareFunc compare)
{
  GTVar *tvar;

  g_return_val_if_fail (var != NULL, NULL);
  g_return_val_if_fail (dup_func != NULL, NULL);

  G_LOCK (tvar_memchunk);
  tvar = g_trash_stack_pop (&free_tvars);

  if (!tvar)
    {
      if (!tvar_memchunk)
          tvar_memchunk = g_mem_chunk_new ("LibCMT GTVar chunk",
                                           sizeof(GTVar),
                                           sizeof(GTVar) * 128,
                                           G_ALLOC_ONLY);
      tvar = g_chunk_new (GTVar, tvar_memchunk);
    }
  G_UNLOCK (tvar_memchunk);

  tvar->var = var;
  tvar->dup = dup_func;
  tvar->destroy = destroyer;
  tvar->copy = NULL;
  tvar->compare = compare;

  if (!g_thread_supported())
    g_thread_init (NULL);

  tvar->waiters = NULL;
  tvar->commit_cb = NULL;

  return tvar;
}

/**
 * Creates a new GTVar encapsulating a shared variable located on a contiguous
 * block of memory (like an int or an array).
 *
 * @param var Pointer to the contiguous shared variable.
 *
 * @param size Size of the memory block which contains the shared variable.
 *
 * @param copy_func Pointer to a function that will be used to copy the 
 * contiguous shared variable from one memory place to another (not overlapped)
 * one.
 *
 * @param compare Pointer to a function which returns 0 if the two given
 * shared variables are equal, non-zero otherwise.
 *
 * @return A newly allocated GTVar.
 *
 * @note The type of GCompareFunc is:
 * gint (*GCompareFunc) (gconstpointer  a, gconstpointer  b)
 */
GTVar*
g_transaction_var_new_contiguous (gpointer var,
                                  gsize size,
                                  GTVarCopyFunc copy_func,
                                  GCompareFunc compare)
{
  GTVar *tvar;

  g_return_val_if_fail (var != NULL, NULL);
  g_return_val_if_fail (copy_func != NULL, NULL);
  g_return_val_if_fail (compare != NULL, NULL);

  G_LOCK (tvar_memchunk);
  tvar = g_trash_stack_pop (&free_tvars);

  if (!tvar)
    {
      if (!tvar_memchunk)
	tvar_memchunk = g_mem_chunk_create (GTVar,
                                            sizeof(GTVar) * 128,
                                            G_ALLOC_ONLY);
      tvar = g_chunk_new (GTVar, tvar_memchunk);
    }
  G_UNLOCK (tvar_memchunk);

  tvar->var = var;
  tvar->dup = NULL;
  tvar->destroy = NULL;
  tvar->copy = copy_func;
  tvar->compare = compare;
  tvar->size = size;

  if (!g_thread_supported())
    g_thread_init (NULL);

  tvar->waiters = NULL;
  tvar->commit_cb = NULL;

  return tvar;
}

/**
 * Add a transactional variable to a given transaction.
 *
 * This function must be used to add every GTVar which is used on the
 * transaction's function.
 */
void
g_transaction_add_tvar (GTransaction *transaction,
                        GTVar *tvar)
{
  g_return_if_fail (transaction != NULL);
  g_return_if_fail (transaction->log != NULL);
  g_return_if_fail (tvar != NULL);
  
  g_tlog_add_tvar (transaction->log, tvar);
}

/**
 * Read the content of a transaction's variable.
 *
 * @return A reference to the shared variable encapsulated by the
 * transactional variable, or NULL if @a tvar is not found on the
 * given transaction (probably because it was not previously added
 * using g_transaction_add_tvar()).
 *
 * @note In fact, the returned pointer does not reference the *real*
 * shared variable, but a copy of it on the transaction's log, so the
 * thread can write to the referenced memory without worry about
 * synchronization (there is simply no g_transaction_write_tvar()).
 */
gpointer
g_transaction_read_tvar (GTransaction *transaction,
                         GTVar *tvar)
{
  gpointer result;

  g_return_val_if_fail (transaction != NULL, NULL);
  g_return_val_if_fail (transaction->log != NULL, NULL);
  g_return_val_if_fail (tvar != NULL, NULL);

  result = g_tlog_read_tvar (transaction->log, tvar);

  if (result)
    return result;
  else {
#ifdef LIBCMT_DEBUG
    g_warning ("GTVar not found on transaction '%s'", transaction->name);
#else
    g_warning ("GTVar not found on transaction's log");
#endif
    return NULL;
  }
}

/**
 * Perform the given transaction.
 *
 * It doesn't return until the transaction is done successfully and changes are
 * committed, or until it is aborted.
 *
 * If the desired behaviour is not to try indefinetely until transaction is done,
 * g_transaction_timed_do() can be used.
 *
 * @param transaction The transaction to perform.
 *
 * @param user_data Pointer that will be passed to the transaction function 
 * when it's invoked. It is provided as a way to pass data to/from the
 * transaction function at runtime. It's allowed to be NULL.
 *
 * @return TRUE if @a transaction was performed successfully, FALSE if it was
 * aborted.
 */
gboolean
g_transaction_do    (GTransaction *transaction,
                     gpointer user_data)
{
  gint result;

  g_return_val_if_fail (transaction != NULL, FALSE);
  g_return_val_if_fail (transaction->log != NULL, FALSE);

  g_slist_foreach (transaction->log->tvar_entries,
		   g_tvar_entry_mark_unreaded,
		   NULL);

  /* Reset before to begin, to get last news... */
  G_LOCK(transaction_lock);
  g_transaction_reset (transaction);
  G_UNLOCK(transaction_lock);

  g_transaction_unmark_aborted (transaction);
  while (1) {
    result = g_transaction_do_impl (transaction, user_data);
    if (result == G_TRANSACTION_RETURN_OK)
      return TRUE;
    else if (result == G_TRANSACTION_RETURN_ABORTED) {
      g_transaction_mark_aborted (transaction);
      return FALSE;
    }
    else
      ; /* Keep trying */
  }
}

/**
 * Try to perform the given transaction, but not longer than until
 * the time that is specified by @a abs_time.
 *
 * @param transaction The transaction to perform.
 *
 * @param user_data Pointer that will be passed to the transaction function 
 * when it's invoked. It is provided as a way to pass data to/from the
 * transaction function at runtime. It's allowed to be NULL.
 *
 * @param abs_time The (absolute) time until which the transaction will be
 * tried to perform.
 *
 * @note To easily calculate @a abs_time a combination of
 * g_get_current_time() and g_time_val_add() can be used.
 * For a simple example of use, see the tests/one-tvar/test2b.c program
 * on the source tree of LibCMT.
 *
 * @note This function doesn't preempt the given transaction. That is, if
 * @a abs_time has past, it doesn't mean that g_transaction_timed_do() will
 * immediately returns, it just only mean that g_transaction_timed_do() will
 * not retry the given transaction again (but the transaction can return from
 * blocking far more later than @a abs_time).
 *
 * @return TRUE if the transaction was performed on time, FALSE if it was not
 * performed on time or if it was aborted (to distinguish between these two
 * cases, g_transaction_was_aborted() can be used).
 */
gboolean
g_transaction_timed_do (GTransaction *transaction,
                        gpointer user_data,
                        const GTimeVal *abs_time)
{
  GTimeVal current_time;
  gint result;

  g_return_val_if_fail (transaction != NULL, FALSE);
  g_return_val_if_fail (transaction->log != NULL, FALSE);
  g_return_val_if_fail (abs_time != NULL, FALSE);

  g_slist_foreach (transaction->log->tvar_entries,
		   g_tvar_entry_mark_unreaded,
		   NULL);

  G_LOCK(transaction_lock);
  g_transaction_reset (transaction);
  G_UNLOCK(transaction_lock);

  g_transaction_unmark_aborted (transaction);
  while (1) {
    g_get_current_time (&current_time);
    if (current_time.tv_sec >= abs_time->tv_sec) {
      if (current_time.tv_sec > abs_time->tv_sec)
        return FALSE;
      else if (current_time.tv_usec >= abs_time->tv_usec)
        return FALSE;
    }
    result = g_transaction_do_impl (transaction, user_data);
    if (result == G_TRANSACTION_RETURN_OK)
      return TRUE;
    else if (result == G_TRANSACTION_RETURN_ABORTED) {
      g_transaction_mark_aborted (transaction);
      return FALSE;
    }
    else
      ; /* Keep trying */
  }

  g_assert_not_reached ();
  
  return FALSE;
}   

/**
 * Block the given transaction.
 *
 * This function is intended to be used by the transaction function.
 * When called, it blocks the current transaction until somebody commit to
 * any of the GTVar's that the transaction have read up to the current point.
 * Then, the transaction is started from the beginning, but noticed about
 * the new changes.
 *
 * @note If you are thinking "how is the function automagically restarted?",
 * yes, it is done using sigsetjmp/siglongjmp.
 */
void
g_transaction_retry (GTransaction *transaction)
{
  GTVarWaitQueue *wait_queue;
  sigjmp_buf *jmp_buf;

  g_return_if_fail (transaction != NULL);
  g_return_if_fail (transaction->log != NULL);

  G_LOCK (transaction_lock);
  if (!g_transaction_is_valid (transaction)) {
    g_transaction_reset (transaction);
    G_UNLOCK (transaction_lock);
    jmp_buf = g_trasaction_get_jmp_buf();
    siglongjmp (*jmp_buf, G_TRANSACTION_RETURN_INVALID);
  }

  /*
   * If we are part of an 'orElse' composition, we must not wait here.
   */
  if (g_transaction_is_or_else_part (transaction)) {
    G_UNLOCK (transaction_lock);
    jmp_buf = g_trasaction_get_jmp_buf();
    siglongjmp (*jmp_buf, G_TRANSACTION_RETURN_INVALID);
  }

  wait_queue = g_tvar_wait_queue_new (transaction->log);

  /* g_tlog_wait() will release 'transaction_lock' */
  g_tlog_wait (transaction->log, wait_queue);
  
  G_LOCK (transaction_lock);
  g_tlog_unwait (transaction->log, wait_queue);
  g_transaction_reset (transaction);
  G_UNLOCK (transaction_lock);
  g_tvar_wait_queue_destroy (wait_queue);

  jmp_buf = g_trasaction_get_jmp_buf();
  siglongjmp (*jmp_buf, G_TRANSACTION_RETURN_INVALID);
}

/**
 * Abort the given transaction.
 */
void
g_transaction_abort (GTransaction *transaction)
{
  sigjmp_buf *jmp_buf;

  g_return_if_fail (transaction != NULL);
  g_return_if_fail (transaction->log != NULL);

  jmp_buf = g_trasaction_get_jmp_buf();
  siglongjmp (*jmp_buf, G_TRANSACTION_RETURN_ABORTED);
}

/**
 * Composition by sequence.
 *
 * First @a tr1 is executed, and then @a tr2, but the whole sequence is executed as
 * a transaction.
 *
 * The composition is destructive on @a tr1 and @a tr2. This means that after calling
 * g_transaction_sequence(), both @a tr1 and @a tr2 are not valid transactions (they
 * must not be passed to g_transaction_do() or used to compose other transactions).
 *
 * If any of them are needed
 * independently, a copy must be do it before the composition with g_transaction_copy().
 * However, it is posible to compose in sequence a transaction with itself (but no with
 * a subset of itself, see note below): g_transaction_sequence (tr, tr) is right.
 *
 * @note The composition of a transaction with a *strict* subtransaction of itself is not
 * allowed.
 * This is to avoid strange errors because of the destructive nature of composing
 * operations. If you really want that kind of composition, use g_transaction_copy()
 * on the subtransaction first.
 */
GTransaction*
g_transaction_sequence (GTransaction *tr1, GTransaction *tr2)
{
#ifdef LIBCMT_DEBUG
  gchar *name;
#endif

  g_return_val_if_fail (tr1 != NULL, NULL);
  g_return_val_if_fail (g_transaction_is_top_level (tr1), NULL);
  g_return_val_if_fail (tr1->log != NULL, NULL);
  g_return_val_if_fail (tr2 != NULL, NULL);
  g_return_val_if_fail (g_transaction_is_top_level (tr2), NULL);
  g_return_val_if_fail (tr2->log != NULL, NULL);

  if (tr1 == tr2)
    tr1 = g_transaction_copy_impl (tr2, tr2->log, TRUE);
  else if (tr1->log == tr2->log) {
    g_error ("The composition of a transaction with a strict subtransaction "
             "of itself is not allowed. If you really need this, use "
             "g_transaction_copy() on the subtransaction.\n");
  }
  else
    g_transaction_log_union (tr1, tr2);

  g_transaction_sequence_impl (tr1, tr2);

  /* This flag is not used for now
     g_transaction_foreach (tr2, g_transaction_mark_sequence_part_func, NULL); */
  g_transaction_unmark_top_level (tr2);

#ifdef LIBCMT_DEBUG
  name = g_strconcat ("(", tr1->name, "; ", tr2->name, ")", NULL);
  g_free (tr1->name);
  g_free (tr2->name);

  g_transaction_set_name (tr1, name);
#endif

  return tr1;
}

/**
 * Composition by 'orElse' alternative: the second transaction is run if the first blocks.
 *
 * This allows to wait for many things at once.
 *
 * @a tr1 is always tried as first alternative, and @a tr2 is run iff @a tr1 blocks.
 * The complete set of possibilities are:
 *   - @a tr1 runs until completion, then either:
 *     - @a tr1 commit, and the composed transaction is done, or
 *     - @a tr1 rollback, then the composed transaction is tried again.
 *   - or @a tr1 blocks, then @a tr2 is run, and then either:
 *     - @a tr2 runs until completion, and then either:
 *       - @a tr2 commit, and the composed transaction is done, or
 *       - @a tr2 rollback, then the composed transaction is tried again.
 *     - or @a tr2 blocks, then the composed transaction blocks.
 *
 * The composition is destructive on @a tr1 and @a tr2. This means that after calling
 * g_transaction_or_else(), both @a tr1 and @a tr2 are not valid transactions (they
 * must not be passed to g_transaction_do() or used to compose other transactions).
 *
 * If any of them are needed
 * independently, a copy must be do it before the composition, using
 * g_transaction_copy().
 *
 * ((A orElse B) orElse C) is exactly the same transaction than (A orElse (B orElse C)).
 *
 * @note @a tr1 and @a tr2 must be two *different* transactions.
 *
 * @note The composition of a transaction with a *strict* subtransaction of itself is not
 * allowed.
 * This is to avoid strange errors because of the destructive nature of composing
 * operations. If you really want that kind of composition, use g_transaction_copy()
 * on the subtransaction first.
 */
GTransaction*
g_transaction_or_else (GTransaction *tr1, GTransaction *tr2)
{
#ifdef LIBCMT_DEBUG
  gchar *name;
#endif

  g_return_val_if_fail (tr1 != NULL, NULL);
  g_return_val_if_fail (g_transaction_is_top_level (tr1), NULL);
  g_return_val_if_fail (tr1->log != NULL, NULL);
  g_return_val_if_fail (tr2 != NULL, NULL);
  g_return_val_if_fail (g_transaction_is_top_level (tr2), NULL);
  g_return_val_if_fail (tr2->log != NULL, NULL);

  /* tr1 orElse tr2 makes sense? */
  g_return_val_if_fail (tr1 != tr2, NULL);

  if (tr1->log == tr2->log) {
    g_error ("The composition of a transaction with a strict subtransaction "
             "of itself is not allowed. If you really need this, use "
             "g_transaction_copy() on the subtransaction.\n");
  }

  g_transaction_log_union (tr1, tr2);

  g_transaction_foreach (tr1, g_transaction_or_else_composer, tr2);

  g_transaction_foreach (tr2, g_transaction_mark_or_else_part_func, NULL);
  g_transaction_unmark_top_level (tr2);

#ifdef LIBCMT_DEBUG
  name = g_strconcat ("(", tr1->name, " orElse ", tr2->name, ")", NULL);
  g_free (tr1->name);
  g_free (tr2->name);

  g_transaction_set_name (tr1, name);
#endif

  return tr1;
}

/**
 * Copy the given transaction.
 *
 * Usually, this function is used when composing transactions, due to the
 * fact that composition using g_transaction_or_else() or g_transaction_sequence()
 * is destructive on its arguments.
 *
 * @return A copy of @a transaction on success, or NULL on failure.
 */
GTransaction*
g_transaction_copy (GTransaction *transaction)
{
  GTLog *tlog;

  g_return_val_if_fail (transaction != NULL, NULL);
  g_return_val_if_fail (transaction->log != NULL, NULL);

  tlog = g_tlog_copy (transaction->log);

  return (g_transaction_copy_impl (transaction, tlog, TRUE));
}

/**
 * [Private] Set a commit callback.
 *
 * This exist only for developers writing very specialized things like bindings
 * and the like. Unless you really understand how LibCMT works, you must
 * <strong>never</strong> use this function in your code.
 */
void
g_transaction_var_set_commit_callback (GTVar *tvar,
                                       GTransactionCommitCallback cb)
{
  g_return_if_fail (tvar != NULL);

  tvar->commit_cb = cb;
}

/**
 * @}
 */

