# Code generator generator for the Nimrod compiler
#  (c) 2008 Andreas Rumpf

# The specification is done in simple Python code, so we don't do any real
# parsing here. We only deal with expression generation here. But this is
# the most work anyway.

# Syntax:

# $n  -- expr code of n'th son

CODEGEN = dict(
  mAddI = overflowOp('addI($1, $2)', '($1 + $2)'),
  mSubI = overflowOp('', ''),
  mAssert = code("""
    begin
      if (optAssert in p.Options) then begin
        useMagic(p.module, 'internalAssert');
        expr(p, n.sons[1], d);
        line := toRope(toLinenumber(e.info));
        filen := makeCString(ToFilename(e.info));
        appf(p.s[cpsStmts], 'internalAssert($1, $2, $3);$n',
            [filen, line, rdLoc(d)])
      end
    end;""")
  
  nkCast = code("""
    
  """),
  

)
