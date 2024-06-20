import std/strutils
import std/strformat
import std/options

import cloths
import submodules/wordropes
import submodules/semanticstrings

import types/json

import config

type Subscription = enum
  Never
  Optimize
  Indexing
  Keying

proc subscription(json: JsonBuiltinClass; typename: TypeSym): Subscription =
  let ignore = getignore(typename)
  if json.indexing_return_type.isNone or ignore.subscript: Never
  elif json.is_keyed: Keying
  elif "Packed" in $typename: Optimize
  else: Indexing

proc item(sym: TypeSym): TypeSym =
  case sym
  of TypeSym"PackedByteArray"    : TypeSym"byte"
  of TypeSym"PackedColorArray"   : TypeSym"Color"
  of TypeSym"PackedFloat32Array" : TypeSym"float32"
  of TypeSym"PackedFloat64Array" : TypeSym"float64"
  of TypeSym"PackedInt32Array"   : TypeSym"int32"
  of TypeSym"PackedInt64Array"   : TypeSym"int64"
  of TypeSym"PackedStringArray"  : TypeSym"String"
  of TypeSym"PackedVector2Array" : TypeSym"Vector2"
  of TypeSym"PackedVector3Array" : TypeSym"Vector3"
  of TypeSym"String"             : TypeSym"Rune"
  of TypeSym"Array"              : TypeSym"Variant"
  of TypeSym"Dictionary"         : TypeSym"Variant"
  else: TypeSym"void"

proc weave_subscript*(json: JsonBuiltinClass): Cloth =
  let typename = json.name.scan.convert(TypeSym)
  case json.subscription(typename)
  of Never: return
  of Optimize:
    weave multiline:
      &"proc `[]`*(self: {typename}; index: int): {typename.item} = self.data_unsafe[index]"
      &"proc `[]`*(self: var {typename}; index: int): var {typename.item} = self.data_unsafe[index]"
      &"proc `[]=`*(self: var {typename}; index: int; value: {typename.item}) = self.data_unsafe[index] = value"
  of Indexing:
    weave multiline:
      &"proc `[]`*(self: {typename}; index: int): {typename.item} = cast[ptr {typename.item}](interface_{typename}_operatorIndexConst(addr self, index))[]"
      &"proc `[]`*(self: var {typename}; index: int): var {typename.item} = cast[ptr {typename.item}](interface_{typename}_operatorIndex(addr self, index))[]"
      &"proc `[]=`*(self: var {typename}; index: int; value: {typename.item}) = cast[ptr {typename.item}](interface_{typename}_operatorIndex(addr self, index))[] = value"
  of Keying:
    weave multiline:
      &"proc `[]`*(self: {typename}; key: Variant): {typename.item} = cast[ptr {typename.item}](interface_{typename}_operatorIndexConst(addr self, addr key))[]"
      &"proc `[]`*(self: var {typename}; key: Variant): var {typename.item} = cast[ptr {typename.item}](interface_{typename}_operatorIndex(addr self, addr key))[]"
      &"proc `[]=`*(self: var {typename}; key: Variant; value: {typename.item}) = cast[ptr {typename.item}](interface_{typename}_operatorIndex(addr self, addr key))[] = value"
