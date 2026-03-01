type Middleware = (path: string, ...any) -> (boolean?)  -- return true to stop
type Handler = (...any) -> any
type Hook = (path: string) -> ()

type SchemaType = {
    string: () -> (value: any) -> boolean,
    nonEmptyString: () -> (value: any) -> boolean,
    stringPattern: (pattern: string) -> (value: any) -> boolean,
    number: () -> (value: any) -> boolean,
    int: () -> (value: any) -> boolean,
    u32: () -> (value: any) -> boolean,
    float: () -> (value: any) -> boolean,
    positive: () -> (value: any) -> boolean,
    negative: () -> (value: any) -> boolean,
    min: (minValue: number) -> (value: any) -> boolean,
    max: (maxValue: number) -> (value: any) -> boolean,
    range: (minValue: number, maxValue: number) -> (value: any) -> boolean,
    boolean: () -> (value: any) -> boolean,
    any: () -> (value: any) -> boolean,
    positiveInt: () -> (value: any) -> boolean,
    negativeInt: () -> (value: any) -> boolean,
    u8: () -> (value: any) -> boolean,
    u16: () -> (value: any) -> boolean,
    u64: () -> (value: any) -> boolean,
    i8: () -> (value: any) -> boolean,
    i16: () -> (value: any) -> boolean,
    i32: () -> (value: any) -> boolean,
    i64: () -> (value: any) -> boolean,
    allOf: (...any) -> (value: any) -> boolean,
    anyOf: (...any) -> (value: any) -> boolean,
    notf: ((value: any) -> boolean) -> (value: any) -> boolean,
    minItems: (min: number) -> (value: any) -> boolean,
    maxItems: (max: number) -> (value: any) -> boolean,
    itemCount: (min: number, max: number) -> (value: any) -> boolean,
    exact: (expected: any) -> (value: any) -> boolean,
    strictMap: (definition: { [any]: (any) -> boolean }) -> (value: any) -> boolean,
    noExtraKeys: (definition: { [any]: (any) -> boolean }) -> (value: any) -> boolean,
    transform: ((any) -> boolean, (any) -> any) -> (value: any) -> boolean,
    coerceNumber: () -> (value: any) -> boolean,
    lazy: (() -> (value: any) -> boolean) -> (value: any) -> boolean,
    trimmedString: () -> (value: any) -> boolean,
    lowercase: () -> (value: any) -> boolean,
    uppercase: () -> (value: any) -> boolean,
    startsWith: (prefix: string) -> (value: any) -> boolean,
    endsWith: (suffix: string) -> (value: any) -> boolean,
    contains: (substr: string) -> (value: any) -> boolean,
    even: () -> (value: any) -> boolean,
    odd: () -> (value: any) -> boolean,
    betweenExclusive: (min: number, max: number) -> (value: any) -> boolean,
    multipleOf: (n: number) -> (value: any) -> boolean,
    arrayLengthExactly: (n: number) -> (value: any) -> boolean,
    hasKeys: (...string) -> (value: any) -> boolean,
    keyType: ((key: any) -> boolean) -> (value: any) -> boolean,
    valueType: ((value: any) -> boolean) -> (value: any) -> boolean,
    default: (defaultValue: any, validator: (value: any) -> boolean) -> (value: any) -> boolean,
    decimal: (precision: number) -> (value: any) -> boolean,
    email: () -> (value: any) -> boolean,
    noHoles: () -> (value: any) -> boolean,
    readonly: () -> (value: any) -> boolean,
    frozen: () -> (value: any) -> boolean,
    callable: () -> (value: any) -> boolean,
    metatable: (expected: any) -> (value: any) -> boolean,
    deepArray: (depth: number, validator: (value: any) -> boolean) -> (value: any) -> boolean,
    shape: ((value: any) -> boolean) -> (value: any) -> boolean,
    guard: ((value: any) -> boolean) -> (value: any) -> boolean,
    pipe: (...(value: any) -> boolean) -> (value: any) -> boolean,
    url: () -> (value: any) -> boolean,
    uuid: () -> (value: any) -> boolean,
    hexColor: () -> (value: any) -> boolean,
    length: (min: number?, max: number?) -> (value: any) -> boolean,
    arrayOf: ((value: any) -> boolean) -> (value: any) -> boolean,
    setOf: ((value: any) -> boolean) -> (value: any) -> boolean,
    dict: ((key: any) -> boolean, (value: any) -> boolean) -> (value: any) -> boolean,
    timestamp: () -> (value: any) -> boolean,
    dateString: () -> (value: any) -> boolean,
    timeString: () -> (value: any) -> boolean,
    vector2: () -> (value: any) -> boolean,
    vector3: () -> (value: any) -> boolean,
    color3: () -> (value: any) -> boolean,
    position3D: () -> (value: any) -> boolean,
    enum: (enumTable: { any }) -> (value: any) -> boolean,
    optional: ((value: any) -> boolean) -> (value: any) -> boolean,
    emptyTable: () -> (value: any) -> boolean,
    exactKeys: (...string) -> (value: any) -> boolean,
    partial: ({ [any]: (value: any) -> boolean }) -> (value: any) -> boolean,
    zero: () -> (value: any) -> boolean,
    nonZero: () -> (value: any) -> boolean,
    clamped: (min: number, max: number) -> (value: any) -> boolean,
    identifier: () -> (value: any) -> boolean,
    snakeCase: () -> (value: any) -> boolean,
    camelCase: () -> (value: any) -> boolean,
    component: ({ [any]: (value: any) -> boolean }) -> (value: any) -> boolean,
    entityId: () -> (value: any) -> boolean,
    xor: ((value: any) -> boolean, (value: any) -> boolean) -> (value: any) -> boolean,
    implies: ((value: any) -> boolean, (value: any) -> boolean) -> (value: any) -> boolean,
    when: ((value: any) -> boolean, (value: any) -> boolean, ((value: any) -> boolean)?) -> (value: any) -> boolean,
    noMetatable: () -> (value: any) -> boolean,
    shallowImmutable: () -> (value: any) -> boolean,
    assert: ((value: any) -> boolean, string?) -> (value: any) -> boolean,
    debug: (string, (value: any) -> boolean) -> (value: any) -> boolean,
    kebabCase: () -> (value: any) -> boolean,
    table: ({ (value: any) -> boolean }) -> (value: any) -> boolean,
    map: ({ [any]: (value: any) -> boolean }) -> (value: any) -> boolean,
    new: (definition: any) -> any,
    validate: (self: any, packet: any) -> (boolean, string?, string?),
}

