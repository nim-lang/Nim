#ifdef C2NIM
#  header "iup.h"
#  cdecl
#  mangle "'GTK_'{.*}" "TGtk$1"
#  mangle "'PGTK_'{.*}" "PGtk$1"
#endif

typedef struct stupidTAG {
  mytype a, b;
} GTK_MyStruct, *PGTK_MyStruct;

typedef struct  {
  mytype a, b;
} GTK_MyStruct, *PGTK_MyStruct;

int IupConvertXYToPos(PIhandle ih, int x, int y);

