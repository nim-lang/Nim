discard """
output: '''14'''
"""

# A module re-exported under two names, `aliased` (mmodaliasas) and
# `mmodaliasbase` (mmodaliasplain), is a qualifier under both names here, where
# both re-exporters are loaded from their NIFs. The loader keeps one module
# symbol per name, not one per module.

import mmodaliasas, mmodaliasplain
echo aliased.baseValue() + mmodaliasbase.baseValue()
