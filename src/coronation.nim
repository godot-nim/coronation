import config
import build

import std/os
import std/osproc
import std/json
import std/strformat
import std/uri
import std/strutils
import std/sequtils

import types/json

const version = staticRead("../coronation.nimble").splitLines
  .filterIt(it.startsWith "version")[0]
  .split('=')[1]
  .strip(chars= {'"', ' '})

proc coronation*(apisource: string; outdir= "out"; package= "gdextgen") =
  ## Description:
  ##   Read API spec from `apisource`, generate godot package named `package` into `outdir`.
  ##
  ## Example:
  ##   coronation --apisorce:extension_api.json --outdir:out/godot410 --package:godot

  var apiuri = apisource.parseuri
  if apiuri.scheme.len == 0:
    apiuri.scheme = "file"
    apiuri.path = expandFilename apiuri.path
  let api = execCmdEx(&"curl -s {apiuri}").output.parsejson.to(JsonAPI)

  build.run api= api, BuildConfig(
    apisource: apisource,
    outdir: outdir,
    package: package,
  )

when isMainModule:
  import cligen
  clCfg.version= version
  coronation.dispatch(
    usage= "$command $args\n\n${doc}\nOptions:\n$options",
    help= {
      "apisource": "Path to extension_api.json output by the engine",
      "outdir": "Directory that the generated package will be placed to",
      "package": "Name of generated package",
    },
  )
