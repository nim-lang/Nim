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

// the Pascal version number gets a little star ('*'), the Nimrod version
// does not! This helps distinguishing the different builds.
{@ignore}
const
  VersionStar = '*'+'';
{@emit
const
  VersionStar = '';
}

const
  MaxSetElements = 1 shl 16; // (2^16) to support unicode character sets?
  defaultAsmMarkerSymbol = '!';

  //[[[cog
  //from koch import NIMROD_VERSION
  //cog.outl("VersionAsString = '%s'+VersionStar;" % NIMROD_VERSION)
  //ver = NIMROD_VERSION.split('.')
  //cog.outl('VersionMajor = %s;' % ver[0])
  //cog.outl('VersionMinor = %s;' % ver[1])
  //cog.outl('VersionPatch = %s;' % ver[2])
  //]]]
  VersionAsString = '0.6.0'+VersionStar;
  VersionMajor = 0;
  VersionMinor = 6;
  VersionPatch = 0;
  //[[[[end]]]]

implementation

end.
