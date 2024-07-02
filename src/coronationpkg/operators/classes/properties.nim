import cloths
import ../classindex

import submodules/wordropes
import submodules/semanticstrings

import std/options
import std/strformat

proc weave_properties*(class: Class): Cloth =
  weave Margin(thickness: 1):
    for prop in class.json.properties.get(@[]):
      weave multiline:
        let index_get = (if prop.index.isSome: $prop.index.get else: "")
        let index_set = (if prop.index.isSome: $prop.index.get & ", " else: "")
        let name = prop.name.scan.convert(ProcSym)
        let retT = prop.`type`.scan.convert(TypeSym)
        &"template {name}*(self: {class.typesym}): {retT} = self.{prop.getter.scan.convert(ProcSym)}({index_get})"
        if prop.setter.isSome:
          &"template `{name}=`*(self: {class.typesym}; value) = self.{prop.setter.get.scan.convert(ProcSym)}({index_set}value)"
