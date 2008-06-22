{$define debug}
{.$define symtabdebug}
// uncomment this code for debugging the symbol table
// (shouldn't be used anymore; the symbol table is stable!)

{$ifdef fpc}
  {$inline on}
  {$mode delphi}
  {$define hasInline} // later versions of delphi have this too
  {$implicitexceptions off} // produce better code
  {$H+}
  {$warnings off} // FPC produces way too many warnings ...
{$else} // Delphi does not define these:
  {$define delphi} // Delphi does not even define a symbol for its compiler!
  {$define x86}
  {$define cpu386}
  {$define cpu387}
  {$define cpu86}
  {$define cpu87}
  {$define cpui386}
{$endif}

{.$define GC} // Boehm's GC is broken again! (I don't need it much longer!)
// define if we have a GC: if we have none, the compiler leaks memory,
// but it still should work for bootstraping (the OS will clean up later)

{$ifdef win32}
  {$ifndef mswindows} {$define mswindows} {$endif}
  {$ifndef windows} {$define windows} {$endif}
{$endif}

{$ifdef CPU386}
  {$define I386} // Delphi does not define this!
{$endif}

{$ifdef CPUI386}
  {$define I386}
{$endif}

{$ifdef CPUamd64}
  {$define amd64}
{$endif}

{$ifdef debug}
  {$define yamlgen} // when debugging we want the YAML code generator
  {$R+} {$Q+}   // turn code generation checks on
  {$ifndef fpc}
    {$O-} // deactivate optimization for Delphi
  {$endif}
  {$C+}  // turn assertions on
{$endif}

{$define cgen}  // activate later if parser is stable
{.$define vmgen} // vmgen is not up to date

{$ifdef cpu64}
  {$define bit64clean} // BUGFIX
{$endif}
{$ifdef fpc}
  {$define bit64clean}
{$endif}

