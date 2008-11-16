#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2008 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module implements the Difference Algorithm published in
## "An O(ND) Difference Algorithm and its Variations" by Eugene Myers
## Algorithmica Vol. 1 No. 2, 1986, p 251.  

## This implementation is based on:
##
## diff.cs: A port of the algorythm to C#
## Copyright (c) by Matthias Hertel, http://www.mathertel.de
## This work is licensed under a BSD style license. 
## See http://www.mathertel.de/License.aspx

{.push debugger:off .} # the user does not want to trace a part
                       # of the standard library!

import 
  strutils

type
  TResultItem* = object of TObject
    startA*: int ## start of line number in A
    startB*: int ## start of line number in B
    deletedA*: int ## number of deletions in A
    deletedB*: int ## number of deletions in B

  SMSRD = tuple[x, y: int] ## shortest middle snake return data
  
  TDiffData {.final.} = object 
    len: int
    data: seq[int]
    modified: seq[bool]
  
proc diffText*(a, b: seq[string], 
               eq: proc (x, y: string): bool): seq[TResultItem] =
  ## returns the difference of two texts `a` and `b`. The texts are compared
  ## line by line with the `eq` proc.
  nil

proc diffText*(a, b: string, eq: proc (x, y: string): bool): seq[TResultItem] =
  ## returns the difference of two texts `a` and `b`. The texts are compared
  ## line by line with the `eq` proc.
  result = diffText(linesSeq(a), linesSeq(b), eq)

    /// <summary>details of one difference.</summary>
    public struct Item
    {
      /// <summary>Start Line number in Data A.</summary>
      public int StartA;
      /// <summary>Start Line number in Data B.</summary>
      public int StartB;

      /// <summary>Number of changes in Data A.</summary>
      public int deletedA;
      /// <summary>Number of changes in Data B.</summary>
      public int insertedB;
    } // Item

    /// <summary>
    /// Shortest Middle Snake Return Data
    /// </summary>
    private struct SMSRD
    {
      internal int x, y;
      // internal int u, v;  // 2002.09.20: no need for 2 points 
    }


    /// <summary>
    /// Find the difference in 2 texts, comparing by textlines.
    /// </summary>
    /// <param name="TextA">A-version of the text (usualy the old one)</param>
    /// <param name="TextB">B-version of the text (usualy the new one)</param>
    /// <returns>Returns a array of Items that describe the differences.</returns>
    public Item[] DiffText(string TextA, string TextB) {
      return (DiffText(TextA, TextB, false, false, false));
    } // DiffText


    /// <summary>
    /// Find the difference in 2 text documents, comparing by textlines.
    /// The algorithm itself is comparing 2 arrays of numbers so when comparing 2 text documents
    /// each line is converted into a (hash) number. This hash-value is computed by storing all
    /// textlines into a common hashtable so i can find dublicates in there, and generating a 
    /// new number each time a new textline is inserted.
    /// </summary>
    /// <param name="TextA">A-version of the text (usualy the old one)</param>
    /// <param name="TextB">B-version of the text (usualy the new one)</param>
    /// <param name="trimSpace">When set to true, all leading and trailing whitespace characters are stripped out before the comparation is done.</param>
    /// <param name="ignoreSpace">When set to true, all whitespace characters are converted to a single space character before the comparation is done.</param>
    /// <param name="ignoreCase">When set to true, all characters are converted to their lowercase equivivalence before the comparation is done.</param>
    /// <returns>Returns a array of Items that describe the differences.</returns>
    public static Item[] DiffText(string TextA, string TextB, bool trimSpace, bool ignoreSpace, bool ignoreCase) {
      // prepare the input-text and convert to comparable numbers.
      Hashtable h = new Hashtable(TextA.Length + TextB.Length);

      // The A-Version of the data (original data) to be compared.
      DiffData DataA = new DiffData(DiffCodes(TextA, h, trimSpace, ignoreSpace, ignoreCase));

      // The B-Version of the data (modified data) to be compared.
      DiffData DataB = new DiffData(DiffCodes(TextB, h, trimSpace, ignoreSpace, ignoreCase));

      h = null; // free up hashtable memory (maybe)

      int MAX = DataA.Length + DataB.Length + 1;
      /// vector for the (0,0) to (x,y) search
      int[] DownVector = new int[2 * MAX + 2];
      /// vector for the (u,v) to (N,M) search
      int[] UpVector = new int[2 * MAX + 2];

      LCS(DataA, 0, DataA.Length, DataB, 0, DataB.Length, DownVector, UpVector);

      Optimize(DataA);
      Optimize(DataB);
      return CreateDiffs(DataA, DataB);
    } // DiffText


