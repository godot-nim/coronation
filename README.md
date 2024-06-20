# godot-nim/coronation

godot-nim/coronation provides a generator that generates any version of the GDExtension binding.

## Quick Start

```console
coronation$ nimble run
coronation$ cd out/godot410
coronation/out/godot410$ nimble install # (or, nimble develop)
coronation/out/godot410$ cd -
coronation$ nimble install https://github.com/godot-nim/godotcore
coronation$ cd tests
coronation/tests$ nim c src/test
coronation/tests$ file lib/libtest.so
coronation/tests$ godot --editor
```

## Requires

* nim compiler >= 2.0.0
* [panno8m/cloths](https://github.com/panno8m/cloths) (nimble ready)
* [godot-nim/godotcore](https://github.com/godot-nim/godotcore) (only available on github)

## Work Progress

It is being transplanted from [godot-nim](https://github.com/panno8m/godot-nim).

1. achieve what was possible in the old project
2. support missing features
3. improve documentation
4. upgrade to Godot 4.3

## Contribute

Currently, we are working on a generator that can be easily extended upon request and an interface that is easy to handle.

We need contributions not only by reporting bugs and implementing features, but also by suggesting better syntax, pointing out areas of poor readability, and supplementing documentation comments.