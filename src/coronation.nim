import config
import build

import std/os
import std/osproc
import std/json
import std/strformat
import std/uri

import types/json

const version = gorge("git tag")

proc coronation*(apisource: string; outdir= "out"; package= "gdextgen"; version_control= true) =
  ## Description:
  ##   Read API spec from `apisource`, generate godot package named `package` into `outdir`.
  ##
  ## Example:
  ##   coronation --apisorce:extension_api.json --outdir:out/godot410 --package:godot

  var apiuri = apisource.parseuri
  if apiuri.scheme.len == 0:
    apiuri.scheme = "file"
    apiuri.path = expandFilename apiuri.path

  echo apiuri
  echo repr apiuri
  let api = execCmdEx(&"curl -s {apiuri}").output.parsejson.to(JsonAPI)

  build.run api= api, BuildConfig(
    apisource: apisource,
    outdir: outdir,
    package: package,
  )
  if version_control: discard execShellCmd &"""
cd {outdir/package}
git init
git add *
git commit -m "generate from {api.header.version_full_name} by coronation {version}"
git tag v{api.header.version}
"""

when isMainModule:
  import cligen
  clCfg.version= "0.1.0"
  coronation.dispatch(
    usage= "$command $args\n\n${doc}\nOptions:\n$options",
    help= {
      "apisource": "Path to extension_api.json output by the engine",
      "outdir": "Directory that the generated package will be placed to",
      "package": "Name of generated package",
      "version-control": "If false, do not execute git init/commit to generated package"
    },
  )
