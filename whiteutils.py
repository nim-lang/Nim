""" Indentation utilities for Cog.
    http://nedbatchelder.com/code/cog

    Copyright 2004-2005, Ned Batchelder.
"""

# $Id: whiteutils.py 110 2005-08-27 22:35:20Z ned $
# modified to run with Python1.5.2 by Andreas Rumpf

import re, types
from string import strip, split, replace, join

def whitePrefix(strings):
    """ Determine the whitespace prefix common to all non-blank lines
        in the argument list.
    """
    # Remove all blank lines from the list
    strings = filter(lambda s: strip(s) != '', strings)

    if not strings: return ''

    # Find initial whitespace chunk in the first line.
    # This is the best prefix we can hope for.
    prefix = re.match(r'\s*', strings[0]).group(0)

    # Loop over the other strings, keeping only as much of
    # the prefix as matches each string.
    for s in strings:
        for i in range(len(prefix)):
            if prefix[i] != s[i]:
                prefix = prefix[:i]
                break
    return prefix

def reindentBlock(lines, newIndent=''):
    """ Take a block of text as a string or list of lines.
        Remove any common whitespace indentation.
        Re-indent using newIndent, and return it as a single string.
    """
    if type(lines) == type(""):
        lines = split(lines, '\n')
    oldIndent = whitePrefix(lines)
    outLines = []
    for l in lines:
        if oldIndent:
            l = replace(l, oldIndent, '', 1)
        if l and newIndent:
            l = newIndent + l
        outLines.append(l)
    return join(outLines, '\n')

def commonPrefix(strings):
    """ Find the longest string that is a prefix of all the strings.
    """
    if not strings:
        return ''
    prefix = strings[0]
    for s in strings:
        if len(s) < len(prefix):
            prefix = prefix[:len(s)]
        if not prefix:
            return ''
        for i in range(len(prefix)):
            if prefix[i] != s[i]:
                prefix = prefix[:i]
                break
    return prefix
