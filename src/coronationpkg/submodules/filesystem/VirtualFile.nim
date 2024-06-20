import sdk
import cloths

type
  VirtualFile* = ref object of VirtualNode

method contents*(file: VirtualFile): Cloth {.base.} = discard
method generate*(file: VirtualFile) =
  (file.path & file.ext).writeFile $contents file

method dumpTree(file: VirtualFile): Cloth = file.name & file.ext