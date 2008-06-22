============================
Nimrod's documenation system
============================

This folder contains Nimrod's documentation. The documentation
is written in a format called *reStructuredText*, a markup language that reads
like ASCII and can be converted to HTML, Tex and other formats automatically!

Unfortunately reStructuredText does not allow to colorize source code in the
HTML page. Therefore a postprocessor runs over the generated HTML code, looking
for Nimrod code fragments and colorizing them.
