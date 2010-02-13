program hashtest;

{$include 'config.inc'}

uses
  nhashes;

begin
  writeln(output, getNormalizedHash(ParamStr(1)));
end.
