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

#ifndef __G_TRANSACTION_H__
#define __G_TRANSACTION_H__

#include <glib.h>
#include <setjmp.h>

G_BEGIN_DECLS

typedef enum
{
  G_TRANSACTION_OR_ELSE_PART  = 1 << 0,
  G_TRANSACTION_SEQUENCE_PART = 1 << 1,
  G_TRANSACTION_TOP_LEVEL     = 1 << 2,
  G_TRANSACTION_WAS_ABORTED   = 1 << 3,
} GTransactionFlags;

typedef struct _GTLog GTLog;
struct _GTLog
{
  /*< private >*/
  GSList *tvar_entries;
  gint   ref_count;
};

/**
 * @addtogroup GTransaction GTransaction
 * @{
 */

/**
 * Type of a function that duplicates a shared variable (not
 * a transactional variable).
 *
 * @param svar Pointer to the shared variable.
 *
 * @return A copy of the shared variable into a newly allocated
 * memory.
 */
typedef gpointer (*GTVarDupFunc)  (gconstpointer svar);

/**
 * Type of a function that copy a contiguous shared variable (not
 * a transactional variable) from @a src to @a dst.
 */
typedef void     (*GTVarCopyFunc) (gpointer dst, gconstpointer src);

/**
 * Type representing a transactional variable which encapsulates a
 * shared variable.
 */
typedef struct _GTVar GTVar;

/**
 * Type representing a transaction.
 */
typedef struct _GTransaction GTransaction;

/**
 * Type of a function which performs the actions of a transaction.
 *
 * When invoked, @a tr will be the transaction which have the function 
 * being called as its transaction function.
 */
typedef void (*GTransactionFunc)           (GTransaction *tr, gpointer user_data);

/**
 * Type of a function which is called on commit.
 *
 * @see g_transaction_var_set_commit_callback().
 */
typedef void (*GTransactionCommitCallback) (gpointer svar, gpointer result_var);

/**
 * Obtain the pointer to transaction's private data that was set on
 * creation.
 *
 * See g_transaction_new() for more details about transaction's private
 * data.
 */
#define g_transaction_get_private(transaction, private_type) \
        ((private_type*)((transaction)->user_data))

/**
 * Tells whether the given transaction was aborted.
 *
 * Tells whether the given transaction was aborted on the last call to
 * g_transaction_do() or g_transaction_timed_do(), if there was any such
 * call.
 *
 * This is needed speciall because the return value of
 * g_transaction_timed_do() tells whether the transaction was performed
 * on time or not, not whether the transaction was successful or aborted,
 * as g_transaction_do() does.
 */
#define g_transaction_was_aborted(transaction)               \
  (((transaction)->flags) & G_TRANSACTION_WAS_ABORTED)

/**
 * @}
 */

struct _GTVar
{
  /*< private >*/
  gpointer                   var;
  gsize                      size;

  GTVarDupFunc               dup;
  GDestroyNotify             destroy;
  GTVarCopyFunc              copy;
  GCompareFunc               compare;

  GSList                     *waiters;
  GTransactionCommitCallback commit_cb;
};

struct _GTransaction
{
  /*< private >*/
  gchar             *name;
  GTLog             *log;
  GTransactionFunc  func;
  GTransaction      *nested;
  GTransaction      *next;
  GTransactionFlags flags;
  gint              ref_count;
  /*< public >*/
  gpointer          user_data;
};

GTransaction* g_transaction_new                 (const gchar *name,
                                                 GTransactionFunc func,
                                                 gpointer user_data);
GTVar*        g_transaction_var_new             (gpointer var,
                                                 GTVarDupFunc dup_func,
                                                 GDestroyNotify destroyer,
                                                 GCompareFunc compare);
GTVar*        g_transaction_var_new_contiguous  (gpointer var,
                                                 gsize size,
                                                 GTVarCopyFunc copy_func,
                                                 GCompareFunc compare);

void          g_transaction_add_tvar            (GTransaction *transaction,
                                                 GTVar *var);
gpointer      g_transaction_read_tvar           (GTransaction *transaction,
                                                 GTVar *tvar);

GTransaction* g_transaction_sequence            (GTransaction *tr1, GTransaction *tr2);
GTransaction* g_transaction_or_else             (GTransaction *tr1, GTransaction *tr2);
gboolean      g_transaction_do                  (GTransaction *transaction,
                                                 gpointer user_data);
gboolean      g_transaction_timed_do            (GTransaction *transaction,
                                                 gpointer user_data,
                                                 const GTimeVal *abs_time);
void          g_transaction_retry               (GTransaction *transaction);
void          g_transaction_abort               (GTransaction *transaction);
GTransaction* g_transaction_copy                (GTransaction *transaction);
void          g_transaction_destroy             (GTransaction *transaction);

/* Private function used when coding bindings */
void          g_transaction_var_set_commit_callback (GTVar *tvar,
                                                     GTransactionCommitCallback cb);

G_END_DECLS

#endif /* __G_TRANSACTION_H__ */
