import godot

import MyExtensionClass

process initialize_scene:
  register MyExtensionClass.MyExtensionClass

GDExtension_EntryPoint name=init_library
