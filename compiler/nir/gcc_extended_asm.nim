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
import nirinsts, nirtypes
import std / assertions
import .. / ic / bitabs

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
    # SymVal
    NodeVal
    EmptyVal

  AsmVal = object
    case kind: AsmValKind
    of StrVal:
      s: string
    # of SymVal:
    #   sym: SymId
    of NodeVal:
      n: NodePos
    of EmptyVal:
      discard

  AsmToken = tuple[sec: int, val: AsmVal, det: Det]

  AsmNodeKind* = enum
    AsmTemplate
    AsmOutputOperand
    AsmInputOperand
    AsmClobber

    AsmInjectExpr
    AsmStrVal

  GccAsmNode* = ref object
    case kind: AsmNodeKind
      of AsmTemplate:
        instrs: seq[GccAsmNode]
      of AsmOutputOperand, AsmInputOperand:
        symbolicName: string
        constraint: string
        injectExpr: GccAsmNode
      of AsmClobber:
        clobber: string
      of AsmStrVal:
        s: string
      of AsmInjectExpr:
        n: NodePos


proc toVal(n: NodePos): AsmVal =
  AsmVal(kind: NodeVal, n: n)

proc toVal(s: string): AsmVal =
  AsmVal(kind: StrVal, s: s)

# proc toVal(s: SymId): AsmVal =
#   AsmVal(kind: SymVal, sym: s)

proc empty(): AsmVal =
  AsmVal(kind: EmptyVal)

proc toNode(val: AsmVal): GccAsmNode =
  # get str node or 
  case val.kind:
    of StrVal: GccAsmNode(kind: AsmStrVal, s: val.s)
    of NodeVal: GccAsmNode(kind: AsmInjectExpr, n: val.n)
    else: raiseAssert"unsupported val"

proc emptyNode(kind: AsmNodeKind): GccAsmNode =
  GccAsmNode(kind: kind)

iterator asmTokens(t: Tree, n: NodePos; lit: Literals): AsmToken =
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

  for ch in sons(t, n):
    case t[ch].kind
      of Verbatim:
        let s = ""#it.strVal

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
          ch.toVal,
          det
        )
        
        left = 0

  if sec == 0:
    # : not specified 
    yield (
      sec, 
      lit.strings[t[lastSon(t, n)].litId].toVal, 
      det
    )
  elif sec > 2:
    maybeAddCaptured()

const
  sections = [
    AsmNodeKind.AsmTemplate,
    AsmOutputOperand,
    AsmInputOperand,
    AsmClobber
  ]

iterator parseGccAsm*(t: Tree, n: NodePos; lit: Literals): GccAsmNode =
  var
    oldSec = 0
    curr = emptyNode(AsmTemplate)
    inInjectExpr = false

  template initNextNode: untyped =
    curr = emptyNode(sections[i.sec])

  for i in asmTokens(t, n, lit):
    if i.sec != oldSec:
      # current node fully filled
      yield curr
      initNextNode()

    case i.det:
      of Delimiter:
        yield curr
        initNextNode()

      of AsmTemplate:
        curr.instrs.add i.val.toNode
      
      of SymbolicName:
        curr.symbolicName = i.val.s
      of Constraint:
        let s = i.val.s
        if s[0] != '"' or s[^1] != '"':
          raiseAssert "constraint must be started and ended by " & '"'
        curr.constraint = s[1..^2]
      of InjectExpr:
        # only one inject expr for now
        curr.injectExpr = i.val.toNode

      of Clobber:
        let s = i.val.s
        if s[0] != '"' or s[^1] != '"':
          raiseAssert "clobber must be started and ended by " & '"'
        curr.clobber = s[1..^2]

    oldSec = i.sec
