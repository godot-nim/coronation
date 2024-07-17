import cloths

import config

import types/json

import submodules/filesystem/sdk
import submodules/filesystem/[
  ProjectRoot,
  Directory,
  NimSource,
  Textfile,
]
import submodules/wordropes
import submodules/semanticstrings

import operators/enums
import operators/structs
import operators/constants
import operators/utilityfuncs
import operators/builtinclasses/constructors
import operators/builtinclasses/subscripts
import operators/builtinclasses/operators
import operators/builtinclasses/methods
import operators/classindex
import operators/classes/methods
import operators/classes/properties
import operators/classes/vmap
import operators/classes/signals

import std/sequtils
import std/strformat
import std/options
import std/tables
import std/os

proc version*(header: JsonHeader): string =
  &"{header.version_major}.{header.version_minor}.{header.version_patch}"

discard layout "godotcore/coronation".root:
  layout "builtinclasses".dir:
    let corona_constructors = dummy "constructors".nim
  let corona_builtinclasses = dummy "builtinclasses".nim
  let corona_structs = dummy "structs".nim
  let corona_classindex = dummy "classindex".nim
  let corona_classes = dummy "classes".nim
  let corona_utilityfuncs = dummy "utilityfuncs".nim
discard layout "godotcore/tune".root:
  layout "builtinclasses".dir:
    let tune_constructors = dummy "constructors".nim
  let tune_builtinclasses = dummy "builtinclasses".nim


proc project(config: BuildConfig; api: JsonAPI): ProjectRoot =
  # Note: What does this section do?
  # these are macros:
  #   `generate`: see filesystem/sdk
  #   `layout`: see filesystem/sdk
  #   `weave *.nim`: see filesystem/NimSource
  #   other `weave`: see cloths(external library)/sdk
  # Make virtual file/directory with `dir`, `nim`, `nims` and `.nimble`.
  # Define hierarchy structure of these with `layout`.
  # Describe file contents with `weave`.
  # Apply above definitions physical with `generate`.
  layout (config.outdir/config.package).root:
    layout "src".dir:
      layout config.package.dir:
        # [Global Enums]
        "globalenums".nim
        let globalenums = weave "globalenums".nim:
          weave margin:
            for globalenum in api.global_enums:
              weave with_registerDB globalenum.convert

        # [Local Enums]
        let localenums = weave "localenums".nim:
          weave margin:
            for builtin in api.builtin_classes:
              let sym = builtin.name.scan.convert(TypeSym)
              for localenum in builtin.enums.get(@[]):
                weave with_registerDB localenum.convert(sym)
            for class in api.classes:
              let sym = class.name.scan.convert(TypeSym)
              for localenum in class.enums.get(@[]):
                weave with_registerDB localenum.convert(sym)

        # [Native Structures]
        weave "structs".nim
            .import(corona_structs)
            .import(localenums):
          weave margin:
            for struct in api.native_structures:
              weave struct.convert

        # [Utility Functions]
        weave "utilityfuncs".nim
            .import(corona_utilityfuncs):
          let utilfuncs = api.utility_functions.mapIt(convert it)
          weave margin:
            weave multiline:
              for utilfunc in utilfuncs:
                weave_container utilfunc
            for utilfunc in utilfuncs:
              weave_procdef utilfunc
            weave multiline:
              "proc load* ="
              weave indent:
                "var proc_name: StringName"
                for utilfunc in utilfuncs:
                  weave_loadstmt utilfunc

        # [Builtin Classes]
        layout "builtinclasses".nim
            .import(tune_builtinclasses)
            .export(tune_builtinclasses):
          let bc_constructors = weave "constructors".nim
              .import(corona_constructors)
              .import(tune_constructors).export(tune_constructors):
            weave margin:
              for builtin in api.builtin_classes:
                weave_constructor builtin

          for builtin in api.builtin_classes:
            let sym = builtin.name.scan.convert(TypeSym)
            if not getignore(sym).module:
              weave ($sym.convert(ModuleSym)).nim
                  .import(corona_builtinclasses)
                  .import(bc_constructors):
                weave margin:
                  weave margin:
                    if builtin.constants.isSome:
                      "# constant values"
                    for constant in builtin.constants.get(@[]):
                      constant.weave(sym)
                  weave_subscript builtin
                  weave_operators builtin
                  weave_methods builtin

        let classindex = weave "classindex".nim
            .import(corona_classindex):
          weave margin:
            for base, sym in inheritanceDB.hierarchical:
              weave_index classDB[sym]

        # layout "classes".nim:
        layout "classes".dir:
          for base, sym in inheritanceDB.hierarchical:
            let class = classDB[sym]
            weave ($sym.convert(ModuleSym)).nim
                .import(corona_classes)
                .import(globalenums, localenums, bc_constructors, classindex):
              weave margin:
                if base != TypeSym"GodotClass":
                  let mdlbase = base.convert(ModuleSym)
                  &"import {mdlbase}; export {mdlbase}"
                weave margin:
                  for entry in class.json.methods.get(@[]):
                    weave entry.convert(sym)
                weave_properties class
                weave_vmap(class)
                weave_signals(class)

    weave config.package.nimble: &"""
# Package

version       = "{api.header.version}"
author        = "coronation written by godot-nim, la.panon."
description   = "A GDExtension binding"
license       = "MIT"
srcDir        = "src"


# Dependencies

requires "nim >= 2.0.0"

# if missing, please install from https://github.com/godot-nim/godotcore
requires "godotcore >= 0.1.0"
"""


proc run*(api: JsonAPI; config: BuildConfig) =

  for class in api.classes:
    registerDB class.convert

  let project = project(config, api)

  echo:
    weave Prefix(prefix: "Dump: "):
      dumptree project
  generate project
