discard """
output: '''105'''
"""

# Regression test: a converter imported into a module and re-exported from it
# (mconvbase's `toReal` re-exported by mconvmid) must survive NIF serialization
# in the re-exporting module's interface, so a consumer that reaches the
# converter only through that re-export chain can still apply it implicitly.
#
# Before the fix only converters DEFINED in a module were logged for IC
# (`addConverterDef`); converters merely imported/re-exported (`addConverter`
# from `importer.addUnnamedIt`) were not, so under `nim ic` the re-exported
# converter was invisible to importers and `init(Reader, Handle)` failed with a
# type mismatch (the real-world symptom: faststreams `InputStreamHandle ->
# InputStream` dropped, breaking `SSZ.decode`/`encode` in Nimbus).

import mconvmid
echo decode()
