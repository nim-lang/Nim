discard """
joinable: false # for clarity, but not necessary
"""

{.warning[UnusedImport]: off.}
# only import `mt*.nim` here; these depend on `m*.nim`
import "."/[mt0,mt1,mt2,mt3,mt4,mt4b,mt5,mt6,mt7,mt8,mt9]