proc Optimize(d: var TDiffData) =
  ## If a sequence of modified lines starts with a line that contains the 
  ## same content as the line that appends the changes, the difference sequence
  ## is modified so that the appended line and not the starting line is marked
  ## as modified. This leads to more readable diff sequences when comparing
  ## text files.
  var startPos = 0
  while startPos < d.len:
    while StartPos < d.len and not d.modified[StartPos]: inc(startPos)
    var endPos = startPos
    while EndPos < d.len and d.modified[EndPos]: inc(endPos)
    if EndPos < d.len and d.data[StartPos] == d.data[EndPos]:
      d.modified[StartPos] = false
      d.modified[EndPos] = true
    else:
      StartPos = EndPos


    /// <summary>
    /// Find the difference in 2 arrays of integers.
    /// </summary>
    /// <param name="ArrayA">A-version of the numbers (usualy the old one)</param>
    /// <param name="ArrayB">B-version of the numbers (usualy the new one)</param>
    /// <returns>Returns a array of Items that describe the differences.</returns>
    public static Item[] DiffInt(int[] ArrayA, int[] ArrayB) {
      // The A-Version of the data (original data) to be compared.
      DiffData DataA = new DiffData(ArrayA);

      // The B-Version of the data (modified data) to be compared.
      DiffData DataB = new DiffData(ArrayB);

      int MAX = DataA.Length + DataB.Length + 1;
      /// vector for the (0,0) to (x,y) search
      int[] DownVector = new int[2 * MAX + 2];
      /// vector for the (u,v) to (N,M) search
      int[] UpVector = new int[2 * MAX + 2];

      LCS(DataA, 0, DataA.Length, DataB, 0, DataB.Length, DownVector, UpVector);
      return CreateDiffs(DataA, DataB);
    } // Diff


    /// <summary>
    /// This function converts all textlines of the text into unique numbers for every unique textline
    /// so further work can work only with simple numbers.
    /// </summary>
    /// <param name="aText">the input text</param>
    /// <param name="h">This extern initialized hashtable is used for storing all ever used textlines.</param>
    /// <param name="trimSpace">ignore leading and trailing space characters</param>
    /// <returns>a array of integers.</returns>
    private static int[] DiffCodes(string aText, Hashtable h, bool trimSpace, bool ignoreSpace, bool ignoreCase) {
      // get all codes of the text
      string[] Lines;
      int[] Codes;
      int lastUsedCode = h.Count;
      object aCode;
      string s;

      // strip off all cr, only use lf as textline separator.
      aText = aText.Replace("\r", "");
      Lines = aText.Split('\n');

      Codes = new int[Lines.Length];

      for (int i = 0; i < Lines.Length; ++i) {
        s = Lines[i];
        if (trimSpace)
          s = s.Trim();

        if (ignoreSpace) {
          s = Regex.Replace(s, "\\s+", " ");            // TODO: optimization: faster blank removal.
        }

        if (ignoreCase)
          s = s.ToLower();

        aCode = h[s];
        if (aCode == null) {
          lastUsedCode++;
          h[s] = lastUsedCode;
          Codes[i] = lastUsedCode;
        } else {
          Codes[i] = (int)aCode;
        } // if
      } // for
      return (Codes);
    } // DiffCodes


    /// <summary>
    /// This is the algorithm to find the Shortest Middle Snake (SMS).
    /// </summary>
    /// <param name="DataA">sequence A</param>
    /// <param name="LowerA">lower bound of the actual range in DataA</param>
    /// <param name="UpperA">upper bound of the actual range in DataA (exclusive)</param>
    /// <param name="DataB">sequence B</param>
    /// <param name="LowerB">lower bound of the actual range in DataB</param>
    /// <param name="UpperB">upper bound of the actual range in DataB (exclusive)</param>
    /// <param name="DownVector">a vector for the (0,0) to (x,y) search. Passed as a parameter for speed reasons.</param>
    /// <param name="UpVector">a vector for the (u,v) to (N,M) search. Passed as a parameter for speed reasons.</param>
    /// <returns>a MiddleSnakeData record containing x,y and u,v</returns>
    private static SMSRD SMS(DiffData DataA, int LowerA, int UpperA, DiffData DataB, int LowerB, int UpperB,
      int[] DownVector, int[] UpVector) {

      SMSRD ret;
      int MAX = DataA.Length + DataB.Length + 1;

      int DownK = LowerA - LowerB; // the k-line to start the forward search
      int UpK = UpperA - UpperB; // the k-line to start the reverse search

      int Delta = (UpperA - LowerA) - (UpperB - LowerB);
      bool oddDelta = (Delta & 1) != 0;

      // The vectors in the publication accepts negative indexes. the vectors implemented here are 0-based
      // and are access using a specific offset: UpOffset UpVector and DownOffset for DownVektor
      int DownOffset = MAX - DownK;
      int UpOffset = MAX - UpK;

      int MaxD = ((UpperA - LowerA + UpperB - LowerB) / 2) + 1;

      // Debug.Write(2, "SMS", String.Format("Search the box: A[{0}-{1}] to B[{2}-{3}]", LowerA, UpperA, LowerB, UpperB));

      // init vectors
      DownVector[DownOffset + DownK + 1] = LowerA;
      UpVector[UpOffset + UpK - 1] = UpperA;

      for (int D = 0; D <= MaxD; D++) {

        // Extend the forward path.
        for (int k = DownK - D; k <= DownK + D; k += 2) {
          // Debug.Write(0, "SMS", "extend forward path " + k.ToString());

          // find the only or better starting point
          int x, y;
          if (k == DownK - D) {
            x = DownVector[DownOffset + k + 1]; // down
          } else {
            x = DownVector[DownOffset + k - 1] + 1; // a step to the right
            if ((k < DownK + D) && (DownVector[DownOffset + k + 1] >= x))
              x = DownVector[DownOffset + k + 1]; // down
          }
          y = x - k;

          // find the end of the furthest reaching forward D-path in diagonal k.
          while ((x < UpperA) && (y < UpperB) && (DataA.data[x] == DataB.data[y])) {
            x++; y++;
          }
          DownVector[DownOffset + k] = x;

          // overlap ?
          if (oddDelta && (UpK - D < k) && (k < UpK + D)) {
            if (UpVector[UpOffset + k] <= DownVector[DownOffset + k]) {
              ret.x = DownVector[DownOffset + k];
              ret.y = DownVector[DownOffset + k] - k;
              // ret.u = UpVector[UpOffset + k];      // 2002.09.20: no need for 2 points 
              // ret.v = UpVector[UpOffset + k] - k;
              return (ret);
            } // if
          } // if

        } // for k

        // Extend the reverse path.
        for (int k = UpK - D; k <= UpK + D; k += 2) {
          // Debug.Write(0, "SMS", "extend reverse path " + k.ToString());

          // find the only or better starting point
          int x, y;
          if (k == UpK + D) {
            x = UpVector[UpOffset + k - 1]; // up
          } else {
            x = UpVector[UpOffset + k + 1] - 1; // left
            if ((k > UpK - D) && (UpVector[UpOffset + k - 1] < x))
              x = UpVector[UpOffset + k - 1]; // up
          } // if
          y = x - k;

          while ((x > LowerA) && (y > LowerB) && (DataA.data[x - 1] == DataB.data[y - 1])) {
            x--; y--; // diagonal
          }
          UpVector[UpOffset + k] = x;

          // overlap ?
          if (!oddDelta && (DownK - D <= k) && (k <= DownK + D)) {
            if (UpVector[UpOffset + k] <= DownVector[DownOffset + k]) {
              ret.x = DownVector[DownOffset + k];
              ret.y = DownVector[DownOffset + k] - k;
              // ret.u = UpVector[UpOffset + k];     // 2002.09.20: no need for 2 points 
              // ret.v = UpVector[UpOffset + k] - k;
              return (ret);
            } // if
          } // if

        } // for k

      } // for D

      throw new ApplicationException("the algorithm should never come here.");
    } // SMS


    /// <summary>
    /// This is the divide-and-conquer implementation of the longes common-subsequence (LCS) 
    /// algorithm.
    /// The published algorithm passes recursively parts of the A and B sequences.
    /// To avoid copying these arrays the lower and upper bounds are passed while the sequences stay constant.
    /// </summary>
    /// <param name="DataA">sequence A</param>
    /// <param name="LowerA">lower bound of the actual range in DataA</param>
    /// <param name="UpperA">upper bound of the actual range in DataA (exclusive)</param>
    /// <param name="DataB">sequence B</param>
    /// <param name="LowerB">lower bound of the actual range in DataB</param>
    /// <param name="UpperB">upper bound of the actual range in DataB (exclusive)</param>
    /// <param name="DownVector">a vector for the (0,0) to (x,y) search. Passed as a parameter for speed reasons.</param>
    /// <param name="UpVector">a vector for the (u,v) to (N,M) search. Passed as a parameter for speed reasons.</param>
    private static void LCS(DiffData DataA, int LowerA, int UpperA, DiffData DataB, int LowerB, int UpperB, int[] DownVector, int[] UpVector) {
      // Debug.Write(2, "LCS", String.Format("Analyse the box: A[{0}-{1}] to B[{2}-{3}]", LowerA, UpperA, LowerB, UpperB));

      // Fast walkthrough equal lines at the start
      while (LowerA < UpperA && LowerB < UpperB && DataA.data[LowerA] == DataB.data[LowerB]) {
        LowerA++; LowerB++;
      }

      // Fast walkthrough equal lines at the end
      while (LowerA < UpperA && LowerB < UpperB && DataA.data[UpperA - 1] == DataB.data[UpperB - 1]) {
        --UpperA; --UpperB;
      }

      if (LowerA == UpperA) {
        // mark as inserted lines.
        while (LowerB < UpperB)
          DataB.modified[LowerB++] = true;

      } else if (LowerB == UpperB) {
        // mark as deleted lines.
        while (LowerA < UpperA)
          DataA.modified[LowerA++] = true;

      } else {
        // Find the middle snakea and length of an optimal path for A and B
        SMSRD smsrd = SMS(DataA, LowerA, UpperA, DataB, LowerB, UpperB, DownVector, UpVector);
        // Debug.Write(2, "MiddleSnakeData", String.Format("{0},{1}", smsrd.x, smsrd.y));

        // The path is from LowerX to (x,y) and (x,y) to UpperX
        LCS(DataA, LowerA, smsrd.x, DataB, LowerB, smsrd.y, DownVector, UpVector);
        LCS(DataA, smsrd.x, UpperA, DataB, smsrd.y, UpperB, DownVector, UpVector);  // 2002.09.20: no need for 2 points 
      }
    } // LCS()


    /// <summary>Scan the tables of which lines are inserted and deleted,
    /// producing an edit script in forward order.  
    /// </summary>
    /// dynamic array
    private static Item[] CreateDiffs(DiffData DataA, DiffData DataB) {
      ArrayList a = new ArrayList();
      Item aItem;
      Item[] result;

      int StartA, StartB;
      int LineA, LineB;

      LineA = 0;
      LineB = 0;
      while (LineA < DataA.Length || LineB < DataB.Length) {
        if ((LineA < DataA.Length) && (!DataA.modified[LineA])
          && (LineB < DataB.Length) && (!DataB.modified[LineB])) {
          // equal lines
          LineA++;
          LineB++;

        } else {
          // maybe deleted and/or inserted lines
          StartA = LineA;
          StartB = LineB;

          while (LineA < DataA.Length && (LineB >= DataB.Length || DataA.modified[LineA]))
            // while (LineA < DataA.Length && DataA.modified[LineA])
            LineA++;

          while (LineB < DataB.Length && (LineA >= DataA.Length || DataB.modified[LineB]))
            // while (LineB < DataB.Length && DataB.modified[LineB])
            LineB++;

          if ((StartA < LineA) || (StartB < LineB)) {
            // store a new difference-item
            aItem = new Item();
            aItem.StartA = StartA;
            aItem.StartB = StartB;
            aItem.deletedA = LineA - StartA;
            aItem.insertedB = LineB - StartB;
            a.Add(aItem);
          } // if
        } // if
      } // while

      result = new Item[a.Count];
      a.CopyTo(result);

      return (result);
    }

  } // class Diff

  /// <summary>Data on one input file being compared.  
  /// </summary>
  internal class DiffData
  {

    /// <summary>Number of elements (lines).</summary>
    internal int Length;

    /// <summary>Buffer of numbers that will be compared.</summary>
    internal int[] data;

    /// <summary>
    /// Array of booleans that flag for modified data.
    /// This is the result of the diff.
    /// This means deletedA in the first Data or inserted in the second Data.
    /// </summary>
    internal bool[] modified;

    /// <summary>
    /// Initialize the Diff-Data buffer.
    /// </summary>
    /// <param name="data">reference to the buffer</param>
    internal DiffData(int[] initData) {
      data = initData;
      Length = initData.Length;
      modified = new bool[Length + 2];
    } // DiffData

  } // class DiffData

{.pop.}
