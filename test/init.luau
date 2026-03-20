local zembed = require("@zembed")

if zembed.IsEmbedded() or not zune.testing.running then
  return nil
end

for _, file in zune.fs.entries("./test") do
  local name = zune.fs.path.stem(file.name)
  if name ~= "init" then
    zune.luau.garbagecollect()
    require("@self/" .. name)
  end
end

if zune.testing._failed > 0 then
  warn(string.format("%i/%i tests failed, terminating", zune.testing._failed, zune.testing._count))
end

zune.process.exit(0)