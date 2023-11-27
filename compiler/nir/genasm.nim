# generates Asm stategments like this:
# Asm {
#   AsmTemplate {
#     Some asm code
#     SymUse nimInlineVar # `a`
#     Some asm code
#   }
#   AsmOutputOperand {
#     # [asmSymbolicName] constraint (nimVariableName)
#     AsmInjectExpr {symUse nimVariableName} # for output it have only one sym (lvalue)
#     asmSymbolicName # default: ""
#     constraint
#   }
#   AsmInputOperand {
#     # [asmSymbolicName] constraint (nimExpr)
#     AsmInjectExpr {symUse nimVariableName} # (rvalue)
#     asmSymbolicName # default: ""
#     constraint
# }
#  AsmClobber {
#    "clobber"
# }

# it can be useful for better asm analysis and 
# easy to use in all nim targets

type
  Det = enum
    AsmTemplate
    SymbolicName
    InjectExpr
    Constraint
    Clobber
    Delimiter
  
  AsmValKind = enum
    StrVal
    SymVal
    NodeVal
    EmptyVal

  AsmVal = object
    case kind: AsmValKind
    of StrVal:
      s: string
    of SymVal:
      sym: SymId
    of NodeVal:
      n: PNode
    of EmptyVal:
      discard

  ParsedAsmChunk = tuple[sec: int, val: AsmVal, det: Det]
  ParsedAsm = seq[ParsedAsmChunk]

const
  asmSections = [
    Opcode.AsmTemplate,
    AsmOutputOperand,
    AsmInputOperand, 
    AsmClobber
  ]

template createSectionItem: untyped =
  prepare(c.code, info, asmSections[sec])

template closeItem: untyped =
  patch(c.code, pos)

proc toVal(n: PNode): AsmVal =
  AsmVal(kind: NodeVal, n: n)

proc toVal(s: string): AsmVal =
  AsmVal(kind: StrVal, s: s)

proc toVal(s: SymId): AsmVal =
  AsmVal(kind: SymVal, sym: s)

proc empty(): AsmVal =
  AsmVal(kind: EmptyVal)

# proc toVal()

iterator parseAsm(c: var ProcCon, n: PNode): ParsedAsmChunk =
  template addCaptured: untyped =
    yield (
      sec, 
      captured.toVal, 
      det
    )
    captured = ""
  
  template maybeAddCaptured: untyped =
    if captured != "":
      addCaptured()
  
  var sec = 0
  var det: Det = AsmTemplate
  var left = 0
  var captured = ""
  
  # handling comments
  var
    inComment = false # current char in comment(note: comment chars is skipped)
    isLineComment = false
    foundCommentStartSym = false
    foundCommentEndSym = false

  for it in n.sons:
    case it.kind
      of nkStrLit..nkTripleStrLit:
        let s = it.strVal

        for i in 0..s.high:

          # Comments
          if sec > 0 and foundCommentStartSym:
            # "/?"
            if s[i] == '/':
              # "//"
              inComment = true
              isLineComment = true
            elif s[i] == '*':
              # "/*"
              inComment = true
              isLineComment = false
            foundCommentStartSym = false # updates it
          
          if sec > 0 and not foundCommentStartSym and s[i] == '*':
            #"(!/)*"
            foundCommentEndSym = true
          elif sec > 0 and foundCommentEndSym: # "*?"
            if s[i] == '/': # "*/"
              inComment = false
              # delete captured '/'
              captured = ""
              continue
            foundCommentEndSym = false
          if sec > 0 and s[i] == '/': # '/'
            foundCommentStartSym = true
          if sec > 0 and s[i] == '\n' and inComment:
            if not isLineComment: # /* comment \n
              raiseAssert """expected "*/", not "*""" & s[i] & """" in asm operand"""
            inComment = false
            # delete captured '/'
            captured = ""
            continue
          if inComment:
            # skip commented syms
            continue



          case s[i]:
            of ':':
              if sec == 0: # det == AsmTemplate
                yield (
                  sec, 
                  s[left..i - 1].toVal, 
                  det
                )
              
              inc sec
              # inc det
              left = i + 1
              captured = ""

              if sec in 1..2:
                # default det for operands
                det = Constraint
              elif sec == 3:
                det = Clobber

            of '[':
              # start of asm symbolic name
              det = SymbolicName
            
            of ']':
              if det != SymbolicName:
                raiseAssert "expected: ']'"
              
              addCaptured()

              det = Constraint
              # s[capturedStart .. i - 1]
            
            of '(':
              addCaptured() # add asm constraint
              det = InjectExpr
            
            of ')':
              if det != InjectExpr:
                raiseAssert "expected: ')'"
              
              maybeAddCaptured()
            
            elif sec > 0 and s[i] == ',':
              if sec in 1..2:
                det = Constraint
              
              if sec == 3:
                maybeAddCaptured()
              
              yield (
                sec,
                empty(),
                Delimiter
              )

            elif (
              sec > 0 and 
              det in {
                SymbolicName, 
                Constraint, 
                InjectExpr, 
                Clobber
              } and 
              s[i] notin {' ', '\n', '\t'}
            ): captured.add s[i]
            

            else: discard

      else:
        maybeAddCaptured()
        
        yield (
          sec,
          if it.kind == nkSym:
            toSymId(c, it.sym).toVal
          else:
            it.toVal,
          det
        )
        
        left = 0

  if sec == 0:
    # : not specified 
    yield (
      sec, 
      n[^1].strVal.toVal, 
      det
    )
  elif sec > 2:
    maybeAddCaptured()

