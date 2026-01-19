local Instance = require("@Instance")
local signal = require("@Kinemium.signal")

local SQLiteService = Instance.new("SQLiteBaseService")

local SQLiteBases = {}

SQLiteService.InitRenderer = function(renderer, renderer_signal, datamodel)
	task.spawn(function()
		local sqlite = zune.sqlite
		repeat
			task.wait()
		until datamodel.SerializationService
		local SerializationService = datamodel.SerializationService
		local userdata = SerializationService.userdata

		SQLiteService:SetProperties({
			GetSQLiteBase = function(name: string)
				if SQLiteBases[name] then
					return SQLiteBases[name]
				end
				local store = Instance.new("SQLiteStore")
				store.Name = name
				SQLiteBases[name] = store

				local db = sqlite.open(name .. ".db")

				db:execute([[
					CREATE TABLE IF NOT EXISTS datastore (
						key TEXT PRIMARY KEY,
						value TEXT
					)
				]])

				store:SetProperties({
					Open = function(self)
						return db
					end,

					GetAsync = function(key, callback)
						task.spawn(function()
							local success, result = pcall(function()
								local stmt = db:query("SELECT value FROM datastore WHERE key = ?", key)
								local rows = stmt:rows()
								if rows[1] then
									return userdata.Decode(rows[1].value)
								end
								return nil
							end)
							callback(success, result)
						end)
					end,

					SetAsync = function(key, value, callback)
						task.spawn(function()
							local success, err = pcall(function()
								db:execute(
									[[
                INSERT INTO datastore(key, value)
                VALUES (?, ?)
                ON CONFLICT(key) DO UPDATE SET value=excluded.value
            ]],
									{ key, userdata.Encode(value) }
								)
							end)
							if callback then
								callback(success, err)
							end
						end)
					end,

					UpdateAsync = function(self, key, transform)
						local old = store:GetAsync(key)
						local new = transform(old)
						store:SetAsync(key, new)
						return new
					end,

					Close = function(self)
						db:close()
					end,
				})

				return store
			end,
		})
	end)
end

return SQLiteService
