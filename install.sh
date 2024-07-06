godot --dump-extension-api

nimble install https://github.com/godot-nim/godotcore

nimble build
bin/coronation --apisource:extension_api.json
cd out/godot410
nimble install