//
// LibCMT C# binding
//
// Copyright (C) 2006 Duilio J. Protti [http://www.fceia.unr.edu.ar/~dprotti/]
//
// Permission is hereby granted, free of charge, to any person obtaining
// a copy of this software and associated documentation files (the
// "Software"), to deal in the Software without restriction, including
// without limitation the rights to use, copy, modify, merge, publish,
// distribute, sublicense, and/or sell copies of the Software, and to
// permit persons to whom the Software is furnished to do so, subject to
// the following conditions:
// 
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
// LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
// OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
// WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

using System.Reflection;

[assembly: AssemblyTitle("LibCMT")]
[assembly: AssemblyDescription("Composable Memory Transactions Library for CLI")]
[assembly: AssemblyCopyright("(c) 2006 Duilio Protti <dprotti@users.sourceforge.net>")]
[assembly: AssemblyDelaySign(false)]
[assembly: AssemblyKeyFile("libcmt-sharp.snk")]
[assembly: AssemblyVersion("0.0.1.0")]


namespace LibCMT
{
using System;
using System.Runtime.InteropServices;
using System.Collections;

  /**
     <summary>
     This interface must be implemented by every object that want to be encapsulated
     into a transactional variable.
     </summary>
     <seealso cref="LibCMT.GTVar"/>
  */
  public interface ILibCMTCommittable : ICloneable, IComparable
  {
    /**
       <summary> Commit changes to the object. </summary>
       <remarks>
       This method will be called by LibCMT when the changes proposed by the
       transaction must be done public to the rest of the program. To meet this, the
       method must copy the values from <c>copy</c> to the current object.
       In general, the body of this method will be boilerplate text that will copy
       the member values of <c>copy</c> to the corresponding members of <c>this</c>.
       </remarks>
       <param name="copy">
       Reference to the copy upon which the transaction have performed its changes.
       </param>
       <example>
       <description>
       Simple example of a class implementing ILibCMTCommittable
       </description>
       <code>
       public class A : ILibCMTCommittable
       {
         public int x;

         public A ()
         {
           x = 0;
         }

         public void Commit (object o)
         {
           A a = o as A;       
           x = a.x;
         }
       
         public object Clone ()
         {
           A ret = new A();       
           ret.x = this.x;
           return ret;
         }

         public int CompareTo (object o)
         {
           A a = o as A;
           if (a.x == this.x)
             return 0;
           else
             return 1;
         }
       }
       </code>
       </example>
    */
    void Commit (object copy);
  }

  /**
     <summary>
     Class representing a transaction.
     </summary>
     <remarks>
     Every thread must create its own instance for every transaction it wants to
     be engaged. This is very important, because a GTransaction object contains
     the log of the changes made by the transaction, which must be kept isolated
     from changes made by other threads.

     Then, the <see cref="LibCMT.GTransaction.GTransactionFunc"/> within a
     GTransaction object does not access the shared variables directly, but instead
     it access the <see cref="LibCMT.GTVar"/> encapsulating
     that shared variables.  For this reason, that function, which makes the
     concurrent work desired by the programmer, mustn't worry about obtaining
     exclusive access to shared resources, it just read and write GTVar's,
     without fear, and it can block if some conditions on these variables
     are not meet, with the guarantee that it will be wake up when the
     GTVar's involved on these conditions have changed (because other thread
     have committed).

     LibCMT takes care of determine whether the transaction have
     seen a consistent state of the memory during the ENTIRE transaction,
     and if this is the case, takes care of commit the changes to the real
     shared variables, possibly waking up other threads interested on these
     changes. Otherwise, if the memory state seen was not consistent, the
     library rollbacks the transaction (all the changes proposed by the
     transaction are discarded and the memory is readed again) and retry it.
     </remarks>
     <example>
     <description>
     A very simple example on how to use LibCMT (without using transactional variables):
     </description>
     <code>
     using System;
     using LibCMT;

     public class HelloTx
     {
     public static void Hello (GTransaction tx, object user_data)
      {
        Console.WriteLine ("Hello World!");
      }

     public static void Main ()
      {
        Console.WriteLine ("Creating the callback...");
        GTransaction.GTransactionFunc helloCb = new GTransaction.GTransactionFunc (Hello);

        Console.WriteLine ("Creating the transaction...");
        GTransaction tx = new GTransaction ("HelloTx", helloCb, null);

        Console.WriteLine ("Running the transaction...");
        tx.Run (null);

        Console.WriteLine ("Exit");
      }
     }
     </code>
     </example>
     <seealso cref="LibCMT.GTVar"/>
   */
  public class GTransaction : ICloneable
  {
    /**
       <summary>
       Delegate representing a transaction function.
       </summary>
       <remarks>
       When invoked, <c>tx</c> will be the transaction which have the function 
       being called as its transaction function.
       </remarks>
    */
    public  delegate void   GTransactionFunc      (GTransaction tx, object userData);
    private delegate void   _GTransactionFunc     (IntPtr tx, IntPtr userData);

