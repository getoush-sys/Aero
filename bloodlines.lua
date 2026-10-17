--[[
	bloodlines.lua

	- Anti Cheat Bypass / No Fall Damage
	- Chakra point teleport dropdown (workspace.ChakraPoints)
]]

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/getoush-sys/Aero/refs/heads/main/Library.lua"))()

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer

-- // Functions
do
	-- Anti Cheat Bypass / No Fall Damage
	do
		local VMProtect = type(SX_VM_CNONE) == "function" and SX_VM_CNONE or function() end

		local dataEvent

		for Index, Name in { "DataEvent", "Data" } do
			local Found = ReplicatedStorage:FindFirstChild(Name, true)

			if Found and Found:IsA("RemoteEvent") then
				dataEvent = Found
				break
			end
		end

		local oldNamecall

		local function fireServerHook(remote, action, ...)
			if
				remote == dataEvent
				and type(action) == "string"
				and string.lower(action) == "banme"
			then
				return warn("[Aero] Blocked banme");
			end;

			return oldNamecall(remote, action, ...);
		end;

		local Hooked, HookError = pcall(function()
			oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
				VMProtect();

				local method = getnamecallmethod();

				if
					(method == "FireServer" or method == "fireServer")
					and typeof(self) == "Instance"
					and self == dataEvent
				then
					return fireServerHook(self, ...);
				elseif (method == "FindFirstChild") then
					local args = { ... };

					if (args[1] == "NegateFall" and Library.Flags["No Fall Damage"]) then
						print("[Aero] no fall damage haha");
						return true;
					end;
				end;

				return oldNamecall(self, ...);
			end);
		end)

		if not Hooked then
			warn("[Aero] bypass failed: " .. tostring(HookError));
		end
	end;
end

-- // Chakra Points
local Points = {}

local function GetPointName(Point)
	local Attribute = Point:GetAttribute("PointName")

	if type(Attribute) == "string" and Attribute ~= "" then
		return Attribute
	end

	local Value = Point:FindFirstChild("PointName")

	if Value and Value:IsA("ValueBase") and type(Value.Value) == "string" and Value.Value ~= "" then
		return Value.Value
	end

	return Point.Name
end

local function GetPointPosition(Point)
	if Point:IsA("BasePart") then
		return Point.Position
	end

	if Point:IsA("Model") then
		local Success, Pivot = pcall(function()
			return Point:GetPivot().Position
		end)

		if Success then
			return Pivot
		end
	end

	local Part = Point:FindFirstChildWhichIsA("BasePart", true)

	return Part and Part.Position or nil
end

local function CollectPoints()
	table.clear(Points)

	local Names = {}
	local Folder = workspace:FindFirstChild("ChakraPoints")

	if not Folder then
		return Names
	end

	for Index, Point in Folder:GetChildren() do
		local Name = GetPointName(Point)

		if Name and Name ~= "" then
			local Unique = Name
			local Suffix = 2

			while Points[Unique] do
				Unique = Name .. " (" .. Suffix .. ")"
				Suffix = Suffix + 1
			end

			Points[Unique] = Point
			table.insert(Names, Unique)
		end
	end

	table.sort(Names)

	return Names
end

local function TeleportToPoint(Name)
	local Point = Points[Name]

	if not Point or not Point.Parent then
		return false, "Point no longer exists"
	end

	local Position = GetPointPosition(Point)

	if not Position then
		return false, "No position found"
	end

	local Character = LocalPlayer.Character

	if not Character then
		return false, "No character"
	end

	local Root = Character:FindFirstChild("HumanoidRootPart")

	if not Root then
		return false, "No HumanoidRootPart"
	end

	Root.CFrame = CFrame.new(Position + Vector3.new(0, 3, 0))

	return true
end

-- // Interface
local Window = Library:Window({ Name = "Aero" })
local Watermark = Library:Watermark("Aero")
local KeybindList = Library:KeybindList()

local SettingsPage = Library:CreateSettingsPage(Window, KeybindList, Watermark)

local MainPage = Window:Page({ Name = "Main", Columns = 2 })
local MiscPage = Window:Page({ Name = "Misc", Columns = 2 })

local TeleportSection = MainPage:Section({ Name = "Chakra Points", Side = 1 })
local BypassSection = MiscPage:Section({ Name = "Bypass", Side = 1 })

local ChakraDropdown = TeleportSection:Dropdown({
	Name = "Chakra Point",
	Flag = "ChakraPoint",
	Multi = false,
	MaxSize = 150,
	Items = CollectPoints(),
	Callback = function(Value)
		if Value == nil then
			return
		end

		local Success, Reason = TeleportToPoint(Value)

		if Success then
			Library:Notification("Teleported to " .. Value, 3, Color3.fromRGB(94, 213, 120))
		else
			Library:Notification("Teleport failed: " .. tostring(Reason), 3, Color3.fromRGB(255, 0, 0))
		end
	end,
})

TeleportSection:Button({
	Name = "Refresh points",
	Callback = function()
		ChakraDropdown:Refresh(CollectPoints())
		Library:Notification("Chakra points refreshed", 3, Color3.fromRGB(94, 213, 120))
	end,
})

BypassSection:Toggle({
	Name = "No Fall Damage",
	Flag = "No Fall Damage",
	Default = false,
	Callback = function(Value)
		Library:Notification("No Fall Damage: " .. tostring(Value), 3)
	end,
})

task.spawn(function()
	local Folder = workspace:WaitForChild("ChakraPoints", 15)

	if Folder and #CollectPoints() > 0 then
		ChakraDropdown:Refresh(CollectPoints())
	end
end)

Library:LoadAutoload()
