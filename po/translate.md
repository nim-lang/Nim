## Documentation translation

This document describes contributing to translations of Nim's documentation
under `doc/` and the docstrings in the compiler and the standard library.

### Helping with the translation

Create an account on https://hosted.weblate.org/ and find the Nim project

### Managing translation files

The translation system does not depend on the gettext library, however it uses
the .po and .pot formats to leverage existing tools like Weblate.

Template translation files are stored as `po/<name>.pot`

Translation files are stored as `po/<name>.<language>.po`

<language> is usually either an ISO 639 two-letter language code, in lowercase
or <lowercase ISO 639>_<uppercase ISO 3166> e.g. zh_TW

Generate/update template files po/<name>.pot for a single file:

```
nim gentranslation <filename.nim>
```

Note: this command always appends any docstring found to the .pot file

To generate/update template files po/<name>.pot for the whole project:
- delete the .pot file if exists
- run `nim gentranslation <filename>.nim` for all project files


Update existing translation files using content from an updated .pot file
```
msgmerge --previous --update po/<name>.<language>.po po/<name>.pot
```

Generate docs in a language
```
./bin/nim doc2 --language:<language> <filename>.nim
# or
./koch docs --language:<language>
```
