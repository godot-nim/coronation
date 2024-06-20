import cloths

import submodules/semanticstrings

import ./arguments

import utils

import std/options
import std/strformat
import std/strutils

type
  ProcKind* = enum
    pkProc = "proc"
    pkFunc = "func"
    pkMethod = "method"
    pkConverter = "converter"
    pkTemplate = "template"
    pkMacro = "macro"
  ProcKey* = ref object of RootObj
    kind*: ProcKind = pkProc
    name*: ProcSym
    exportme*: bool = true
    self*: RenderableSelfArgument
    args*: seq[RenderableArgument]
    result*: RenderableResult
    pragmas*: Pragmas
  GodotProc* = ref object of ProcKey
    native_name*: string
    hash*: Option[int]

proc weave*(procKey: ProcKey): Cloth =
  var head = &"{procKey.kind} {procKey.name}"
  if procKey.exportme:
    head &= "*"
  head &= "("
  head.add:
    `$`: weave Join(delim: "; "):
      if procKey.self != nil:
        weave procKey.self
      for arg in procKey.args:
        weave arg
  head &= "): " & $weave procKey.result

  if procKey.pragmas.list.len != 0:
    head &= " " & $procKey.pragmas

  head &= " ="
  return head

proc gen_containerKey*(prockey: ProcKey): ContainerKey =
  ## FORMAT: SELFTYPE_PROCNAME(_ARGS..)
  ## ARGS will be expanded only when the SELFTYPE is none
  var text: string
  if prockey.self != nil:
    text.add $prockey.self.typesym
    text.add " "
  text.add ($prockey.name).replace("`", "")
  if prockey.self == nil:
    for arg in prockey.args:
      if arg.typesym in [TypeSym.Void]: continue
      text.add " "
      text.add $arg.typesym
  ContainerKey "`" & text & "`"
