""" Indentation utilities for Cog.
    http://nedbatchelder.com/code/cog
    
    Copyright 2004-2005, Ned Batchelder.
"""

# $Id: whiteutils.py 110 2005-08-27 22:35:20Z ned $

import re, types

def whitePrefix(strings):
    """ Determine the whitespace prefix common to all non-blank lines
        in the argument list.
    """
    # Remove all blank lines from the list
    strings = filter(lambda s: s.strip() != '', strings)
    
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
    if isinstance(lines, types.StringTypes):
        lines = lines.split('\n')
    oldIndent = whitePrefix(lines)
    outLines = []
    for l in lines:
        if oldIndent:
            l = l.replace(oldIndent, '', 1)
        if l and newIndent:
            l = newIndent + l
        outLines.append(l)
    return '\n'.join(outLines)

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
