//
// Test of basic transactional variable's usage, with threading.
//

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
