//
// Very simple test, just to see if interaction with native platform is right.
// There are no threading nor transactional variables.
//

using System;
using LibCMT;

public class Test1
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
        GTransaction tx = new GTransaction ("Test1", helloCb, null);

        Console.WriteLine ("Running the transaction...");
        tx.Run (null);

        Console.WriteLine ("Exit");
    }
}