type Class = {
    __name: string,
    __index: any,
    __base: Class?,
    __type: "ClassType",

    New: (...any) -> any,
    Super: (Class, methodName: string, ...any) -> any,
}

type RouteEntry = {
    handler: Handler,
    pattern: string,
}

type RouteHooks = {
    onAdd: {Hook},
    onRemove: {Hook},
}

type Routes = {
    routes: {[string]: RouteEntry},
    middlewares: {Middleware},
    hooks: RouteHooks,

    add: (path: string, handler: Handler) -> (),
    remove: (path: string) -> (),
    clear: () -> (),
    count: () -> number,
    list: () -> {string},
    has: (path: string) -> boolean,
    use: (fn: Middleware) -> (),
    on: (event: "onAdd" | "onRemove", fn: Hook) -> (),
    handle: (path: string, ...any) -> (any, string?),
    callSafe: (path: string, ...any) -> (any, string?),
}

type ClassGlobal = {
    New: (name: string?, base: Class?) -> Class,
    IsInstance: (obj: any, cls: Class) -> boolean,
}

type Task = any

type Disposable = {
    _tasks: { { task: Task, method: string? } },
    _destroyed: boolean,

    Add: (self: Disposable, task: Task, methodName: string?) -> (),
    Remove: (self: Disposable, task: Task) -> (),
    Destroy: (self: Disposable) -> (),
    IsDestroyed: (self: Disposable) -> boolean,
}

type DisposableClass = {
    new: () -> Disposable,
    CleanupTask: (task: Task, methodName: string?) -> (),
}