    [DllImport("libcmt.dll")]
    static extern IntPtr g_transaction_new        (string name,
                                                   _GTransactionFunc func,
                                                   IntPtr userData);
    [DllImport("libcmt.dll")]
    static extern IntPtr g_transaction_sequence   (IntPtr tx1, IntPtr tx2);
    [DllImport("libcmt.dll")]
    static extern IntPtr g_transaction_or_else    (IntPtr tx1, IntPtr tx2);
    [DllImport("libcmt.dll")]
    static extern bool   g_transaction_do         (IntPtr tx, IntPtr data);
    [DllImport("libcmt.dll")]
    static extern void   g_transaction_retry      (IntPtr tx);
    [DllImport("libcmt.dll")]
    static extern void   g_transaction_abort      (IntPtr tx);

    private string name;
    private IntPtr           tx;         // The native transaction
    private GTransactionFunc tx_func;    // The C# transactional method's delegate

    /**
       <summary>
       Creates a new top level transaction.
       </summary>
       <param name="name">The name of the transaction.</param>
       <param name="func">Delegate that will perform the work of the transaction.</param>
       <param name="userData">Private data to be used by the transaction.
       It could be <c>null</c>.</param>
       <seealso cref="LibCMT.GTransaction.GTransactionFunc"/>
     */
    public GTransaction (string name, GTransactionFunc func, object userData)
    {
      if (name == null)
	throw new ArgumentNullException ("GTransaction(): name is null");
      if (func == null)
	throw new ArgumentNullException ("GTransaction(): func is null");
      if (userData != null)
	throw new NotImplementedException ("Transaction private data not handled yet");

      this.name = name;
      tx_func = func;
      _GTransactionFunc txFunc = new _GTransactionFunc (Marshaller);
      tx = g_transaction_new (name, txFunc, IntPtr.Zero);
    }

    /**
       <summary>
       Creates a new sequence transaction.
       </summary>
       <remarks>
       First <c>tx1</c> is executed, and then <c>tx2</c>, but the whole sequence is executed
       as a transaction.

       The composition is destructive on <c>tx1</c> and <c>tx2</c>. This means that after this constructor
       returns, both <c>tx1</c> and <c>tx2</c> are not valid transactions.

       If any of the two given transactions are needed independently, a clone must be do it
       before calling this constructor. However, it is posible to compose in sequence a
       transaction with itself, but no with a subset of itself.
       </remarks>
       <param name="tx1">The first transaction to be executed.</param>
       <param name="tx2">The second transaction to be executed.</param>
     */
    public GTransaction (GTransaction tx1, GTransaction tx2)
    {
      if (tx1 == null)
	throw new ArgumentNullException ("GTransaction(tx1,tx2): tx1 is null");
      if (tx2 == null)
	throw new ArgumentNullException ("GTransaction(tx1,tx2): tx2 is null");

      // tx_func's remains untouched and the tvars list are merged in the 
      // unmanaged side
      tx = g_transaction_sequence (tx1.tx, tx2.tx);
    }

    /**
       <summary> Add a transactional variable to the transaction. </summary>
       <remarks>
       This function must be called to add every <see cref="LibCMT.GTVar"/>
       which is used on the transaction's function.
       </remarks>
    */
    public void AddTVar (GTVar tvar)
    {
      if (tvar == null)
	throw new ArgumentNullException ();

      tvar.NativeTransaction = tx;
    }

    /**
       <summary> Read the content of the transactional variable. </summary>
       <remarks>
       The returned object does not reference the *real* shared variable, but a copy
       of it on the transaction's log, so the thread can write to the referenced
       memory without worry about synchronization
       </remarks>
    */
    public object ReadTVar (GTVar tvar)
    {
      if (tvar == null)
	throw new ArgumentNullException ();

      return tvar.Read (tx);
    }

