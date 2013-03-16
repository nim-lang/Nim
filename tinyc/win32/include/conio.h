/* A conio implementation for Mingw/Dev-C++.
 *
 * Written by:
 * Hongli Lai <hongli@telekabel.nl>
 * tkorrovi <tkorrovi@altavista.net> on 2002/02/26. 
 * Andrew Westcott <ajwestco@users.sourceforge.net>
 *
 * Offered for use in the public domain without any warranty.
 */

#ifndef _CONIO_H_
#define _CONIO_H_


#include <stdio.h>

#ifdef __cplusplus
extern "C" {
#endif

#define BLINK 0

typedef enum
{
    BLACK,
    BLUE,
    GREEN,
    CYAN,
    RED,
    MAGENTA,
    BROWN,
    LIGHTGRAY,
    DARKGRAY,
    LIGHTBLUE,
    LIGHTGREEN,
    LIGHTCYAN,
    LIGHTRED,
    LIGHTMAGENTA,
    YELLOW,
    WHITE
} COLORS;


#define cgets	_cgets
#define cprintf	_cprintf
#define cputs	_cputs
#define cscanf	_cscanf
#define ScreenClear clrscr

/* blinkvideo */

void clreol (void);
void clrscr (void);

int _conio_gettext (int left, int top, int right, int bottom,
                    char *str);
/* _conio_kbhit */

void delline (void);

/* gettextinfo */
void gotoxy(int x, int y);
/*
highvideo
insline
intensevideo
lowvideo
movetext
normvideo
*/

void puttext (int left, int top, int right, int bottom, char *str);

// Screen Variables

/* ScreenCols
ScreenGetChar
ScreenGetCursor
ScreenMode
ScreenPutChar
ScreenPutString
ScreenRetrieve
ScreenRows
ScreenSetCursor
ScreenUpdate
ScreenUpdateLine
ScreenVisualBell
_set_screen_lines */

void _setcursortype (int type);

void textattr (int _attr);

void textbackground (int color);

void textcolor (int color);

/* textmode */

int wherex (void);

int wherey (void);

/* window */



/*  The code below was part of Mingw's conio.h  */
/*
 * conio.h
 *
 * Low level console I/O functions. Pretty please try to use the ANSI
 * standard ones if you are writing new code.
 *
 * This file is part of the Mingw32 package.
 *
 * Contributors:
 *  Created by Colin Peters <colin@bird.fu.is.saga-u.ac.jp>
 *
 *  THIS SOFTWARE IS NOT COPYRIGHTED
 *
 *  This source code is offered for use in the public domain. You may
 *  use, modify or distribute it freely.
 *
 *  This code is distributed in the hope that it will be useful but
 *  WITHOUT ANY WARRANTY. ALL WARRANTIES, EXPRESS OR IMPLIED ARE HEREBY
 *  DISCLAMED. This includes but is not limited to warranties of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 *
 * $Revision: 1.2 $
 * $Author: bellard $
 * $Date: 2005/04/17 13:14:29 $
 *
 */

char*	_cgets (char*);
int	_cprintf (const char*, ...);
int	_cputs (const char*);
int	_cscanf (char*, ...);

int	_getch (void);
int	_getche (void);
int	_kbhit (void);
int	_putch (int);
int	_ungetch (int);


int	getch (void);
int	getche (void);
int	kbhit (void);
int	putch (int);
int	ungetch (int);


#ifdef __cplusplus
}
#endif

#endif /* _CONIO_H_ */
