import submodules/wordropes

import std/hashes
import std/strutils

type VariableSym* = distinct string
proc `$`*(a: VariableSym): string {.borrow.}
proc `==`*(a, b: VariableSym): bool {.borrow.}
proc hash*(a: VariableSym): Hash {.borrow.}

type TypeSym* = distinct string
proc `$`*(a: TypeSym): string {.borrow.}
proc `==`*(a, b: TypeSym): bool {.borrow.}
proc hash*(a: TypeSym): Hash {.borrow.}

proc typefy*(sym: VariableSym): TypeSym =
  TypeSym capitalizeAscii string sym

proc variablefy*(sym: TypeSym): VariableSym =
  VariableSym (string sym)[0].toLowerAscii & (string sym)[1..^1]

template Void*(_: typedesc[TypeSym]): TypeSym = TypeSym"void"
template Variant*(_: typedesc[TypeSym]): TypeSym = TypeSym"Variant"
template GodotClass*(_: typedesc[TypeSym]): TypeSym = TypeSym"GodotClass"

type ProcSym* = distinct string
proc `$`*(a: ProcSym): string {.borrow.}
proc `==`*(a, b: ProcSym): bool {.borrow.}
proc hash*(a: ProcSym): Hash {.borrow.}

type VariantType* = distinct string
proc `$`*(typekey: VariantType): string = string typekey
proc `==`*(a, b: VariantType): bool {.borrow.}
proc hash*(a: VariantType): Hash {.borrow.}

func variantType*(typesym: TypeSym): VariantType =
  VariantType:
    if typesym in [TypeSym.Variant, TypeSym.Void]:
      "VariantType_Nil"
    elif typesym in [TypeSym.GodotClass]:
      "VariantType_Object"
    else:
      "VariantType_" & $typesym

type ContainerKey* = distinct string
proc `$`*(containerkey: ContainerKey): string = string containerkey
proc `==`*(a, b: ContainerKey): bool {.borrow.}
proc hash*(a: ContainerKey): Hash {.borrow.}


proc erase(str: string; target: string): string {.inline.} = str.replace(target, "")
proc quoted*(w: string): string = "`" & w.erase("`") & "`"

const keywords* = [
  "addr", "and", "as", "asm", "bind", "block", "break", "case", "cast", "concept",
  "const", "continue", "converter", "defer", "discard", "distinct", "div", "do",
  "elif", "else", "end", "enum", "except", "export", "finally", "for", "from",
  "func", "if", "import", "in", "include", "interface", "is", "isnot", "iterator",
  "let", "macro", "method", "mixin", "mod", "nil", "not", "notin", "object", "of",
  "or", "out", "proc", "ptr", "raise", "ref", "return", "shl", "shr", "static",
  "template", "try", "tuple", "type", "using", "var", "when", "while", "xor", "yield",
]
proc escapeVariable*(w: string): string =
  if w in keywords:
    result = quoted w
  else:
    result = w
    for c in w:
      if c notin 'a'..'z' and c notin 'A'..'Z' and c notin '0'..'9':
        result = quoted w
        break

proc convert*(ss: WordRope; _: typedesc[TypeSym]): TypeSym =
  var str = newStringOfCap(ss.total)
  for i, w in ss.words:
    case string(w)
    of "t": discard
    of ".": str.add "_"
    of "double": str.add "float64"
    else: str.add w.pascal
  str = case str
  of "Bool": "bool"
  of "Void": "void"
  of "Pointer": "pointer"
  of "Int8", "Int16", "Int32", "Int64": str.replace("Int", "int")
  of "Uint8", "Uint16", "Uint32", "Uint64": str.replace("Uint", "uint")
  of "Float32", "Float64": str.replace("Float", "float")
  of "Thread": "GodotThread" # will conflicts to system.Thread
  else: str
  TypeSym str

proc convert*(ss: WordRope; _: typedesc[VariableSym]): VariableSym =
  var str = newStringOfCap(ss.total)
  for i, w in ss.words:
    str.add:
      if i == 0: w.snake
      else:      w.pascal
  VariableSym escapeVariable str

proc convert*(ss: WordRope; _: typedesc[ProcSym]): ProcSym =
  var str = newStringOfCap(ss.total)
  let words =
  #   if ss.words[0].string == "set" and ss.words.len > 1: concat(ss.words[1..^1], @[LowerString"="])
  #   else: ss.words
    ss.words
  for i, w in words:
    str.add:
      if i == 0: w.snake
      else:      w.pascal
  ProcSym escapeVariable str


when isMainModule:
  echo scan("set_getter").convert(ProcSym)
  echo repr scan("Object.int64_t")
  echo scan("Object.int64_t").convert(TypeSym)