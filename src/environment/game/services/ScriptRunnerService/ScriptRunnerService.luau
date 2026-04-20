
local a=require"@Instance"
local b=require"@Kinemium.signal"
local c=require"@EnumMap"
local d=require"@sandboxer"
local e=zune.task
local f=zune.fs
local g=zune.process
require"@Kilang"
local h=zune.platform

local i=a.new"ScriptRunnerService"
i.ExplorerHidden=true

local j={luau={},python={},duktape={},quickjs={},luajit={}}
local k={}
local l={}
local m={}


local n={}


local o=1073741824

local p=1073741824

local function getMemoryUsage()
local q,r=h.getTotalMemory()
if q then
return r
end
return 0
end

local function createThreadInfo(q,r,s,t)
local u={
name=q,
thread=r,
env=s,
language=t or"luau",
status="running",
memoryLimit=o,
memoryAtStart=getMemoryUsage(),
createdAt=os.clock(),
globals={},
}
n[q]=u
return u
end

i.Initenvironment=function(q,r)
b.new()

i:SetProperties{
CreateScriptingRuntime=function(s,t,u)
m[s]={runner=t,clearer=u}
end,

RunLuauScript=function(s)
local t=r:GetService"LogService"
local u,v
local w=table.clone(q)
w.script=s

local x=e.spawn(function()local
x, y, z=d.run(s.Source,s.Name,w)

w.script=nil
u=y
v=z
end)

j.luau[s.Name]=x
createThreadInfo(s.Name,x,w,"luau")

if not u and v~=nil then
t.CreateLog("error",v)
end
return v
end,

RunPythonScript=function(s)
local t=require"@python"
local u=t.PythonVM.new()

for v,w in pairs(q)do
u:setGlobal(v,w)
end

j.python[s.Name]=u
createThreadInfo(s.Name,u,nil,"python")

return u:execute(s.Source),u
end,

RunQuickJS=function(s)
local t=require"@quickjs"

local u=e.spawn(function()
local u=t.new()
u.Evaluate(s.Source)
end)

j.duktape[s.Name]=u
createThreadInfo(s.Name,u,nil,"quickjs")
return u
end,

RunScript=function(s)
local t=s.Language

if m[t]then
return m[t].runner(s)
end

return
end,


GetActive=function()
return j
end,


GetThread=function(s)
return n[s]
end,


GetAllThreads=function()
local s={}
for t,u in pairs(n)do
s[t]={
name=u.name,
language=u.language,
status=u.status,
memoryLimit=u.memoryLimit,
createdAt=u.createdAt,
globals=u.globals,
}
end
return s
end,


GetThreadStatus=function(s)
local t=n[s]
if not t then
return"unknown"
end
return t.status
end,


SetGlobal=function(s,t,u)
local v=n[s]
if not v then
warn(`[ScriptRunner] Thread '{s}' not found`)
return false
end

if v.env then
v.env[t]=u
v.globals[t]=true
return true
else
warn(`[ScriptRunner] Thread '{s}' does not have an accessible environment`)
return false
end
end,


GetGlobal=function(s,t)
local u=n[s]
if not u or not u.env then
return nil
end
return u.env[t]
end,


SetMemoryLimit=function(s,t)
local u=n[s]
if not u then
warn(`[ScriptRunner] Thread '{s}' not found`)
return false
end
u.memoryLimit=math.min(t,o)
return true
end,


GetThreadGlobals=function(s)
local t=n[s]
if not t then
return{}
end
local u={}
for v in pairs(t.globals)do
table.insert(u,v)
end
return u
end,

RegisterUserThread=function(s)
table.insert(k,s)
end,

Clear=function()
for s,t in pairs(m)do
if t.clearer then
t.clearer()
end
end

for s,t in pairs(k)do
pcall(e.cancel,t)
end

for s,t in pairs(l)do
pcall(e.cancel,t)
l[s]=nil
end


for s,t in pairs(n)do
t.status="dead"
end

j={luau={},python={},duktape={},quickjs={},luajit={}}
k={}
n={}
end,

OpenInExternalEditor=function(s,t,u)
local v=u.."/"..s.UniqueId..".luau"
f.writeFile(v,s.Source)

s.IsOverridden=true

local w=f.realPath(v)

local x
local y={w}

if t=="vscode"then
x="code"
elseif t=="note"then
x="notepad"
else
x="start"
y={"",w}
end

e.spawn(function()
g.run(x,y,{shell=true})
end)

local z=l[s.UniqueId]
if z then
pcall(e.cancel,z)
end

local A
A=e.spawn(function()
local B=s.Source
while not s.Destroyed do
local C,D=pcall(f.stat,v)
if not C or not D or D.kind=="none"then
break
end

local E,F=pcall(f.readFile,v)
if E and F~=B then
B=F
s.Source=F
end

e.wait(0.3)
end

if l[s.UniqueId]==A then
l[s.UniqueId]=nil
end
end)
l[s.UniqueId]=A
end,


GetDefaultMemoryLimit=function()
return o
end,


GetMaxBufferSize=function()
return p
end,
}

i.CreateScriptingRuntime(c.Language.Luau,i.RunLuauScript,function()
for s,t in pairs(j.luau)do
e.cancel(t)
end
end)

i.CreateScriptingRuntime(c.Language.Python,i.RunPythonScript,function()
for s,t in pairs(j.python)do
t:close()
end
end)

i.CreateScriptingRuntime(c.Language.JavaScript,i.RunQuickJS,function()
for s,t in pairs(j.duktape)do
t:close()
end
end)

return i
end

return i