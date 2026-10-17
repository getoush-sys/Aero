--[[
	deepwoken.lua

	Deepwoken
]]

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/getoush-sys/Aero/refs/heads/main/Library.lua"))()

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer

-- // Interface
local Window = Library:Window({ Name = "Aero" })
local Watermark = Library:Watermark("Aero")
local KeybindList = Library:KeybindList()

local SettingsPage = Library:CreateSettingsPage(Window, KeybindList, Watermark)

local MainPage = Window:Page({ Name = "Main", Columns = 2 })

local MainSection = MainPage:Section({ Name = "Main", Side = 1 })

MainSection:Label("Features coming soon")

Library:Notification("Aero loaded (Deepwoken)", 5)

Library:LoadAutoload()