    /**
       <summary>
       Composition by OrElse alternative: the given transaction is run if this transaction
       blocks. This allows to wait for many things at once.
       </summary>
       <remarks>
       Remember that this method is destructive on the current transaction and
       the transaction passed as argument. That is, after calling this method, both
       <c>otherTx</c> and the current transaction will not the same as previous, but will be
       the 'orElse' composition of both. If you want to keep the original transactions, make
       a clone first.
       </remarks>
    */
    public GTransaction OrElse (GTransaction otherTx)
    {
      if (otherTx == null)
	throw new ArgumentNullException ();

      if (otherTx == this)
        throw new LibCMTException ("An OrElse composition of a transaction with itself (or "
                                   +"a subtransaction of itself) is not allowed. If this is "
                                   +"really what you want to do, use GTransaction.Clone() "
                                   +"first");
      tx = g_transaction_or_else (this.tx, otherTx.tx);
      // TODO we must set this too?
      // otherTx.tx = tx;
      return this;
    }

    private void Marshaller (IntPtr tx, IntPtr data)
    {
      Console.WriteLine ("We are in the Marshaller of {0}", this.name);
      tx_func (this, null);
    }

    /**
       <summary> Perform the transaction. </summary>
       <param name="arg"> Extra argument to be passed to the GTransactionFunc when
       executed.</param>
       <returns><c>true</c> if the transaction was performed successfully, <c>false</c> if
       it was aborted.</returns>
    */
    public bool Run (object arg)
    {
      return g_transaction_do (tx, IntPtr.Zero);
    }

    /**
       <summary> Block the transaction. </summary>
       <remarks>
       This function is intended to be used by the
       <see cref="LibCMT.GTransaction.GTransactionFunc"/>.
       When called, it blocks the current transaction until somebody commit to any of the
       <see cref="LibCMT.GTVar"/>'s that the transaction have read up to the
       current point. Then, the transaction is started from the beginning, but noticed
       about the new changes.

       It must be noted that blocking here is compositional, in the sense that the
       programmer must not identify the conditions under which the transaction can run
       to completion, it just make this function call to block the transaction, and the
       library takes care of wake up the thread when the conditions are (possibly) meet.
       </remarks>
    */
    public void Retry ()
    {
      g_transaction_retry (this.tx);
    }

    /**
       <summary> Abort the transaction immediately. </summary>
       This function is intended to be used by the
       <see cref="LibCMT.GTransaction.GTransactionFunc"/>.
    */
    public void Abort ()
    {
      g_transaction_abort (this.tx);
    }

    public object Clone ()
    {
      // TODO
      return null;
    }
  }

  /**
     <summary>
     Class representing a transactional variable which encapsulates a shared variable.
     </summary>
     <remarks>
     Every program variable shared among different threads that will be accessed from a 
     transaction function, must be encapsulated into a transactional variable representing
     it. The shared variable must implement the <see cref="LibCMT.ILibCMTCommittable"/>
     interface.
     </remarks>
     <seealso cref="LibCMT.GTransaction"/>
     <seealso cref="LibCMT.ILibCMTCommittable"/>
   */
  public sealed class GTVar
  {
    private delegate int    _GCompareFunc                 (IntPtr a, IntPtr b);
    private delegate IntPtr _GTVarDupFunc                 (IntPtr svar);
    private delegate void   _GDestroyNotify               (IntPtr svar);
    private delegate void   _GTVarCopyFunc                (IntPtr dst, IntPtr src);

    private delegate void   _GTransactionCommitCallback   (IntPtr svar, IntPtr resultVar);

    [DllImport("libcmt.dll")]
    static extern IntPtr g_transaction_var_new            (IntPtr var,
                                                           _GTVarDupFunc dup_func,
                                                           _GDestroyNotify destroyer,
                                                           _GCompareFunc compare);
    [DllImport("libcmt.dll")]
    static extern void   g_transaction_add_tvar           (IntPtr tx, IntPtr tvar);
    [DllImport("libcmt.dll")]
    static extern IntPtr g_transaction_read_tvar          (IntPtr tx, IntPtr tvar);
    [DllImport("libcmt.dll")]
    static extern void   g_transaction_var_set_commit_callback (IntPtr tvar,
                                                                _GTransactionCommitCallback cb);

    private IntPtr     tvar_handle;
    private object     shared_object;
    private Hashtable  tvars;     /* Mapping from shared objects to its native
                                     GTVar handles */
    private Hashtable  objects;   /* Mapping from IntPtr's to objects */

    private static int next_object_id = 0;

