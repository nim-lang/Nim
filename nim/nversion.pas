//
//
//           The Nimrod Compiler
//        (c) Copyright 2008 Andreas Rumpf
//
//    See the file "copying.txt", included in this
//    distribution, for details about the copyright.
//

unit nversion;

// this unit implements the version handling

interface

{$include 'config.inc'}

uses
  strutils;

const
  MaxSetElements = 1 shl 16; // (2^16) to support unicode character sets?
  defaultAsmMarkerSymbol = '!';

  //[[[cog
  //from koch import NIMROD_VERSION
  //cog.outl("VersionAsString = '%s';" % NIMROD_VERSION)
  //ver = NIMROD_VERSION.split('.')
  //cog.outl('VersionMajor = %s;' % ver[0])
  //cog.outl('VersionMinor = %s;' % ver[1])
  //cog.outl('VersionPatch = %s;' % ver[2])
  //]]]
  VersionAsString = '0.5.1';
  VersionMajor = 0;
  VersionMinor = 5;
  VersionPatch = 1;
  //[[[[end]]]]

implementation

end.
