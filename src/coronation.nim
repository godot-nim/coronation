import config
import build

proc coronation*(apisource: string; outdir= "out/godot410"; package= "godot") =
  ## Description:
  ##   Read API spec from `apisource`, generate godot package named `package` into `outdir`.
  ##
  ## Example:
  ##   coronation --apisorce:extension_api.json --outdir:out/godot410 --package:godot

  build.run BuildConfig(
    apisource: apisource,
    outdir: outdir,
    package: package,
  )

when isMainModule:
  import cligen
  clCfg.version= "0.1.0"
  coronation.dispatch(
    usage= "$command $args\n\n${doc}\nOptions:\n$options",
    help= {
      "apisource": "Path to extension_api.json output by the engine",
      "outdir": "Directory that the generated package will be placed to",
      "package": "Name of generated package",
    },
  )