    public GTVar (object sharedObject, bool isPrimitive)
    {
      IntPtr dummy;

      if (sharedObject == null)
        throw new ArgumentNullException ("GTVar(): sharedObject is null");

      tvars = new Hashtable();
      objects = new Hashtable();

      if (!(sharedObject is ILibCMTCommittable))
        throw new LibCMTException ("CreateTVar(): the object must implement the "
                                   +"ILibCMTCommittable interface.");

      lock (this)
	{
	  dummy = new IntPtr (++next_object_id);
	}
      shared_object = sharedObject;
      objects[dummy.ToInt32()] = sharedObject;
      if (isPrimitive) {
	throw new NotImplementedException ("The shared variable must be of an object type");
      } else {
        _GTVarDupFunc dup = new _GTVarDupFunc (DefaultDup);
        _GDestroyNotify destroy = new _GDestroyNotify (DefaultDestroy);
        _GCompareFunc compare = new _GCompareFunc (DefaultCompare);
        
        tvar_handle = g_transaction_var_new (dummy,
					     dup,
					     destroy,
					     compare);
      }
      tvars[sharedObject] = tvar_handle;
      Console.WriteLine ("CreateTVar(): New pinned object: " + dummy.ToInt32());
    }

    internal IntPtr NativeTransaction {
      set {
	g_transaction_add_tvar (value, tvar_handle);
	_GTransactionCommitCallback commitCb = new _GTransactionCommitCallback (CommitCallback);
	g_transaction_var_set_commit_callback (tvar_handle, commitCb);
      }
    }

    internal object Read (IntPtr tx)
    {
      if (shared_object == null)
	throw new LibCMTException ("ReadTVar(): null object!");

      if (tvar_handle == IntPtr.Zero)
	throw new LibCMTException ("ReadTVar(): tvar_handle null!");

      if (tx == IntPtr.Zero)
	throw new LibCMTException ("ReadTVar(): this GTVar is not part of any transaction");
      
      IntPtr copyOfSharedVar = g_transaction_read_tvar (tx, tvar_handle);
      Console.WriteLine ("ReadTVar(): get pinned object " + copyOfSharedVar.ToInt32());

      object ret = objects[copyOfSharedVar.ToInt32()];
      if (ret == null)
        throw new LibCMTException ("ReadTVar(): cannot find object copy!");

      return ret;
    }

    private void CommitCallback (IntPtr svar, IntPtr resultVar)
    {
      if (resultVar == IntPtr.Zero)
        throw new LibCMTException ("CommitCallback(): native resultVar is null");

      Console.WriteLine ("CommitCallback: [{0}] = {1}", svar, resultVar);
      object txResult = objects[resultVar.ToInt32()];

      (shared_object as ILibCMTCommittable).Commit (txResult);
    }

    private int DefaultCompare (IntPtr a, IntPtr b)
    {
      if (a == IntPtr.Zero || b == IntPtr.Zero)
        throw new LibCMTException ("DefaultCompare(): native null pointers!");

      object aObj = objects[a.ToInt32()];
      object bObj = objects[b.ToInt32()];

      if (aObj == null || bObj == null)
        throw new LibCMTException ("DefaultCompare(): cannot find objects");

      int res = (aObj as IComparable).CompareTo(bObj as IComparable);
      Console.WriteLine ("DefaultCompare({0},{1}): {2}", aObj, bObj, res);
      return res;
    }

    private IntPtr DefaultDup (IntPtr var)
    {
      IntPtr res;

      if (var == IntPtr.Zero)
        throw new LibCMTException ("DefaultDup(): native null pointer!");

      object o = objects[var.ToInt32()];

      if (o == null)
        throw new LibCMTException ("DefaultDup(): cannot find source object "
                             +var.ToInt32());

      object copy = ((o as ICloneable).Clone());

      lock (this)
	{
	  res = new IntPtr (++next_object_id);
	}
      objects[res.ToInt32()] = copy;

      Console.WriteLine ("DefaultDup(): created new pinned object: " + res.ToInt32());

      return res;
    }

    private void DefaultDestroy (IntPtr var)
    {
      object o = objects[var.ToInt32()];

      if (o == null)
        throw new LibCMTException ("DefaultDestroy(): cannot find source object " + var.ToInt32());
      
      objects[var.ToInt32()] = null;
    }
  }

  internal class LibCMTException : Exception
  {
    public LibCMTException (string msg) : base ("LibCMT.GTransaction::" + msg) {}
  }
}
