repeat
	task.wait()
until ishared.EscapeMenu_Signal

local sign = ishared.EscapeMenu_Signal

local KinemiumFontService = game:GetService("KinemiumFontService")
local Players = game:GetService("Players")

local vend = KinemiumFontService.GetDefaultFontSmall()

local function newPlayerCell(playerObject: Player)
	return {
		name = playerObject.Name,
		description = tostring(playerObject.UserId),
		font = vend,
		backgroundColor = Color3.new(0, 0, 0),
		value = true,
	}
end

sign:Fire("MakeWindow", "Players", function(window)
	local cellList = Instance.new("UICellList")
	cellList.Parent = window
	cellList.Size = UDim2.new(1, -20, 1, 0)
	cellList.Sections = {
		Players = {},
	}

	Players.ChildAdded:Connect(function(new)
		if new:IsA("Player") then
			table.insert(cellList.Sections.Players, newPlayerCell(new))
		end
	end)

	Players.ChildRemoved:Connect(function(old)
		if old:IsA("Player") then
			for i, cell in pairs(cellList.Sections.Players) do
				if cell.description == old.UserId then
					table.remove(cellList.Sections.Players, i)
					break
				end
			end
		end
	end)

	for _, player in pairs(Players:GetChildren()) do
		table.insert(cellList.Sections.Players, newPlayerCell(player))
	end
end)
