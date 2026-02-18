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