type Connection = {
    Connected: boolean,
    Priority: number,
    Disconnect: (self: Connection) -> (),
    Fire: (self: Connection, ...any) -> (),
    SetPriority: (self: Connection, priority: number) -> (),
}

type Video = {
	Url: string,
	Length: number,
	Framerate: number,

	Clone: (self: Video) -> Video,
	Equals: (self: Video, other: any) -> boolean,
	GetFrameAtTime: (self: Video, seconds: number) -> number,
}

type VideoDatatype = {
	new: (url: string, length: number?, framerate: number?) -> Video,
	ClassName: string,
}

type Signal = {
    new: () -> Signal,
    Connect: (self: Signal, fn: (...any) -> (), priority: number?) -> Connection,
    Once: (self: Signal, fn: (...any) -> ()) -> Connection,
    Wait: (self: Signal, timeout: number?) -> (...any),
    Fire: (self: Signal, ...any) -> (),
    FireDeferred: (self: Signal, ...any) -> (),
    FireParallel: (self: Signal, ...any) -> (),
    Pause: (self: Signal) -> (),
    Resume: (self: Signal) -> (),
    IsPaused: (self: Signal) -> boolean,
}

type include = (path: string) -> (any)
type FlagExists = (flag: string) -> (boolean)

-- C primitives
type int = any
type float = any
type double = any
type bool = any
type char = any

-- C sized integers
type int8_t = any
type int16_t = any
type int32_t = any
type int64_t = any
type uint8_t = any
type uint16_t = any
type uint32_t = any
type uint64_t = any

-- Rust-style integers
type i8 = any
type i16 = any
type i32 = any
type i64 = any
type i128 = any
type u8 = any
type u16 = any
type u32 = any
type u64 = any
type u128 = any
type f32 = any
type f64 = any

-- C++ / common
type wchar_t = any
type size_t = any
type ptrdiff_t = any
type long = any
type short = any
type byte = any
type word = any
type dword = any
type qword = any
type uchar = any
type uint = any
type ulong = any
type ushort = any

-- Qualifiers (treated as wrappers)
type const = any
type static = any
type volatile = any
type auto = any
type signed = any
type unsigned = any

-- Rust keywords
type let = any
type mut = any

-- JS / C# style
type var = any

-- Compound types
type long_long = any
type unsigned_int = any
type unsigned_long = any
type unsigned_char = any
type signed_int = any
type signed_char = any

-- Pointer / reference annotations
type ptr = any
type ref = any
type nullptr_t = any

declare int: int
declare float: float
declare double: double
declare bool: bool
declare char: char
declare int8_t: int8_t
declare int16_t: int16_t
declare int32_t: int32_t
declare int64_t: int64_t
declare uint8_t: uint8_t
declare uint16_t: uint16_t
declare uint32_t: uint32_t
declare uint64_t: uint64_t
declare i8: i8
declare i16: i16
declare i32: i32
declare i64: i64
declare i128: i128
declare u8: u8
declare u16: u16
declare u32: u32
declare u64: u64
declare u128: u128
declare f32: f32
declare f64: f64
declare wchar_t: wchar_t
declare size_t: size_t
declare ptrdiff_t: ptrdiff_t
declare long: long
declare short: short
declare byte: byte
declare word: word
declare dword: dword
declare qword: qword
declare uchar: uchar
declare uint: uint
declare ulong: ulong
declare ushort: ushort
declare const: const
declare static: static
declare volatile: volatile
declare auto: auto
declare signed: signed
declare unsigned: unsigned
declare var: var
declare let: let
declare mut: mut
declare long_long: long_long
declare unsigned_int: unsigned_int
declare unsigned_long: unsigned_long
declare unsigned_char: unsigned_char
declare signed_int: signed_int
declare signed_char: signed_char
declare ptr: ptr
declare ref: ref
declare nullptr_t: nullptr_t
declare Signal: Signal
declare Disposable: DisposableClass
declare kiclass: ClassGlobal
declare Routes: Routes
declare Schema: SchemaType
declare ishared: {any}
declare shared: {}
declare Video: VideoDatatype
declare FlagExists: FlagExists
declare include: include