struct vector3d
{
    float V[3];
    inline float Evaluate( const int I ) const { return V[I]; }

    template< class ta >
    inline const vector3d& operator = ( const ta& Exp )
    {
        V[0] = Exp.Evaluate( 0 );
        V[1] = Exp.Evaluate( 1 );
        V[2] = Exp.Evaluate( 2 );
    }
};

type
  TVector3D = record
    v: array [0..2, float]
    
  TSum[A, B] = record
  TVecExpr2[A, B, op] = record
    
proc eval(a: TVector3d, i: int): float = a.v[i]
proc eval[T, S](a: T, b: S, i: int): float = eval(a, i) + eval(b, i)

proc `+` [T, S](a, b: TVector3d): TSum[T, S] = return vecExpr2[a, b, TSum]

proc `=` [T](a: var TVector3d, b: T) =
  a.v[0] = eval(b, 0)
  a.v[1] = eval(b, 1)
  a.v[2] = eval(b, 2)

macro `=` (a: var TVector3d, b: expr) =
  
proc doSomething(a, b: TVector3d): TVector3d =
  eliminateTemps:
    result = a +^ b +^ a *^ a *^ 7
  # result = a
  # result +^= b
  # tmp = a
  # tmp *^= a
  # tmp *^= 7
  # result +^= tmp
  
macro vectorOptimizeExpr(n: expr): stmt =
  # load the expr n[1] into n[0]
  var e = n[1]
  if binOp(e) and Operator(e) == "+^":
    var m = flattenTree(n[1])
    result = newAst(nkStmtList) # ``newAst`` is built-in for any macro
    add(result, newAst(nkAsgn, n[0], m[1]))
    var tmp: PNode = nil
    for i in 2..m.len-1:
      if BinOp(m[i]):
        if tmp = nil: tmp = getTemp() # reuse temporary if possible
        vectorOptimizeExpr(newAst(nkAsgn, tmp, m[i]))
        add(result, newAst(nkCall, Operator(m) & "=", n[0], tmp))
      else:
        add(result, newAst(nkCall, Operator(m) & "=", n[0], m[i]))
  
macro eliminateTemps(s) {.check.} =
  case s.kind
  of nkAsgnStmt:
    result = vectorOptimizeExpr(s)
  else:
    result = s
    for i in 0..s.sons.len-1: result[i] = eliminateTemps(s[i])
 
struct sum
{
    template< class ta, class tb >
    static inline float Evaluate( const int I, const ta& A, const tb& B )
    { return A.Evaluate( I ) + B.Evaluate( I ); }
};

 

template< class ta_a, class ta_b, class ta_eval >
class vecexp_2
{
   const ta_a   Arg1;
   const ta_b   Arg2;

public:
    inline vecexp_2( const ta_a& A1, const ta_b& A2 ) 
     : Arg1( A1 ), Arg2( A2 ) {}
    inline const float Evaluate ( const int I ) const
    { return ta_eval::Evaluate( I, Arg1, Arg2 ); }
};
 

template< class ta, class tb > inline
vecexp_2< ta, tb, sum > 
inline operator + ( const ta& A, const tb& B )
{
    return vecexp_2< const ta, const tb, sum >( A, B );
}