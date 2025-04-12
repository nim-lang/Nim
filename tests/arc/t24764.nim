discard """
  matrix: "--mm:arc"
"""

import m24764

type QWidget* = object of QObject
proc `=copy`(dest: var QWidget, source: QWidget) {.error.}
proc `=sink`(dest: var QWidget, source: QWidget) =
  `=sink`(QObject(dest), QObject(source))

proc show(v: QWidget) = discard

proc main() =
  let btn = QWidget()

  let tmp = proc() =
    btn.show()

  btn.show()

main()