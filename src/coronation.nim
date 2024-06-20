when isMainModule:
  import config
  import build

  build.run BuildConfig(
    apisource: "dump/extension_api.json",
  )