proc genInlineAsm(c: var ProcCon; n: PNode) =
  template createInstr(sec: int): untyped =
    prepare(c.code, info, asmSections[sec])
  
  template createInstr(instr: Opcode): untyped =
    prepare(c.code, info, instr)
  
  template endInstr: untyped =
    patch(c.code, pos)
  
  template maybeEndOperand(): untyped =
    if inInjectExpr:
      # end of old operand
      endInstr() # AsmInjectExpr node
      c.code.addStrVal c.lit.strings, info, asmSymbolicName
      c.code.addStrVal c.lit.strings, info, constraint

      pos = oldPos

      #default operand info 
      inInjectExpr = false
      asmSymbolicName = ""
      constraint = ""

  let info = toLineInfo(c, n.info)  
  build c.code, info, Asm:
    var
      pos = createInstr(AsmTemplate)
      oldPos = pos

      oldSec = 0
      # operands
      asmSymbolicName = ""
      constraint = ""
      inInjectExpr = false

    for i in parseAsm(c, n):
      when false:
        echo i
      
      if i.sec != oldSec:
        # new sec
        maybeEndOperand()
        
        endInstr()
        pos = createInstr(i.sec)

      case i.det:
        of AsmTemplate:
          # it's tmp code, template can contains nodes
          c.code.addStrVal c.lit.strings, info, i.val.s
        
        of SymbolicName:
          asmSymbolicName = i.val.s
        of Constraint:
          let s = i.val.s
          if s[0] != '"' or s[^1] != '"':
            raiseAssert "constraint must be started or ended by " & '"'
          constraint = s[1..^2]
        of InjectExpr:
          # (`dst`)
          if not inInjectExpr:
            oldPos = pos
            pos = createInstr(AsmInjectExpr)
          
          case i.val.kind:
            of SymVal:
              c.code.addSymUse info, i.val.sym
            of StrVal:
              c.code.addStrVal c.lit.strings, info, i.val.s
            of NodeVal:
              raiseAssert "unsupported"
            of EmptyVal: raiseAssert "never"

          inInjectExpr = true

        of Delimiter:
          maybeEndOperand()

          endInstr()
          pos = createInstr(i.sec)

        of Clobber:
          let s = i.val.s
          if s[0] != '"' or s[^1] != '"':
            raiseAssert "clobber must be started or ended by " & '"'
          c.code.addStrVal c.lit.strings, info, s[1..^2]
      
      oldSec = i.sec
    
    maybeEndOperand()
    
    endInstr()

proc genGlobalAsm(c: var ProcCon; n: PNode) =
  let info = toLineInfo(c, n.info)  
  build c.code, info, AsmGlobal:
    for i in n:
      case i.kind
        of nkStrLit..nkTripleStrLit:
          c.code.addStrVal c.lit.strings, info, i.strVal
        of nkSym:
          c.code.addSymUse info, toSymId(c, i.sym)
        else:
          gen(c, i)
