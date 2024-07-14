import cloths

import ../arguments
import ../functions

import types/json

import submodules/wordropes
import submodules/semanticstrings
import config

import std/options
import std/strformat
import std/strutils
import std/sequtils

type
  BuiltinClassMethodEntry* = ref object of GodotProc
    containerKey: ContainerKey

proc extract_result(self: JsonBuiltinClassMethod): RenderableResult =
  convertToResult self.return_type

proc specify(arg: RenderableArgument): RenderableArgument =
  if arg.typeSym == TypeSym"Object":
    arg.typeSym = TypeSym.GodotClass
  arg

proc specify(arg: RenderableResult): RenderableResult =
  if arg.typeSym == TypeSym"Object":
    arg.typeSym = TypeSym.GodotClass
  arg

proc extract_args(self: JsonBuiltinClassMethod): seq[RenderableArgument] =
  result = self.arguments.get(@[])
    .mapIt(specify convert it)
  if self.is_vararg:
    result.add specify RenderableArgument(
      variableSym: VariableSym"args",
      info: ParamInfo(isVarargs: true),
      typeSym: TypeSym.Variant,
      default_value: none string)

proc convert*(json: JsonBuiltinClassMethod; self_type: RenderableSelfArgument): BuiltinClassMethodEntry =
  result = BuiltinClassMethodEntry(
    kind: pkProc,
    name: json.name.scan.convert(ProcSym),
    self: self_type,
    args: json.extract_args(),
    result: specify json.extract_result(),

    native_name: json.name,
    hash: some json.hash,
  )
  result.containerKey = gen_containerKey result
  # TODO: Support varargs
  if json.is_vararg:
    result.pragmas.list.add "error"

proc weave_container*(entry: BuiltinClassMethodEntry): Cloth =
  &"var {entry.containerKey}: PtrBuiltinMethod"

proc weave_loadstmt*(entry: BuiltinClassMethodEntry): Cloth =
  weave multiline:
    &"proc_name = stringName \"{entry.native_name}\""
    &"{entry.containerKey} = interface_Variant_getPtrBuiltinMethod({variantType entry.self.typesym}, addr proc_name, {get entry.hash})"

proc weave_procdef*(entry: BuiltinClassMethodEntry): Cloth =
  if "error" in entry.pragmas.list:
    return

  let p_self = case entry.self.isStatic
  of false: &"addr {entry.self.name}"
  of true: "nil"
  let p_args =
    if entry.args.len == 0: "nil"
    else: "addr argArr[0]"
  let p_result =
    if entry.result.typeSym == TypeSym.Void: "nil"
    else: "addr result"

  weave multiline:
    weave ProcKey entry
    weave cloths.indent:
      if entry.args.len != 0:
        &"let argArr = [" & entry.args.mapIt(&"getPtr {it.name}").join(", ") & "]"
      &"{entry.containerKey}({p_self}, {p_args}, {p_result}, {entry.args.len})"

proc weave_methods*(json: JsonBuiltinClass): Cloth =
  let typesym = json.name.scan.convert(TypeSym)
  let ignore = getignore(typeSym)

  let methods = json.methods.get(@[])
    .mapIt(it.convert(RenderableSelfArgument(
      typeSym: typeSym,
      info: ParamInfo(
        ismutable: not it.is_const
      ),
      isStatic: it.isStatic,
      )))
    .filterIt((not ignore.procedure) or it.containerKey in ignore.procedure_white)

  weave margin:
    if methods.len != 0:
      weave multiline:
        for entry in methods:
          weave_container entry

      weave multiline:
        for entry in methods:
          weave_procdef entry

      weave multiline:
        &"process eventindex.init_engine.on_load_builtinclassMethod:"
        weave cloths.indent:
          "var proc_name: StringName"
          for entry in methods:
            weave_loadstmt entry