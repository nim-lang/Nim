/*! \mainpage LibCMT C# binding

This is the API documentation for the C# binding of the
<a href="http://libcmt.sourceforge.net">LibCMT</a> library, that allows you to use a
<a href="http://en.wikipedia.org/wiki/Composable_Memory_Transactions">composable model
</a> of 
<a href="http://en.wikipedia.org/wiki/Software_transactional_memory">Software
Transactional Memory</a> from C#.

\section remarks Remarks

The shared object that wants to be engaged on a LibCMT transaction only 
needs to implement the <see cref="LibCMT.ILibCMTCommittable"/> interface (<c>Clone</c>,
<c>CompareTo</c> and <c>Commit</c> methods). After that, every shared object that will
be accessed from a transaction, must be encapsulated into a transactional variable (a
<see cref="LibCMT.GTVar"/>).

Then every thread creates and run the transactions (<see cref="LibCMT.GTransaction"/>)
it want to perform, without worry about synchronization: LibCMT does that job for you.

\section platforms Platforms

Although the LibCMT assembly (LibCMT.dll) containing the binding could be used on any
place where a .Net runtime is available, to be fully functional it also needs the native
library libcmt.dll or libcmt.so which is invoked using P/Invoke. So the availability of
LibCMT assembly will be restricted to platforms where the native library is supported 
(many Unix'es and soon Win32 too).

\section example Example

<example>
<description>
Basic transactional variable's usage, with threading:
</description>
<code>
using System;
using System.Threading;
using LibCMT;

public class A : ILibCMTCommittable
{
  public int x;

  public A ()
  {
    x = 0;
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

  public void Commit (object o)
  {
    A a = o as A;

    x = a.x;
  }
}

public class Test6
{
  public static A a;
  public static GTVar aTx;

  public Test6 ()
  {
    if (a == null)
      a = new A();
    if (aTx == null)
      aTx = new GTVar (a, false);
  }

  public static void ChangeA (GTransaction tx, object user_data)
  {
    object o;
    A localA;

    o = tx.ReadTVar (aTx);
    localA = o as A;

    localA.x++;
    Console.WriteLine (Thread.CurrentThread.Name + " set a.x = " + localA.x);
  }

  public static void WorkerMethod ()
  {
    GTransaction.GTransactionFunc cb = new GTransaction.GTransactionFunc (ChangeA);
    GTransaction tx = new GTransaction ("ChangeA", cb, null);
    tx.AddTVar (aTx);

    Random rand = new Random();
    for (int i = 0; i < 5; i++) {
      tx.Run (null);
      Thread.Sleep (rand.Next() % 1000);
    }
  }

  public static void Main ()
  {
    Test6 app = new Test6();

    ThreadStart worker = new ThreadStart (WorkerMethod);

    Thread t1 = new Thread (worker);
    Thread t2 = new Thread (worker);
    Thread t3 = new Thread (worker);

    t1.Name = "Worker1";
    t2.Name = "Worker2";
    t3.Name = "Worker3";
    t1.Start();
    t2.Start();
    t3.Start();

    t1.Join();
    t2.Join();
    t3.Join();

    Console.WriteLine ("Worker threads done, a.x = " + a.x);
    Console.WriteLine ("Exit");
  }
}
</code>

*/
