//
// A solution to the classical problem of the dinning philosophers.
//

using System;
using System.Threading;
using LibCMT;

public class Fork : ILibCMTCommittable
{
  public bool inUse;
  public int  numberOfUses;

  public Fork ()
  {
    inUse = false;
    numberOfUses = 0;
  }

  public object Clone ()
  {
    Fork ret = new Fork();

    ret.inUse = this.inUse;
    ret.numberOfUses = this.numberOfUses;

    return ret;
  }

  public int CompareTo (object o)
  {
    if (o == null)
      throw new ArgumentNullException ();

    Fork a = o as Fork;
    if (a.inUse == this.inUse
	&& a.numberOfUses == this.numberOfUses)
      return 0;
    else
      return 1;
  }

  public void Commit (object o)
  {
    if (o == null)
      throw new ArgumentNullException ();

    Fork a = o as Fork;

    inUse = a.inUse;
    numberOfUses = a.numberOfUses;
  }
}

public class Philosopher
{
  private string name;
  private GTVar leftFork, rightFork;

  public Philosopher (string name)
  {
    this.name = name;
  }

  public GTVar RightFork
  {
    set { rightFork = value; }
  }

  public GTVar LeftFork
  {
    set { leftFork = value; }
  }

  public void TakeForks (GTransaction tx, object user_data)
  {
    object a, b;
    Fork lf, rf;

    a = tx.ReadTVar (leftFork);
    lf = a as Fork;
    b = tx.ReadTVar (rightFork);
    rf = b as Fork;

    if (lf.inUse || rf.inUse)
      tx.Retry();

    lf.inUse = rf.inUse = true;
    lf.numberOfUses++;
    rf.numberOfUses++;

    Console.WriteLine (name + " take forks");
  }

  public void DownForks (GTransaction tx, object user_data)
  {
    object a, b;
    Fork lf, rf;

    a = tx.ReadTVar (leftFork);
    lf = a as Fork;
    b = tx.ReadTVar (rightFork);
    rf = b as Fork;

    lf.inUse = rf.inUse = false;

    Console.WriteLine (name + " down forks");    
  }

  public void DoPhilosophy ()
  {
    GTransaction.GTransactionFunc cb = new GTransaction.GTransactionFunc (TakeForks);
    GTransaction txTakeForks = new GTransaction ("TakeForks", cb, null);
    txTakeForks.AddTVar (leftFork);
    txTakeForks.AddTVar (rightFork);

    cb = new GTransaction.GTransactionFunc (DownForks);
    GTransaction txDownForks = new GTransaction ("DownForks", cb, null);
    txDownForks.AddTVar (leftFork);
    txDownForks.AddTVar (rightFork);

    Random rand = new Random();
    for (int i = 0; i < 2; i++) {
      txTakeForks.Run (null);
      // eat a little
      Thread.Sleep (rand.Next() % 1000);
      txDownForks.Run (null);
    }
  }
}

public class PhiloTest
{
  private const int NR_PHILO = 5;

  private readonly Philosopher[] philosophers;
  private readonly Fork[]        forks;
  private readonly GTVar[]       txForks;

  public PhiloTest ()
  {
    // Mhmm, this is managed by the garbage collector, so probably it cause
    // troubles on the unmanaged side. Would be better to use the 'fixed'
    // array construction of .Net 2.0.
    philosophers = new Philosopher[NR_PHILO];
    forks = new Fork[NR_PHILO];
    txForks = new GTVar[NR_PHILO];

    // Create the forks and the transactional variables encapsulating it
    for (int i = 0; i < NR_PHILO; i++) {
      forks[i] = new Fork();
      txForks[i] = new GTVar (forks[i], false);
    }
    for (int i = 0; i < NR_PHILO; i++) {
      philosophers[i] = new Philosopher ("Philosopher"+(i+1));
      philosophers[i].LeftFork = txForks[i];
      philosophers[i].RightFork = txForks[(i+1)%NR_PHILO];
    }
    for (int i = 0; i < NR_PHILO; i++) {
      ThreadStart worker = new ThreadStart (philosophers[i].DoPhilosophy);
      Thread t = new Thread (worker);
      t.Start();
      t.Join();
    }
  }

  public void ShowResults ()
  {
    Console.WriteLine ("=============================================");
    for (int i = 0; i < NR_PHILO; i++)
      Console.WriteLine ("Fork " + (i+1) + " was used "
			 + forks[i].numberOfUses + " times");
  }

  public static void Main ()
  {
    PhiloTest app = new PhiloTest();
    
    app.ShowResults();
  }
}
