import ./sdk
import VirtualFile

import cloths
import cloths/styles/algorithm

import std/macros
import std/hashes
import std/sets
import std/os
import std/tables

type
  Flag* = enum
    Dummy
  MetaData* = object
    enableWarning: tuple[
      unusedImport: bool
    ]
    flags: set[Flag]
  NimSource* = ref object of VirtualFile
    metadata*: MetaData
    moduleName*: string
    imports: HashSet[NimSource]
    exports: HashSet[NimSource]
    pContents: Cloth

proc hash*(source: NimSource): Hash = hash cast[uint64](source)

proc nim*(moduleName: string): NimSource =
  NimSource(
    moduleName: moduleName,
    pContents: cloth multiline,
  )

proc dummy*(source: NimSource): NimSource =
  source.metadata.flags.incl Dummy
  source

proc `import`*(source: NimSource; targets: varargs[NimSource]): NimSource =
  for target in targets:
    source.imports.incl target
  source

proc `export`*(source: NimSource; targets: varargs[NimSource]): NimSource =
  for target in targets:
    source.exports.incl target
  source

proc makeImportSentence(caller, target: NimSource; importMode, exportMode: bool): Cloth =
  let path = target.relativePath(caller.parent).changeFileExt("")
  if not importMode:
    cloth empty
  elif not exportMode:
    "import " & path
  else:
    "import " & path & "; export " & path.extractFileName

proc weave_imports(source: NimSource): Cloth =
  weave Sort.sort:
    for target in source.imports:
      source.makeImportSentence(target, true, target in source.exports)

macro weave*(source: NimSource; body): NimSource =
  let src = gensym(nskLet, "src")
  quote do:
    let `src`: NimSource = `source`
    weave(`src`.pContents, `body`)
    `src`

method name(source: NimSource): string = source.modulename
method ext(source: NimSource): string = ".nim"
method contents(source: NimSource): Cloth = weave Margin(thickness: 1):
  if Dummy notin source.metadata.flags:
    if not source.metadata.enableWarning.unusedImport:
      "{.warning[UnusedImport]:off.}"
    weave_imports source
    source.pContents


proc collectSources(source: NimSource): seq[NimSource] =
  for subitem in source.subitems.values:
    if subitem of NimSource:
      result.add NimSource subitem

method generate(source: NimSource) =
  if source.subitems.len != 0:
    if not source.path.dirExists:
      createDir source.path
    for subitem in source.subitems.values:
      generate subitem

    for subsource in collectSources source:
      discard source
        .import(subsource)
        .export(subsource)

  procCall generate VirtualFile source

method dumpTree(source: NimSource): Cloth =
  weave multiline:
    if source.subitems.len == 0:
      source.name & source.ext
    else:
      source.name & source.ext & "/"
      weave Tree():
        for key, subitem in source.subitems:
          dumpTree subitem