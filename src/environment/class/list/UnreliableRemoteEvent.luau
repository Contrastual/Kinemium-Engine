local a=require"@Kinemium.signal"

return{
class="UnreliableRemoteEvent",
callback=function(b,c,d)
local e=a.new()
local f=a.new()

b:SetProperties{
OnClientEvent=e,
OnServerEvent=f,

}

return b
end,
}