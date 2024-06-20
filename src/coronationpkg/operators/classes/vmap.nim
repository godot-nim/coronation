import cloths

import types/json
import ../classindex
import submodules/wordropes
import submodules/semanticstrings

import std/options
import std/sequtils
import std/strformat

proc weave_vmap*(class: Class): Cloth = weave multiline:
  let vmethods = class.json.methods.get(@[]).filterIt(it.isVirtual)
  &"let {class.typesym}_vmap* ="
  if vmethods.len == 0:
    "  initTable[string, string]()"
  else:
    if class.inherits == TypeSym"GodotClass":
      "  toTable {"
    else:
      &"  {class.inherits}_vmap.concat" & " toTable {"
    weave indent(4):
      for entry in vmethods:
        "\"" & $entry.name.scan.convert(ProcSym) & "\" : \"" & $entry.name & "\","
      "}"
  &"template vmap*(_: typedesc[{class.typesym}]): Table[string, string] = {class.typesym}_vmap"
