# Demo file showing how to use enhanced error reporting in the compiler
# This demonstrates the new Rust-style error messages with notes and help

import compiler/[msgs, lineinfos, options, idents]

# Example: How to emit a structured diagnostic with notes and help
proc exampleStructuredError*(conf: ConfigRef; info: TLineInfo) =
  var diag = TStructuredDiagnostic(
    msg: errGenerated,
    info: info,
    arg: "type mismatch: expected 'int' but got 'string'"
  )

  # Add a note for additional context
  diag.notes.add TDiagnosticNote(
    info: unknownLineInfo,
    message: "integers and strings cannot be implicitly converted"
  )

  # Add help suggesting a fix
  diag.help.add TDiagnosticHelp(
    message: "consider using '$' to convert the string to int, or change the type"
  )

  conf.emitStructuredDiagnostic(diag, doNothing)

# Example: How to add a simple note to an existing error
proc exampleSimpleNote*(conf: ConfigRef; info: TLineInfo) =
  # First emit the main error
  conf.localError(info, "cannot call proc with these arguments")

  # Then add a note with additional context
  conf.addDiagnosticNote(unknownLineInfo, "proc expects 2 arguments but 3 were provided")

  # Add a help message
  conf.addDiagnosticHelp("check the proc signature to see required parameter types")
