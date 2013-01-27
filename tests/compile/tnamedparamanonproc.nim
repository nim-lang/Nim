
type
  PButton = ref object
  TButtonClicked = proc(button: PButton) {.nimcall.}

proc newButton*(onClick: TButtonClicked) =
  nil
  
proc main() =
  newButton(onClick = proc(b: PButton) =
    var requestomat = 12
    )

main()
