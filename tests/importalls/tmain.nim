{.warning[UnusedImport]: off.}
# only import `mt*.nim` here; these depend on `m*.nim`
# import "."/[mt0,mt1,mt2,mt3,mt4,mt4b,mt5,mt6,mt7,mt8,mt9]
# BUG: mt1,mt2,
# import "."/[mt0,mt3,mt4,mt4b,mt5,mt6,mt7,mt8,mt9]
import "."/[mt2]
