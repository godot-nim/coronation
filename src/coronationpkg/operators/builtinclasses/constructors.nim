import cloths

import ../arguments
import ../functions

import submodules/wordropes
import submodules/semanticstrings
import types/json
import config
import utils

import std/sequtils
import std/strutils
import std/strformat
import std/options

proc specify(arg: RenderableArgument): RenderableArgument =
  if arg.typeSym == TypeSym"Object":
    arg.typeSym = TypeSym.GodotClass
  arg

proc weave*(json: JsonConstructor; typesym: TypeSym): Cloth =
  let entry = ProcKey(
    name: constructorName typesym,
    args: json.arguments.get(@[]).mapIt(specify convert it),
    result: RenderableResult(typesym: typesym),
    kind: pkProc
  )

  weave multiline:
    weave entry
    weave Indent.indent:
      if entry.args.len != 0:
        &"let argArr = [" & entry.args.mapIt(&"getPtr {it.name}").join(", ") & "]"
      let argptr = if entry.args.len == 0: "nil" else: "addr argArr[0]"
      &"{typesym}_constr[{json.index}](addr result, {argptr})"

proc weave_constructor*(self: JsonBuiltinClass): Cloth =
  if self.constructors.len == 0: result
  else:
    let typesym = self.name.scan.convert(TypeSym)
    let ignore = getignore(typesym)

    let idxrange =
      if ignore.constructor:
        ignore.constructor_white
      else:
        (0..self.constructors.high).toSeq

    if idxrange.len == 0: result
    else:
      let idxrange_str = ($idxRange).replace("@", "")
      let constr = &"{typesym}_constr"
      weave Margin(thickness: 1):
        weave multiline:
          &"var {constr}: array[{self.constructors.len}, PtrConstructor]"
          &"process eventindex.init_engine.on_load_builtinclassConstructor:"
          &"  for i in {idxRange_str}:"
          &"    {constr}[i] = interface_Variant_getPtrConstructor(VariantType_{typesym}, int32 i)"
        weave multiline:
          for i in idxrange:
            weave(self.constructors[i], typesym)