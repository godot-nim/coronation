import godot
import godot/classindex
import godot/classes/Node

type MyExtensionClass* = ref object of Node


method ready(self: MyExtensionClass) {.gdsync.} =
  echo "HELLO, WORLD!"

method process(self: MyExtensionClass; delta: float64) {.gdsync.} =
  discard
