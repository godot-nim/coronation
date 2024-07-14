import cloths
import cloths/styles/exception

import submodules/wordropes
import submodules/semanticstrings

import types/json

import ../arguments
import ../functions

import std/sequtils
import std/options
import std/strformat
import std/tables

import config

type
  BuiltinClassOperator* = ref object
    key: ProcKey
    opkey: string
    vt_first, vt_second: VariantType
    addr_first, addr_second: string

    containerKey: ContainerKey

func operator(basename: string): ProcSym =
  ProcSym:
    case basename
    of "in": "contains"
    of "unary+": "`+`"
    of "unary-": "`-`"
    else: "`" & basename & "`"

const EscapeSign = toTable {
  "==": "Equal",
  "!=": "NotEqual",
  "<": "Less",
  "<=": "LessEqual", ">": "Greater",
  ">=": "GreaterEqual",
  "+": "Add",
  "-": "Subtract",
  "*": "Multiply",
  "/": "Divide",
  "**": "Power",
  "unary-": "Negate",
  "unary+": "Positive",
  "%": "Module",
  "<<": "ShiftLeft",
  ">>": "ShiftRight",
  "&": "BitAnd",
  "|": "BitOr",
  "^": "BitXor",
  "~": "BitNegate",
  "and": "And",
  "or": "Or",
  "xor": "Xor",
  "not": "Not",
  "and": "And",
  "in": "In" }

func variantOPKey(sign: string): string =
  "VariantOP_" & EscapeSign[sign]

proc specify(arg: RenderableArgument): RenderableArgument =
  if arg.typesym == TypeSym"Object":
    arg.typesym = TypeSym.GodotClass
  arg

proc convert*(operator: JsonOperator; caller: TypeSym): BuiltinClassOperator =
  new result
  new result.key
  result.key.name = operator operator.name
  result.key.args.add specify RenderableArgument(
    variableSym: VariableSym"left",
    typeSym: caller)

  if operator.right_type.isSome:
    result.key.args.add specify RenderableArgument(
      variableSym: VariableSym"right",
      typeSym: operator.right_type.get.scan.convert(TypeSym))
  result.key.result = convertToResult some operator.return_type

  result.opkey = variantOpKey operator.name

  result.vt_first = variantType result.key.args[0].typeSym
  result.vt_second = variantType:
    if result.key.args.len == 1: TypeSym.Void
    else: result.key.args[1].typeSym

  result.containerKey = gen_containerKey result.key

  if result.key.name == operator"in":
    swap(result.key.args[0].typeSym, result.key.args[1].typeSym)

  result.addr_first = &"getPtr {result.key.args[0].name}"
  result.addr_second =
    if result.key.args.len == 1: "nil"
    else: &"getPtr {result.key.args[1].name}"

  if result.key.name == operator"in":
    # bool in(Left left, Right right) {Godot::in(&left, &right)}
    # <->
    # proc contains(left: Right; right: Left): bool = Godot::in(addr right, addr left)
    # and then, call it using template: `Left in Right`
    swap(result.addr_first, result.addr_second)


proc weave_container(operator: BuiltinClassOperator): Cloth =
  &"var {operator.containerkey}: PtrOperatorEvaluator"

proc weave_procdef(operator: BuiltinClassOperator): Cloth =
  &"{weave operator.key} {operator.containerkey}({operator.addr_first}, {operator.addr_second}, addr result)"

proc weave_loadstmt(operator: BuiltinClassOperator): Cloth =
  &"{operator.containerkey} = interface_variantGetPtrOperatorEvaluator({operator.opkey}, {operator.vt_first}, {operator.vt_second})"

proc weave_operators*(json: JsonBuiltinClass): Cloth =
  let typesym = json.name.scan.convert(TypeSym)
  let ignore = getignore(typesym)
  if ignore.operator and ignore.operator_white.len == 0: return

  let operators = json.operators.get(@[]).mapIt(it.convert(typesym))

  weave multiline:
    weave multiline:
      for op in operators:
        if ignore.operator:
          if op.containerkey in ignore.operator_white:
            weave_container op
        else:
          weave_container op
    weave multiline:
      for op in operators:
        if ignore.operator:
          if op.containerkey in ignore.operator_white:
            weave_procdef op
        else:
          weave_procdef op

    weave transact:
      &"process eventindex.init_engine.on_load_builtinclassOperator:"
      weave Proof(elements: 1) & cloths.indent:
        for op in operators:
          if ignore.operator:
            if op.containerkey in ignore.operator_white:
              weave_loadstmt op
          else:
            weave_loadstmt op