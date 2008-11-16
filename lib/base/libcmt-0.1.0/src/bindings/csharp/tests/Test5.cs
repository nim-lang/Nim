//
// Test of basic transactional variable's usage, without threading.
//

using System;
using LibCMT;

public class A : ILibCMTCommittable
{
  public int x, y;

  public A ()
  {
    x = 9;
    y = 10;
  }

  public object Clone ()
  {
    A ret = new A();

    ret.x = this.x;
    ret.y = this.y;

    return ret;
  }

  public int CompareTo (object o)
  {
    A a = o as A;
    if (a.x == this.x && a.y == this.y)
      return 0;
    else
      return 1;
  }

  public void Dispose ()
  {
    ;
  }

  public void Commit (object o)
  {
    A a = o as A;

    x = a.x;
    y = a.y;
  }
}

public class Test5
{
  public A a;
  public GTVar aTx;

  public void changeA (GTransaction tx, object user_data)
  {
    object o;
    A localA;

    Console.WriteLine ("Entering changeA()...");
    o = tx.ReadTVar (aTx);
    localA = o as A;

    localA.x = localA.x + localA.y;
  }
  
  public static void Main ()
  {
    Test5 app = new Test5();

    Console.WriteLine ("Creating the callback...");
    GTransaction.GTransactionFunc cb = new GTransaction.GTransactionFunc (app.changeA);
    
    Console.WriteLine ("Creating the transaction...");
    GTransaction tx = new GTransaction ("changeA", cb, null);

    app.a = new A();
    app.aTx = new GTVar (app.a, false);

    tx.AddTVar (app.aTx);
    
    Console.WriteLine ("a.x = {0}", app.a.x);
    Console.WriteLine ("Running the transaction...");
    tx.Run (null);
    Console.WriteLine ("a.x = {0}", app.a.x);

    Console.WriteLine ("Exit");
  }
}
