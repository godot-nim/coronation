import submodules/semanticstrings
import std/tables

type
  RenderableType* = ref object of RootObj
    typename*: TypeSym
    nativename*: string

  TypeDB* = TableRef[TypeSym, RenderableType]
let typeDB* = new TypeDB

proc registerDB*(renderable: RenderableType) =
  typeDB[renderable.typename] = renderable
proc with_registerDB*[T: RenderableType](renderable: T): T =
  registerDB(renderable); renderable