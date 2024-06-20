import std/tables

import submodules/semanticstrings

const AutoDetect* = "%AutoDetect%"
type BuildConfigResolveError = object of CatchableError

type BuildConfig* {.requiresinit.} = object
  outdir*: string = AutoDetect
  project*: string = AutoDetect
  apisource*: string

proc resolve*(conf: BuildConfig): BuildConfig =
  BuildConfig(
    outdir: case conf.outdir:
    of AutoDetect:
      "out/godot410"
    else:
      conf.outdir
    ,
    project: case conf.project:
    of AutoDetect:
      "godot"
    else:
      conf.project
    ,
    apisource: case conf.apisource:
    of AutoDetect:
      raise newException(BuildConfigResolveError, "`apisource` MUST be specified.")
    else:
      conf.apisource
  )


type
  IgnoreConf* = object
    module*: bool
    constructor*: bool
    operator*: bool
    procedure*: bool
    subscript*: bool
    constructor_white*: seq[int]
    operator_white*: seq[ContainerKey]
    procedure_white*: seq[ContainerKey]

template ck(str): ContainerKey = ContainerKey "`" & str & "`"
template ts(str): TypeSym = TypeSym str

const ignoreConf*: Table[TypeSym, IgnoreConf] = toTable {
  ts"Vector2": IgnoreConf(
    subscript: true,
    constructor: true,
    procedure: true,
    procedure_white: @[
      ck"Vector2 limitLength",
      ck"Vector2 project",
      ck"Vector2 slerp",
      ck"Vector2 cubicInterpolate",
      ck"Vector2 cubicInterpolateInTime",
      ck"Vector2 bezierInterpolate",
      ck"Vector2 bezierDerivative",
      ck"Vector2 rotated",
      ck"Vector2 orthogonal",
      ck"Vector2 bounce",
      ck"Vector2 reflect",
    ],
    operator: true,
    operator_white: @[
      ck"== Vector2 Variant",
      ck"!= Vector2 Variant",
      ck"* Vector2 Transform2D",
      ck"contains Vector2 Dictionary",
      ck"contains Vector2 Array",
      ck"contains Vector2 PackedVector2Array",
    ],
  ),
  ts"Vector2i": IgnoreConf(
    subscript: true,
    constructor: true,
    procedure: true,
    operator: true,
    operator_white: @[
      ck"== Vector2i Variant",
      ck"!= Vector2i Variant",
      ck"contains Vector2i Dictionary",
      ck"contains Vector2i Array",
    ],
  ),
  ts"Vector3": IgnoreConf(
    subscript: true,
    constructor: true,
    procedure: true,
    procedure_white: @[
      ck"Vector3 angleTo",
      ck"Vector3 signedAngleTo",
      ck"Vector3 limitLength",
      ck"Vector3 inverse",
      ck"Vector3 rotated",
      ck"Vector3 slerp",
      ck"Vector3 cubicInterpolate",
      ck"Vector3 cubicInterpolateInTime",
      ck"Vector3 bezierInterpolate",
      ck"Vector3 bezierDerivative",
      ck"Vector3 cross",
      ck"Vector3 outer",
      ck"Vector3 project",
      ck"Vector3 bounce",
      ck"Vector3 reflect",
      ck"Vector3 octahedronEncode",
      ck"Vector3 octahedronDecode",
    ],
    operator: true,
    operator_white: @[
      ck"== Vector3 Variant",
      ck"!= Vector3 Variant",
      ck"* Vector3 Quaternion",
      ck"* Vector3 Basis",
      ck"* Vector3 Transform3D",
      ck"contains Vector3 Dictionary",
      ck"contains Vector3 Array",
      ck"contains Vector3 PackedVector3Array",
    ],
  ),
  ts"Vector3i": IgnoreConf(
    subscript: true,
    constructor: true,
    procedure: true,
    operator: true,
    operator_white: @[
      ck"== Vector3i Variant",
      ck"!= Vector3i Variant",
      ck"contains Vector3i Dictionary",
      ck"contains Vector3i Array",
    ],
  ),
  ts"Vector4": IgnoreConf(
    subscript: true,
    constructor: true,
    procedure: true,
    procedure_white: @[
      ck"Vector4 cubicInterpolate",
      ck"Vector4 cubicInterpolateInTime",
      ck"Vector4 inverse",
    ],
    operator: true,
    operator_white: @[
      ck"== Vector4 Variant",
      ck"!= Vector4 Variant",
      ck"* Vector4 Projection",
      ck"contains Vector4 Dictionary",
      ck"contains Vector4 Array",
    ],
  ),
  ts"Vector4i": IgnoreConf(
    subscript: true,
    constructor: true,
    procedure: true,
    operator: true,
    operator_white: @[
      ck"== Vector4i Variant",
      ck"!= Vector4i Variant",
      ck"contains Vector4i Dictionary",
      ck"contains Vector4i Array",
    ],
  ),
  ts"Quaternion": IgnoreConf(
    subscript: true,
    constructor: true,
    constructor_white: @[1, 2, 3, 4],
  ),
  ts"Color": IgnoreConf(
    subscript: true,
    constructor: true,
    constructor_white: @[5, 6],
  ),
  ts"Plane": IgnoreConf(
    constructor: true,
    constructor_white: @[1, 2, 3, 4, 5],
  ),
  ts"Basis": IgnoreConf(
    subscript: true,
  ),
  ts"Projection": IgnoreConf(
    subscript: true,
  ),
  ts"Transform2D": IgnoreConf(
    subscript: true,
  ),
  ts"bool": IgnoreConf(
    constructor: true,
    operator: true,
    operator_white: @[
      ck"== bool Variant",
      ck"!= bool Variant",
      ck"contains bool Dictionary",
      ck"contains bool Array",
    ],
  ),
  ts"Int": IgnoreConf(
    constructor: true,
    operator: true,
    operator_white: @[
      ck"== Int Variant",
      ck"!= Int Variant",
    ],
  ),
  ts"Float": IgnoreConf(
    constructor: true,
    operator: true,
    operator_white: @[
      ck"== Float Variant",
      ck"!= Float Variant",
      ck"contains Float Dictionary",
      ck"contains Float Array",
      ck"contains Float PackedByteArray",
      ck"contains Float PackedInt32Array",
      ck"contains Float PackedInt64Array",
      ck"contains Float PackedFloat32Array",
      ck"contains Float PackedFloat64Array",
    ],
  ),
  ts"Nil": IgnoreConf(
    module: true,
    constructor: true,
    operator: true,
  ),
}

proc getignore*(ts: TypeSym): IgnoreConf = ignoreConf.getOrDefault(ts)