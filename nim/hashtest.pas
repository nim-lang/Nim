program hashtest;

{$include 'config.inc'}

uses
  hashes;

begin
  writeln(output, getNormalizedHash(ParamStr(1)));
end.
