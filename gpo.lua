local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/getoush-sys/Aero/refs/heads/main/Library.lua"))()

local Window = Library:Window({ Name = "Aero" })
local Watermark = Library:Watermark("GPO")
local KeybindList = Library:KeybindList()

local Connections = {}

local function Safe(Fn)
	return function(...)
		local Ok, Err = pcall(Fn, ...)
		if not Ok then
			warn(Err)
		end
	end
end

local function Call(Object, Method, ...)
	local Args = table.pack(...)
	local Ok, Result = pcall(function()
		return Object[Method](Object, table.unpack(Args, 1, Args.n))
	end)
	if not Ok then
		warn(Method, Result)
		return nil
	end
	return Result
end

local function FiniteNumber(N)
	return type(N) == "number" and N == N and N > -math.huge and N < math.huge
end

local function ValidVec3(P)
	return typeof(P) == "Vector3" and FiniteNumber(P.X) and FiniteNumber(P.Y) and FiniteNumber(P.Z)
end

local function SafePosOf(Part)
	if not Part then return nil end
	local Ok, Pos = pcall(function()
		return Part.Position
	end)
	if not Ok or not ValidVec3(Pos) then return nil end
	return Pos
end

local function CameraPos()
	local Cam = workspace.CurrentCamera
	if not Cam then return nil end
	local Ok, Pos = pcall(function()
		return Cam.CFrame.Position
	end)
	if not Ok or not ValidVec3(Pos) then return nil end
	return Pos
end

local function DistSqBetween(A, B)
	if not ValidVec3(A) or not ValidVec3(B) then return nil end
	local DX, DY, DZ = A.X - B.X, A.Y - B.Y, A.Z - B.Z
	local D = DX * DX + DY * DY + DZ * DZ
	if not FiniteNumber(D) then return nil end
	return D
end

local function SafeStuds(D)
	if not FiniteNumber(D) then return nil end
	return math.floor(D + 0.5)
end

local function ToKeybindCode(KeyString)
	local Key = tostring(KeyString or "F4"):upper()
	local EnumMapping = {
		F1 = Enum.KeyCode.F1, F2 = Enum.KeyCode.F2, F3 = Enum.KeyCode.F3, F4 = Enum.KeyCode.F4, F5 = Enum.KeyCode.F5, F6 = Enum.KeyCode.F6, F7 = Enum.KeyCode.F7, F8 = Enum.KeyCode.F8, F9 = Enum.KeyCode.F9, F10 = Enum.KeyCode.F10, F11 = Enum.KeyCode.F11, F12 = Enum.KeyCode.F12,
	}
	if EnumMapping[Key] then
		return EnumMapping[Key]
	end
	for _, EnumItem in pairs(Enum.KeyCode:GetEnumItems()) do
		if string.upper(tostring(EnumItem.Name)) == Key then
			return EnumItem
		end
	end
	return Enum.KeyCode.F4
end

local function GetService(Name)
	local Ok, Service = pcall(function()
		return game:GetService(Name)
	end)
	return Ok and Service or nil
end

local Services = {
	Players = GetService("Players"), ReplicatedStorage = GetService("ReplicatedStorage"), RunService = GetService("RunService"), TweenService = GetService("TweenService"), UserInputService = GetService("UserInputService"), VirtualUser = GetService("VirtualUser"), Workspace = GetService("Workspace"), HttpService = GetService("HttpService"), PathfindingService = GetService("PathfindingService"),
}

local Player = { Object = Services.Players.LocalPlayer }
Player.Gui = Player.Object:WaitForChild("PlayerGui", 15)

local Utils = { Running = true }

function Utils.Notify(Message)
	pcall(function() Library:Notification(tostring(Message), 4) end)
end

function Utils.NotifyToggle(Name, Value)
	Utils.Notify(Name .. (Value and " enabled." or " disabled."))
end

function Utils.GetRoot()
	local Character = Player.Object.Character
	return Character and Character:FindFirstChild("HumanoidRootPart")
end

function Utils.GetHumanoid()
	local Character = Player.Object.Character
	return Character and Character:FindFirstChildOfClass("Humanoid")
end

function Utils.Give(Connection)
	if typeof(Connection) == "RBXScriptConnection" then
		table.insert(Connections, Connection)
	end
	return Connection
end

function Utils.ResetToggle(Id)
	task.defer(function() pcall(function() Library.Flags[Id] = false end) end)
end

function Utils.Post(Url, Payload)
	task.spawn(function()
		local Ok, Err = pcall(function()
			local Request = request or http_request or (syn and syn.request) or (http and http.request)
			if typeof(Request) ~= "function" then return end
			Request({ Url = Url, Method = "POST", Headers = { ["Content-Type"] = "application/json" }, Body = Services.HttpService:JSONEncode(Payload) })
		end)
		if not Ok then warn("Webhook:", Err) end
	end)
end

function Utils.Loop(State, Tick)
	task.spawn(function()
		while Utils.Running and task.wait(State.Interval) do
			if State.Enabled then
				local Success, ErrorMessage = pcall(Tick)
				if not Success then warn(ErrorMessage) end
			end
		end
	end)
end

local AutoFish = {
    Enabled = false,
    Busy = false,
    CastPending = false,
    LastCast = 0,
    NextAction = 0,
    CastTimeout = 18,
    RecastDelay = 0.6,
    Interval = 0.15,
    StoreFruit = false,
    FruitStorage = nil,
    FruitStorageBusy = false,
    FruitAttempts = {},
    FruitNotified = {},
    FruitRetryAt = {},
    MaxFruitAttempts = 5,
    FruitRetryDelay = 3,
    Bait = "Common Fish Bait",
    BaitWarned = false,
    SmartBait = false,
    LastFallback = nil,
    BaitOrder = {
        "Common Fish Bait",
        "Rare Fish Bait",
        "Legendary Fish Bait",
    },
    UsingFallback = false,
    Hook = {
        Module = nil,
        Action = nil,
        Original = nil,
        Installed = false,
    },
}

local AutoStoreFruit = {
    Enabled = false,
    Interval = 0.15,
}

local Webhook = {
    Enabled = false,
    Url = "",
    Drops = {
        ["nightfall aura"] = true,
        ["brand of sacrifice"] = true,
    },
    KnownDrops = {},
    DropInitialized = false,
}

local CandyWebhook = {
    Enabled = false,
    Url = "",
    LastCandy = nil,
}

local AutoBuyBait = {
    Enabled = false,
    Interval = 1,
    Amount = 1,
    Busy = false,
}

local AutoSellFish = {
    Enabled = false,
    Interval = 5,
    Busy = false,
    SelectedRarity = { ["Common Fish"] = true },
    Utils = nil,
}

local AntiAFK = {
    Enabled = false,
    Connection = nil,
}

local Movement = {
    Fly = false,
    FlySpeed = 80,
    Walk = false,
    WalkSpeed = 60,
}

local HalloweenFarm = {
    Enabled = false,
    Interval = 0.25,
    Cooldown = 175,
    RetryDelay = 25,
    PostKnockDelay = 7,
    Speed = 30,
    Busy = false,
    Session = 0,
    LastHouse = nil,
    Recent = {},
    RecentLimit = 3,
    MinHouseDistance = 80,
    PickPool = 4,
    CooldownUntil = {},
    Highlights = {},
    FadeTime = 0.6,
    OnlyBuyAtMax = false,
    MaxCandy = 500,
    MaxPathAttempts = 5,
    MaxLookahead = 12,
    HoverHeight = 2,
    Moving = false,
    HoverConnection = nil,
    MaxStep = 12,
    VerticalSpeed = 150,
    StuckTime = 1.2,
    ClimbMax = 30,
    BoxSize = Vector3.new(2.5, 3, 2.5),
    BoxLift = 0,
    Baskets = {
        "Candy Corn Basket",
        "Pumpkin Basket",
        "Pumpkin Bag",
    },
    EquippedBasket = nil,
    BuyItems = {},
    BuyBlockedUntil = 0,
    AgentProfiles = {
        { AgentRadius = 2, AgentHeight = 5, AgentCanJump = true, WaypointSpacing = 4 },
        { AgentRadius = 1.5, AgentHeight = 5, AgentCanJump = true, WaypointSpacing = 4 },
        { AgentRadius = 1, AgentHeight = 4, AgentCanJump = true, WaypointSpacing = 4 },
    },
    ShopItems = {
        { "SP Reset Essence", 10 },
        { "Dark Root", 25 },
        { "Race Reroll x5", 25 },
        { "Lantern", 50 },
        { "Spirit Color Essence", 50 },
        { "Ghost Face Costume", 100 },
        { "Joker Costume", 100 },
        { "Legendary Fruit Chest Blueprint", 100 },
        { "Mummy Wrappings", 100 },
        { "Plague Doctor Costume", 100 },
        { "Pumpkin Basket", 100 },
        { "Trading Sign", 100 },
        { "Devil Fruit Journal", 125 },
        { "Frankenstein Costume", 175 },
        { "Shark Costume", 175 },
        { "Wizard Costume", 175 },
        { "Candy Corn Basket", 250 },
        { "Rare Fruit Chest", 250 },
        { "Spare Fruit Bag", 250 },
        { "Blood Scythe", 500 },
        { "Tung Sahur Costume", 500 },
    },
}

function HalloweenFarm.GetCandy()
    local Folder = Services.ReplicatedStorage:FindFirstChild("Stats" .. Player.Object.Name)
    local Inventory = Folder and Folder:FindFirstChild("Inventory")
    local Candy = Inventory and Inventory:FindFirstChild("Halloween26Candy")
    return Candy and Candy.Value or nil
end

function HalloweenFarm.GetBuilding()
    local Islands = Services.Workspace:FindFirstChild("Islands")
    local Spooksville = Islands and Islands:FindFirstChild("Spooksville")
    return Spooksville and Spooksville:FindFirstChild("Building")
end

function HalloweenFarm.GetDoor(House)
    local EventDoor = House and House:FindFirstChild("eventDoor")
    local Frame = EventDoor and EventDoor:FindFirstChild("Frame")
    local Prompt = Frame and Frame:FindFirstChildOfClass("ProximityPrompt")
    if Frame and Frame:IsA("BasePart") and Prompt and Prompt.Enabled then
        return Frame
    end
    return nil
end

function HalloweenFarm.GetKey(House)
    local Position

    if House:IsA("PVInstance") then
        local Ok, Pivot = pcall(function()
            return House:GetPivot().Position
        end)
        if Ok then
            Position = Pivot
        end
    end

    if not Position then
        local Part = House:FindFirstChildWhichIsA("BasePart", true)
        Position = Part and Part.Position
    end

    if not Position then
        return House.Name
    end

    return string.format("%s:%d:%d:%d", House.Name, math.floor(Position.X + 0.5), math.floor(Position.Y + 0.5), math.floor(Position.Z + 0.5))
end

function HalloweenFarm.GetCooldown(House)
    return HalloweenFarm.CooldownUntil[HalloweenFarm.GetKey(House)] or 0
end

function HalloweenFarm.SetCooldown(House, Seconds)
    HalloweenFarm.CooldownUntil[HalloweenFarm.GetKey(House)] = os.clock() + Seconds
end

function HalloweenFarm.FadeIn(Highlight)
    pcall(function()
        Services.TweenService:Create(Highlight, TweenInfo.new(HalloweenFarm.FadeTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            FillTransparency = 0.5,
            OutlineTransparency = 0,
        }):Play()
    end)
end

function HalloweenFarm.RemoveHighlight(House, Immediate)
    local Highlight = HalloweenFarm.Highlights[House]
    HalloweenFarm.Highlights[House] = nil

    if not Highlight then
        return
    end

    if Immediate or not Highlight.Parent then
        pcall(function()
            Highlight:Destroy()
        end)
        return
    end

    pcall(function()
        local Tween = Services.TweenService:Create(Highlight, TweenInfo.new(HalloweenFarm.FadeTime, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            FillTransparency = 1,
            OutlineTransparency = 1,
        })

        Tween.Completed:Once(function()
            pcall(function()
                Highlight:Destroy()
            end)
        end)

        Tween:Play()
    end)

    task.delay(HalloweenFarm.FadeTime + 1, function()
        pcall(function()
            Highlight:Destroy()
        end)
    end)
end

function HalloweenFarm.ClearHighlights(Immediate)
    for House in pairs(HalloweenFarm.Highlights) do
        pcall(HalloweenFarm.RemoveHighlight, House, Immediate)
    end
end

function HalloweenFarm.UpdateHighlights()
    if not HalloweenFarm.Enabled then
        HalloweenFarm.ClearHighlights()
        return
    end

    local Building = HalloweenFarm.GetBuilding()
    if not Building then
        HalloweenFarm.ClearHighlights(true)
        return
    end

    local Now = os.clock()

    for House, Highlight in pairs(HalloweenFarm.Highlights) do
        if not House.Parent or not Highlight.Parent then
            HalloweenFarm.RemoveHighlight(House, true)
        elseif HalloweenFarm.GetCooldown(House) <= Now then
            HalloweenFarm.RemoveHighlight(House)
        end
    end

    for _, House in ipairs(Building:GetChildren()) do
        if not HalloweenFarm.Highlights[House] and HalloweenFarm.GetCooldown(House) > Now then
            local Ok, Highlight = pcall(function()
                local Created = Instance.new("Highlight")
                Created.Name = "MeowCooldown"
                Created.Adornee = House
                Created.FillColor = Color3.fromRGB(255, 0, 0)
                Created.OutlineColor = Color3.fromRGB(255, 70, 70)
                Created.FillTransparency = 1
                Created.OutlineTransparency = 1
                Created.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                Created.Parent = House
                return Created
            end)

            if Ok and Highlight then
                HalloweenFarm.Highlights[House] = Highlight
                HalloweenFarm.FadeIn(Highlight)
            end
        end
    end
end

function HalloweenFarm.EquipBasket()
    local Humanoid = Utils.GetHumanoid()
    if not Humanoid then
        return nil
    end

    local Character = Player.Object.Character
    local Backpack = Player.Object:FindFirstChildOfClass("Backpack")

    for _, Name in ipairs(HalloweenFarm.Baskets) do
        local Tool = (Backpack and Backpack:FindFirstChild(Name)) or (Character and Character:FindFirstChild(Name))
        if Tool then
            if Tool.Parent ~= Character then
                pcall(function()
                    Humanoid:EquipTool(Tool)
                end)
            end
            HalloweenFarm.EquippedBasket = Name
            return Name
        end
    end

    return nil
end

function HalloweenFarm.GetWitch()
    local Npcs = Services.Workspace:FindFirstChild("NPCs")
    return Npcs and Npcs:FindFirstChild("Witch of Halloween")
end

function HalloweenFarm.GetCapacity()
    local Name = HalloweenFarm.EquippedBasket
    if not Name then
        return nil
    end

    local Modules = Services.ReplicatedStorage:FindFirstChild("Modules")
    if not Modules or not Modules:FindFirstChild("ToolDesc") then
        return nil
    end

    local Ok, Desc = pcall(function()
        return require(Modules.ToolDesc)
    end)

    if Ok and type(Desc) == "table" and type(Desc[Name]) == "table" then
        return Desc[Name].MaxCandy
    end

    return nil
end

function HalloweenFarm.GetTarget()
    local Building = HalloweenFarm.GetBuilding()
    if not Building then
        return nil
    end

    local Root = Utils.GetRoot()
    local Origin = Root and Root.Position
    local Now = os.clock()
    local Available = {}

    for _, House in ipairs(Building:GetChildren()) do
        local Door = HalloweenFarm.GetDoor(House)
        if Door and HalloweenFarm.GetCooldown(House) <= Now then
            local Distance = 0

            if Origin then
                Distance = Vector3.new(Door.Position.X - Origin.X, 0, Door.Position.Z - Origin.Z).Magnitude
            end

            Available[#Available + 1] = { House = House, Door = Door, Distance = Distance }
        end
    end

    if #Available == 0 then
        return nil
    end

    local Fresh = {}
    for _, Entry in ipairs(Available) do
        if not table.find(HalloweenFarm.Recent, Entry.House) then
            Fresh[#Fresh + 1] = Entry
        end
    end

    if #Fresh > 0 then
        Available = Fresh
    end

    local Spread = {}
    for _, Entry in ipairs(Available) do
        if Entry.Distance >= HalloweenFarm.MinHouseDistance then
            Spread[#Spread + 1] = Entry
        end
    end

    if #Spread > 0 then
        Available = Spread
    end

    table.sort(Available, function(A, B)
        return A.Distance < B.Distance
    end)

    local Pool = math.min(#Available, HalloweenFarm.PickPool)
    local Total = 0

    for Rank = 1, Pool do
        Total = Total + 1 / Rank
    end

    local Roll = math.random() * Total

    for Rank = 1, Pool do
        Roll = Roll - 1 / Rank
        if Roll <= 0 then
            return Available[Rank]
        end
    end

    return Available[Pool]
end

function HalloweenFarm.Remember(House)
    table.insert(HalloweenFarm.Recent, House)

    while #HalloweenFarm.Recent > HalloweenFarm.RecentLimit do
        table.remove(HalloweenFarm.Recent, 1)
    end
end

function HalloweenFarm.GetFront(Door)
    local Front = Door.CFrame.LookVector
    Front = Vector3.new(Front.X, 0, Front.Z)
    if Front.Magnitude > 0 then
        return Front.Unit
    end
    return Vector3.new(0, 0, 1)
end

function HalloweenFarm.IsAlive()
    local Root = Utils.GetRoot()
    local Humanoid = Utils.GetHumanoid()
    return Root ~= nil and Root.Parent ~= nil and Humanoid ~= nil and Humanoid.Health > 0
end

function HalloweenFarm.GetRayParams()
    local Ignore = {}

    if Player.Object.Character then
        Ignore[#Ignore + 1] = Player.Object.Character
    end

    local Npcs = Services.Workspace:FindFirstChild("NPCs")
    if Npcs then
        Ignore[#Ignore + 1] = Npcs
    end

    for _, Highlight in pairs(HalloweenFarm.Highlights) do
        Ignore[#Ignore + 1] = Highlight
    end

    local Params = RaycastParams.new()
    Params.FilterType = Enum.RaycastFilterType.Exclude
    Params.FilterDescendantsInstances = Ignore
    Params.RespectCanCollide = true
    return Params
end

function HalloweenFarm.GetHeightOffset()
    local Root = Utils.GetRoot()
    local Humanoid = Utils.GetHumanoid()
    if not Root or not Humanoid then
        return Vector3.new(0, 3, 0)
    end
    return Vector3.new(0, Humanoid.HipHeight + Root.Size.Y / 2, 0)
end

function HalloweenFarm.BeginHover()
    local Humanoid = Utils.GetHumanoid()
    if Humanoid then
        Humanoid.PlatformStand = true
    end
end

function HalloweenFarm.EndHover()
    local Humanoid = Utils.GetHumanoid()
    if Humanoid then
        Humanoid.PlatformStand = Movement.Fly or (HalloweenFarm.Enabled and HalloweenFarm.GetBuilding() ~= nil)
    end

    local Root = Utils.GetRoot()
    if Root then
        Root.AssemblyLinearVelocity = Vector3.zero
    end
end

function HalloweenFarm.GroundAt(Position, Params, Lift)
    local Result = Services.Workspace:Raycast(
        Vector3.new(Position.X, Position.Y + (Lift or 1), Position.Z),
        Vector3.new(0, -500, 0),
        Params
    )
    return Result and Result.Position or nil
end

function HalloweenFarm.HoverStep()
    if not HalloweenFarm.Enabled then
        HalloweenFarm.StopHover()
        return
    end

    if HalloweenFarm.Moving or not HalloweenFarm.IsAlive() then
        return
    end

    local Root = Utils.GetRoot()
    local Humanoid = Utils.GetHumanoid()

    if not HalloweenFarm.GetBuilding() then
        if Humanoid.PlatformStand and not Movement.Fly then
            Humanoid.PlatformStand = false
        end
        return
    end

    Humanoid.PlatformStand = true
    Root.AssemblyLinearVelocity = Vector3.zero
    Root.AssemblyAngularVelocity = Vector3.zero

    local Ground = HalloweenFarm.GroundAt(Root.Position, HalloweenFarm.GetRayParams())
    if not Ground then
        return
    end

    local Wanted = Ground.Y + HalloweenFarm.HoverHeight + HalloweenFarm.GetHeightOffset().Y
    local Position = Root.Position

    if math.abs(Wanted - Position.Y) > 0.05 then
        Root.CFrame = CFrame.new(Position.X, Wanted, Position.Z) * (Root.CFrame - Root.CFrame.Position)
    end
end

function HalloweenFarm.StartHover()
    if HalloweenFarm.HoverConnection then
        return
    end

    HalloweenFarm.HoverConnection = Services.RunService.Heartbeat:Connect(function()
        local Ok, Err = pcall(HalloweenFarm.HoverStep)
        if not Ok then
            warn("Hover:", Err)
        end
    end)
end

function HalloweenFarm.StopHover()
    if HalloweenFarm.HoverConnection then
        pcall(function()
            HalloweenFarm.HoverConnection:Disconnect()
        end)
        HalloweenFarm.HoverConnection = nil
    end

    HalloweenFarm.Moving = false
    pcall(HalloweenFarm.EndHover)
end

function HalloweenFarm.GetGround(Position)
    return HalloweenFarm.GroundAt(Position, HalloweenFarm.GetRayParams(), 6) or Position
end

function HalloweenFarm.IsBlocked(From, To, Params)
    local Direction = To - From
    if Direction.Magnitude < 0.01 then
        return false
    end

    local Result = Services.Workspace:Blockcast(
        CFrame.new(From + Vector3.new(0, HalloweenFarm.BoxLift, 0)),
        HalloweenFarm.BoxSize,
        Direction,
        Params
    )

    return Result ~= nil and Result.Distance > 0.05
end

function HalloweenFarm.SamplePath(FromGround, ToGround, Params)
    local Offset = HalloweenFarm.GetHeightOffset() + Vector3.new(0, HalloweenFarm.HoverHeight, 0)
    local Flat = Vector3.new(ToGround.X - FromGround.X, 0, ToGround.Z - FromGround.Z)
    local Steps = math.max(1, math.ceil(Flat.Magnitude / 3))
    local Previous = FromGround + Offset

    for I = 1, Steps do
        local Alpha = I / Steps
        local Probe = Vector3.new(FromGround.X + Flat.X * Alpha, Previous.Y, FromGround.Z + Flat.Z * Alpha)
        local Ground = HalloweenFarm.GroundAt(Probe, Params)

        if not Ground then
            return false
        end

        local Next = Ground + Offset

        if Next.Y - Previous.Y > HalloweenFarm.MaxStep then
            return false
        end

        if HalloweenFarm.IsBlocked(Previous, Next, Params) then
            return false
        end

        Previous = Next
    end

    return true
end

function HalloweenFarm.Smooth(Points)
    local Root = Utils.GetRoot()
    if not Root then
        return Points
    end

    local Params = HalloweenFarm.GetRayParams()
    local Result = {}
    local Current = HalloweenFarm.GroundAt(Root.Position, Params) or (Root.Position - HalloweenFarm.GetHeightOffset())
    local Index = 1

    while Index <= #Points do
        local Far = Index

        for I = math.min(#Points, Index + HalloweenFarm.MaxLookahead), Index + 1, -1 do
            local Ok, Clear = pcall(HalloweenFarm.SamplePath, Current, Points[I], Params)
            if Ok and Clear then
                Far = I
                break
            end
        end

        Result[#Result + 1] = Points[Far]
        Current = Points[Far]
        Index = Far + 1
    end

    return Result
end

function HalloweenFarm.ComputeWaypoints(Goal, Start)
    local Root = Utils.GetRoot()
    if not Root then
        return nil
    end

    Start = Start or HalloweenFarm.GroundAt(Root.Position, HalloweenFarm.GetRayParams()) or Root.Position

    for _, Profile in ipairs(HalloweenFarm.AgentProfiles) do
        local Ok, Points = pcall(function()
            local Path = Services.PathfindingService:CreatePath(Profile)
            Path:ComputeAsync(Start, Goal)

            if Path.Status ~= Enum.PathStatus.Success then
                return nil
            end

            local Result = {}
            for _, Waypoint in ipairs(Path:GetWaypoints()) do
                Result[#Result + 1] = Waypoint.Position
            end
            return Result
        end)

        if Ok and Points and #Points > 0 then
            return Points
        end
    end

    return nil
end

function HalloweenFarm.MoveToInner(Target, StopDistance)
    StopDistance = StopDistance or 1

    local Deadline = os.clock() + 25
    local Params = HalloweenFarm.GetRayParams()
    local Offset = HalloweenFarm.GetHeightOffset()
    local BestDistance = math.huge
    local LastProgress = os.clock()
    local ClimbStartY = nil

    while HalloweenFarm.Enabled and HalloweenFarm.IsAlive() and os.clock() < Deadline do
        local Dt = Services.RunService.Heartbeat:Wait()

        local Root = Utils.GetRoot()
        if not Root then
            return false, "lost"
        end

        local Position = Root.Position
        local Flat = Vector3.new(Target.X - Position.X, 0, Target.Z - Position.Z)
        local Distance = Flat.Magnitude

        if Distance <= StopDistance then
            Root.AssemblyLinearVelocity = Vector3.zero
            return true
        end

        if Distance < BestDistance - 0.5 then
            BestDistance = Distance
            LastProgress = os.clock()
        elseif os.clock() - LastProgress > HalloweenFarm.StuckTime then
            return false, "blocked"
        end

        local Step = math.min(Distance, HalloweenFarm.Speed * Dt)

        local function Try(Direction)
            if Direction.Magnitude < 0.05 then
                return nil
            end

            local Flat3 = Vector3.new(Direction.X, 0, Direction.Z).Unit
            local Next = Position + Flat3 * Step
            local Ground = HalloweenFarm.GroundAt(Next, Params)

            if not Ground then
                return nil
            end

            local Wanted = Ground.Y + HalloweenFarm.HoverHeight + Offset.Y
            local Delta = Wanted - Position.Y

            if Delta > HalloweenFarm.MaxStep then
                return nil
            end

            local MaxMove = HalloweenFarm.VerticalSpeed * Dt
            local NewY = Position.Y + math.clamp(Delta, -MaxMove, MaxMove)
            local NewPosition = Vector3.new(Next.X, NewY, Next.Z)

            if HalloweenFarm.IsBlocked(Position, NewPosition, Params) then
                return nil
            end

            return NewPosition
        end

        local NewPosition = Try(Flat)
            or Try(Vector3.new(Flat.X, 0, 0))
            or Try(Vector3.new(0, 0, Flat.Z))

        if NewPosition then
            ClimbStartY = nil
            Root.CFrame = CFrame.lookAt(NewPosition, NewPosition + Flat)
        else
            local MaxMove = HalloweenFarm.VerticalSpeed * Dt
            ClimbStartY = ClimbStartY or Position.Y

            local Up = Position + Vector3.new(0, MaxMove, 0)
            local CanClimb = Position.Y - ClimbStartY < HalloweenFarm.ClimbMax
                and not HalloweenFarm.IsBlocked(Position, Up, Params)

            if CanClimb then
                Root.CFrame = CFrame.new(Up) * (Root.CFrame - Root.CFrame.Position)
            else
                local Ground = HalloweenFarm.GroundAt(Position, Params)
                if Ground then
                    local Wanted = Ground.Y + HalloweenFarm.HoverHeight + Offset.Y
                    local NewY = Position.Y + math.clamp(Wanted - Position.Y, -MaxMove, MaxMove)
                    Root.CFrame = CFrame.new(Position.X, NewY, Position.Z) * (Root.CFrame - Root.CFrame.Position)
                end
            end
        end

        Root.AssemblyLinearVelocity = Vector3.zero
    end

    return false, "stopped"
end

function HalloweenFarm.MoveTo(Target, StopDistance)
    HalloweenFarm.Moving = true

    local Success, Ok, Reason = pcall(HalloweenFarm.MoveToInner, Target, StopDistance)

    HalloweenFarm.Moving = false

    if not Success then
        warn("MoveTo:", Ok)
        return false, "stopped"
    end

    return Ok, Reason
end

function HalloweenFarm.PathLoop(GroundGoal, StopDistance)
    for Attempt = 1, HalloweenFarm.MaxPathAttempts do
        if not HalloweenFarm.Enabled or not HalloweenFarm.IsAlive() then
            return false
        end

        local Root = Utils.GetRoot()
        if not Root then
            return false
        end

        local Here = Vector3.new(GroundGoal.X - Root.Position.X, 0, GroundGoal.Z - Root.Position.Z)
        if Here.Magnitude <= StopDistance then
            return true
        end

        local Raw = HalloweenFarm.ComputeWaypoints(GroundGoal)
        local Points

        if Raw then
            local Ok, Smoothed = pcall(HalloweenFarm.Smooth, Raw)
            Points = (Ok and Smoothed) or Raw
        else
            Points = { GroundGoal }
        end

        local Arrived = true

        for Index, Point in ipairs(Points) do
            local Stop = (Index == #Points) and StopDistance or 1.5
            local Ok, Reason = HalloweenFarm.MoveTo(Point, Stop)

            if not Ok then
                Arrived = false
                if Reason ~= "blocked" then
                    return false
                end
                break
            end
        end

        if Arrived then
            return true
        end

        task.wait(0.1 * Attempt)
    end

    return false
end

function HalloweenFarm.PathTo(Goal, StopDistance)
    StopDistance = StopDistance or 5

    local Result = false

    pcall(HalloweenFarm.BeginHover)

    local Ok, Error = pcall(function()
        local GroundGoal = HalloweenFarm.GetGround(Goal)
        Result = HalloweenFarm.PathLoop(GroundGoal, StopDistance)
    end)

    pcall(HalloweenFarm.EndHover)

    if not Ok then
        warn("PathTo:", Error)
        return false
    end

    return Result
end

function HalloweenFarm.WalkTo(Door)
    local Goal = Door.Position + HalloweenFarm.GetFront(Door) * 4
    HalloweenFarm.PathTo(Goal, 3.5)

    local Root = Utils.GetRoot()
    if not Root then
        return false
    end

    local Flat = Vector3.new(Door.Position.X - Root.Position.X, 0, Door.Position.Z - Root.Position.Z)
    return Flat.Magnitude <= 9 and math.abs(Door.Position.Y - Root.Position.Y) <= 15
end

function HalloweenFarm.Buy()
    local Remote = Services.ReplicatedStorage:FindFirstChild("HalloweenShopRemote")
    if not Remote then
        return {}
    end

    local Bought = {}

    for Name, Price in pairs(HalloweenFarm.BuyItems) do
        for _ = 1, 50 do
            local Candy = HalloweenFarm.GetCandy()
            if not Candy or Candy < Price then
                break
            end

            local Before = Candy

            local Ok = pcall(function()
                return Remote:InvokeServer(Name)
            end)

            task.wait(0.35)

            local After = HalloweenFarm.GetCandy() or Before

            if Ok and After < Before then
                Bought[#Bought + 1] = Name
                pcall(CandyWebhook.SendPurchase, Name, Before - After, After)
                task.wait(0.25)
            elseif Ok then
                pcall(function()
                    Remote:InvokeServer(Name)
                end)
                task.wait(0.4)
                After = HalloweenFarm.GetCandy() or Before
                if After < Before then
                    Bought[#Bought + 1] = Name
                    pcall(CandyWebhook.SendPurchase, Name, Before - After, After)
                else
                    break
                end
            else
                break
            end
        end
    end

    return Bought
end

function HalloweenFarm.Purchase()
    local Witch = HalloweenFarm.GetWitch()
    local Part = Witch and (Witch:FindFirstChild("HumanoidRootPart") or Witch.PrimaryPart)

    if not Part then
        HalloweenFarm.BuyBlockedUntil = os.clock() + 12
        return
    end

    HalloweenFarm.PathTo(Part.Position, 5)

    local Root = Utils.GetRoot()
    if Root then
        local Flat = Vector3.new(Part.Position.X - Root.Position.X, 0, Part.Position.Z - Root.Position.Z)
        if Flat.Magnitude > 4 then
            HalloweenFarm.PathTo(Part.Position, 3.5)
        end
        Root.AssemblyLinearVelocity = Vector3.zero
        task.wait(0.6)
    end

    local Bought = HalloweenFarm.Buy()

    if #Bought > 0 then
        Utils.Notify("Bought: " .. table.concat(Bought, ", ") .. ".")
        HalloweenFarm.BuyBlockedUntil = 0
    else
        HalloweenFarm.BuyBlockedUntil = os.clock() + 12
        Utils.Notify("Failed to buy items.")
    end
end

function HalloweenFarm.ShouldBuy()
    if next(HalloweenFarm.BuyItems) == nil then
        return false
    end

    if os.clock() < HalloweenFarm.BuyBlockedUntil then
        return false
    end

    local Candy = HalloweenFarm.GetCandy()
    if not Candy then
        return false
    end

    local Capacity = HalloweenFarm.GetCapacity() or HalloweenFarm.MaxCandy

    if HalloweenFarm.OnlyBuyAtMax then
        return Candy >= Capacity
    end

    for _, Price in pairs(HalloweenFarm.BuyItems) do
        if Candy >= Price then
            return true
        end
    end

    return Candy >= Capacity
end

function HalloweenFarm.Knock(Target)
    local Prompt = Target.Door:FindFirstChildOfClass("ProximityPrompt")
    if not Prompt then
        return false
    end

    local FirePrompt = fireproximityprompt or (getgenv and getgenv().fireproximityprompt)
    if typeof(FirePrompt) ~= "function" then
        return false
    end

    local Ok = pcall(function()
        FirePrompt(Prompt)
    end)

    if Ok then
        HalloweenFarm.SetCooldown(Target.House, HalloweenFarm.Cooldown)

        local Until = os.clock() + HalloweenFarm.PostKnockDelay
        while HalloweenFarm.Enabled and os.clock() < Until do
            task.wait(0.1)
        end
    end

    return Ok
end

function HalloweenFarm.Tick()
    if HalloweenFarm.Busy or not HalloweenFarm.IsAlive() then
        return
    end

    if not HalloweenFarm.GetBuilding() then
        return
    end

    if not HalloweenFarm.EquipBasket() then
        Utils.Notify("No candy basket found.")
        HalloweenFarm.SetEnabled(false)
        Utils.ResetToggle("CandyFarmToggle")
        return
    end

    local Session = HalloweenFarm.Session

    if HalloweenFarm.ShouldBuy() then
        HalloweenFarm.Busy = true
        task.spawn(function()
            local Ok, Err = pcall(HalloweenFarm.Purchase)
            if not Ok then
                warn("Purchase:", Err)
                HalloweenFarm.BuyBlockedUntil = os.clock() + 12
            end
            if HalloweenFarm.Session == Session then
                HalloweenFarm.Busy = false
            end
        end)
        return
    end

    local Target = HalloweenFarm.GetTarget()
    if not Target then
        return
    end

    HalloweenFarm.Busy = true
    HalloweenFarm.LastHouse = Target.House
    HalloweenFarm.Remember(Target.House)

    task.spawn(function()
        local Ok, Reached = pcall(HalloweenFarm.WalkTo, Target.Door)

        if HalloweenFarm.Session ~= Session or not HalloweenFarm.Enabled then
            return
        end

        pcall(function()
            if Ok and Reached and HalloweenFarm.GetCooldown(Target.House) <= os.clock() then
                HalloweenFarm.EquipBasket()
                if not HalloweenFarm.Knock(Target) then
                    HalloweenFarm.SetCooldown(Target.House, HalloweenFarm.RetryDelay)
                end
            elseif not Ok or not Reached then
                HalloweenFarm.SetCooldown(Target.House, HalloweenFarm.RetryDelay)
            end
        end)

        if HalloweenFarm.Session == Session then
            HalloweenFarm.Busy = false
        end
    end)
end

function HalloweenFarm.SetBuyItems(Selected)
    table.clear(HalloweenFarm.BuyItems)

    if type(Selected) ~= "table" then
        return
    end

    local IsArray = #Selected > 0

    for _, Entry in ipairs(HalloweenFarm.ShopItems) do
        local Label = Entry[1] .. " (" .. Entry[2] .. ")"

        if Selected[Label] or (IsArray and table.find(Selected, Label)) then
            HalloweenFarm.BuyItems[Entry[1]] = Entry[2]
        end
    end

    HalloweenFarm.BuyBlockedUntil = 0
end

function HalloweenFarm.GetShopLabels()
    local Labels = {}
    for _, Entry in ipairs(HalloweenFarm.ShopItems) do
        Labels[#Labels + 1] = Entry[1] .. " (" .. Entry[2] .. ")"
    end
    return Labels
end

function HalloweenFarm.SetEnabled(Value)
    if Value == HalloweenFarm.Enabled and not Value then
        return
    end

    HalloweenFarm.Enabled = Value
    HalloweenFarm.Busy = false
    HalloweenFarm.Session = HalloweenFarm.Session + 1

    if not Value then
        HalloweenFarm.StopHover()
        HalloweenFarm.ClearHighlights()
        HalloweenFarm.BuyBlockedUntil = 0
        Utils.NotifyToggle("Candy Farm", false)
        return
    end

    HalloweenFarm.BuyBlockedUntil = 0

    if not HalloweenFarm.GetBuilding() then
        HalloweenFarm.Enabled = false
        Utils.Notify("Candy Farm island not found.")
        Utils.ResetToggle("CandyFarmToggle")
        return
    end

    if not HalloweenFarm.EquipBasket() then
        HalloweenFarm.Enabled = false
        Utils.Notify("No candy basket found.")
        Utils.ResetToggle("CandyFarmToggle")
        return
    end

    HalloweenFarm.StartHover()
    Utils.NotifyToggle("Candy Farm", true)
end

function Webhook.GetPity()
    local Folder = Services.ReplicatedStorage:FindFirstChild("Stats" .. Player.Object.Name)
    local Stats = Folder and Folder:FindFirstChild("Stats")
    local Pity = Stats and Stats:FindFirstChild("FruitPity")

    if Pity and Pity:IsA("IntValue") then
        return tostring(Pity.Value)
    end

    return "Unknown"
end

function Webhook.Send(FruitName)
    if not Webhook.Enabled or Webhook.Url == "" then
        return
    end

    Utils.Post(Webhook.Url, {
        username = "Meow",
        embeds = {
            {
                title = "Fruit Stored",
                description = "A fruit was sent to the fruit storage.",
                color = 0x5865F2,
                fields = {
                    { name = "Fruit", value = tostring(FruitName), inline = true },
                    { name = "Fruit Pity", value = Webhook.GetPity(), inline = true },
                    { name = "Player", value = Player.Object.Name, inline = true },
                },
                footer = { text = "Meow" },
                timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
            },
        },
    })
end

function Webhook.GetInventory()
    local Folder = Services.ReplicatedStorage:FindFirstChild("Stats" .. Player.Object.Name)
    local InventoryFolder = Folder and Folder:FindFirstChild("Inventory")
    local Inventory = InventoryFolder and InventoryFolder:FindFirstChild("Inventory")

    if not Inventory or not Inventory:IsA("StringValue") then
        return nil
    end

    local Success, Decoded = pcall(function()
        return Services.HttpService:JSONDecode(Inventory.Value)
    end)

    if not Success or type(Decoded) ~= "table" then
        return nil
    end

    return Decoded
end

function Webhook.SendDrop(ItemName)
    if not Webhook.Enabled or Webhook.Url == "" then
        return
    end

    Utils.Post(Webhook.Url, {
        username = "Meow",
        embeds = {
            {
                title = "Rare Drop Obtained",
                description = "**" .. tostring(ItemName) .. "** was obtained!",
                color = 0x9B59B6,
                fields = {
                    { name = "Drop", value = tostring(ItemName), inline = true },
                    { name = "Player", value = Player.Object.Name, inline = true },
                },
                footer = { text = "Meow" },
                timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
            },
        },
    })
end

function Webhook.CheckDrops()
    local Inventory = Webhook.GetInventory()
    if not Inventory then
        return
    end

    for Name in pairs(Inventory) do
        local Key = tostring(Name):lower()

        if Webhook.Drops[Key] and not Webhook.KnownDrops[Key] then
            Webhook.KnownDrops[Key] = true

            if Webhook.DropInitialized then
                Webhook.SendDrop(Name)
            end
        end
    end

    Webhook.DropInitialized = true
end

function CandyWebhook.Send(CandyAmount)
    if not CandyWebhook.Enabled or CandyWebhook.Url == "" then
        return
    end

    Utils.Post(CandyWebhook.Url, {
        username = "Meow",
        embeds = {
            {
                title = "Candy Updated",
                description = "Your candy amount has changed.",
                color = 0xF39C12,
                fields = {
                    { name = "Candy", value = tostring(CandyAmount), inline = true },
                    { name = "Player", value = Player.Object.Name, inline = true },
                },
                footer = { text = "Meow" },
                timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
            },
        },
    })
end

function CandyWebhook.SendPurchase(ItemName, Spent, Remaining)
    if not CandyWebhook.Enabled or CandyWebhook.Url == "" then
        return
    end

    Utils.Post(CandyWebhook.Url, {
        username = "Meow",
        embeds = {
            {
                title = "Item Purchased",
                description = "Successfully bought an item from the Halloween shop.",
                color = 0x2ECC71,
                fields = {
                    { name = "Item", value = tostring(ItemName), inline = true },
                    { name = "Spent", value = tostring(Spent), inline = true },
                    { name = "Remaining Candy", value = tostring(Remaining), inline = true },
                    { name = "Player", value = Player.Object.Name, inline = true },
                },
                footer = { text = "Meow" },
                timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
            },
        },
    })
end

function CandyWebhook.Check()
    local Candy = HalloweenFarm.GetCandy()
    if Candy == nil then
        return
    end

    if CandyWebhook.LastCandy == nil then
        CandyWebhook.LastCandy = Candy
        return
    end

    if Candy ~= CandyWebhook.LastCandy then
        CandyWebhook.LastCandy = Candy
        CandyWebhook.Send(Candy)
    end
end

function AutoSellFish.GetFishes()
    if not AutoSellFish.Utils then
        local Ok, Result = pcall(function()
            return require(Services.ReplicatedStorage.Modules.ToolDesc.ToolDescUtils)
        end)

        if not Ok or type(Result) ~= "table" then
            return {}
        end

        AutoSellFish.Utils = Result
    end

    local ByRarity = {
        ["Common Fish"] = {},
        ["Rare Fish"] = {},
        ["Legendary Fish"] = {},
    }

    local Ok, All = pcall(function()
        return AutoSellFish.Utils.GetAllFishes()
    end)

    if Ok and type(All) == "table" then
        for Name, Data in pairs(All) do
            local List = type(Data) == "table" and ByRarity[Data.BaseItem]
            if List then
                table.insert(List, Name)
            end
        end
    end

    return ByRarity
end

function AutoSellFish.SellRarity(Remote, Fishes)
    if type(Fishes) ~= "table" then
        return
    end

    for _, FishName in ipairs(Fishes) do
        pcall(function()
            Remote:InvokeServer({
                Fish = FishName,
                All = true,
                Method = "SellFish",
            })
        end)
        task.wait(0.04)
    end
end

function AutoSellFish.Sell()
    if AutoSellFish.Busy or typeof(AutoSellFish.SelectedRarity) ~= "table" then
        return
    end

    local Rarities = {}
    for Rarity, IsSelected in pairs(AutoSellFish.SelectedRarity) do
        if IsSelected then
            table.insert(Rarities, Rarity)
        end
    end

    if #Rarities == 0 then
        return
    end

    local Remote = Services.ReplicatedStorage:FindFirstChild("FishingShopRemote")
    if not Remote then
        return
    end

    AutoSellFish.Busy = true

    pcall(function()
        local Fishes = AutoSellFish.GetFishes()
        for _, Rarity in ipairs(Rarities) do
            AutoSellFish.SellRarity(Remote, Fishes[Rarity])
        end
    end)

    AutoSellFish.Busy = false
end

function AutoBuyBait.GetNearest()
    local Folder = Services.Workspace:FindFirstChild("BuyableItems")
    local Root = Utils.GetRoot()

    if not Folder or not Root then
        return nil
    end

    local Nearest
    local NearestDistance = math.huge

    for _, Item in ipairs(Folder:GetChildren()) do
        if Item.Name == "Common Fish Bait" then
            local TargetPart

            if Item:IsA("BasePart") then
                TargetPart = Item
            elseif Item:IsA("Model") then
                TargetPart = Item.PrimaryPart or Item:FindFirstChildWhichIsA("BasePart", true)
            end

            if TargetPart then
                local Distance = (Root.Position - TargetPart.Position).Magnitude
                if Distance < NearestDistance then
                    NearestDistance = Distance
                    Nearest = Item
                end
            end
        end
    end

    return Nearest
end

function AutoBuyBait.Buy()
    if AutoBuyBait.Busy then
        return
    end

    local Events = Services.ReplicatedStorage:FindFirstChild("Events")
    local Remote = Events and Events:FindFirstChild("Shop")

    if not Remote or not Remote:IsA("RemoteFunction") then
        return
    end

    local Bait = AutoBuyBait.GetNearest()
    if not Bait then
        return
    end

    AutoBuyBait.Busy = true

    local Success, Result = pcall(function()
        return Remote:InvokeServer(Bait, AutoBuyBait.Amount)
    end)

    AutoBuyBait.Busy = false

    if not Success then
        warn("Auto Buy Bait:", Result)
    end
end

function AutoFish.GetBaitList()
    local Gui = Player.Gui and Player.Gui:FindFirstChild("FishingBaitGui")
    local Main = Gui and Gui:FindFirstChild("Main")
    return Main and Main:FindFirstChild("List")
end

function AutoFish.FindBaitButton(List, Bait)
    local Button = List:FindFirstChild(Bait)

    if Button then
        return Button
    end

    local Needle = string.lower(Bait)
    for _, Child in ipairs(List:GetChildren()) do
        if Child:IsA("GuiButton") and string.find(string.lower(Child.Name), Needle, 1, true) then
            return Child
        end
    end

    return nil
end

function AutoFish.GetBaitCandidates(Bait)
    if not AutoFish.SmartBait then
        return { Bait }
    end

    local Index = table.find(AutoFish.BaitOrder, Bait)
    if not Index then
        return { Bait }
    end

    local Candidates = {}
    for I = Index, 1, -1 do
        table.insert(Candidates, AutoFish.BaitOrder[I])
    end

    return Candidates
end

function AutoFish.SelectBait()
    local Bait = AutoFish.Bait

    if not Bait or Bait == "" or Bait == "None" then
        return true
    end

    local List = AutoFish.GetBaitList()
    if not List then
        return true
    end

    local Button
    local Chosen

    for _, Candidate in ipairs(AutoFish.GetBaitCandidates(Bait)) do
        Button = AutoFish.FindBaitButton(List, Candidate)
        if Button then
            Chosen = Candidate
            break
        end
    end

    if not Button then
        if not AutoFish.BaitWarned then
            AutoFish.BaitWarned = true
            if AutoFish.SmartBait then
                Utils.Notify("No available bait from " .. Bait .. " downwards.")
            else
                Utils.Notify("You don't have the bait: " .. Bait)
            end
        end
        return false
    end

    AutoFish.BaitWarned = false

    if Chosen ~= Bait then
        if AutoFish.LastFallback ~= Chosen then
            AutoFish.LastFallback = Chosen
            Utils.Notify("Using " .. Chosen .. " instead of " .. Bait)
        end
    else
        AutoFish.LastFallback = nil
    end

    local Marker = Button:FindFirstChild("backGroundSelect")
    if Marker and Marker.Visible then
        return true
    end

    pcall(function()
        local FireSignal = firesignal or _G.firesignal
        if typeof(FireSignal) == "function" then
            FireSignal(Button.MouseButton1Click)
        else
            Button.MouseButton1Click:Fire()
        end
    end)

    return true
end

function AutoFish.EnsureMouseCF()
    if _G.MouseCF ~= nil and not AutoFish.UsingFallback then
        return
    end

    local Camera = Services.Workspace.CurrentCamera
    if not Camera then
        return
    end

    local Look = Camera.CFrame.LookVector
    local Goal = Camera.CFrame.Position + Look * 2000
    _G.MouseCF = CFrame.new(Goal, Goal + Look)
    AutoFish.UsingFallback = true
end

function AutoFish.EnsureFishing()
    local Hook = AutoFish.Hook

    if Hook.Module then
        return true
    end

    local Fishing = Services.ReplicatedStorage:FindFirstChild("Fishing")
    local Assets = Fishing and Fishing:FindFirstChild("Assets")
    local ClientScript = Assets and Assets:FindFirstChild("Client")

    if not ClientScript then
        return false
    end

    local Ok, Result = pcall(require, ClientScript)
    if not Ok or typeof(Result) ~= "table" or typeof(Result._fishCaught) ~= "function" then
        return false
    end

    local Remotes = Fishing:FindFirstChild("Remotes")

    Hook.Module = Result
    Hook.Action = Remotes and Remotes:FindFirstChild("Action")
    Hook.Original = Result._fishCaught

    return true
end

function AutoFish.IsRod(Tool)
    return Tool:IsA("Tool") and Tool:GetAttribute("isFishingRod") == true
end

function AutoFish.FindRodIn(Container)
    if not Container then
        return nil
    end

    for _, Child in ipairs(Container:GetChildren()) do
        if AutoFish.IsRod(Child) then
            return Child
        end
    end

    return nil
end

function AutoFish.GetRod()
    local Character = Player.Object.Character
    local Backpack = Player.Object:FindFirstChildOfClass("Backpack")

    local Equipped = AutoFish.FindRodIn(Character)
    if Equipped then
        return Equipped
    end

    local Stored = AutoFish.FindRodIn(Backpack)
    if Stored then
        local Humanoid = Utils.GetHumanoid()
        if Humanoid then
            pcall(function()
                Humanoid:EquipTool(Stored)
            end)
        end
        return Stored
    end

    if Character then
        for _, Child in ipairs(Character:GetChildren()) do
            if Child:IsA("Tool") then
                return Child
            end
        end
    end

    return nil
end

function AutoFish.Cast()
    local Rod = AutoFish.GetRod()

    if not Rod or Rod.Parent ~= Player.Object.Character then
        return false
    end

    pcall(AutoFish.SelectBait)
    pcall(AutoFish.EnsureMouseCF)

    return (pcall(Rod.Activate, Rod))
end

function AutoFish.EnsureFruitStorage()
    if AutoFish.FruitStorage and AutoFish.FruitStorage.Parent then
        return AutoFish.FruitStorage
    end

    local Events = Services.ReplicatedStorage:FindFirstChild("Events")
    local Remote = Events and Events:FindFirstChild("FruitStorage")

    AutoFish.FruitStorage = Remote
    return Remote
end

function AutoFish.IsMinigameRunning()
    return AutoFish.Busy
end

function AutoFish.IsFruit(Tool)
    if not Tool or not Tool:IsA("Tool") then
        return false
    end

    local VerifiedFruit = Tool:GetAttribute("verifiedFruit")
    return VerifiedFruit ~= nil and VerifiedFruit ~= false
end

function AutoFish.FindFruitIn(Container)
    if not Container then
        return nil
    end

    for _, Child in ipairs(Container:GetChildren()) do
        if AutoFish.IsFruit(Child)
            and (AutoFish.FruitAttempts[Child] or 0) < AutoFish.MaxFruitAttempts
            and os.clock() >= (AutoFish.FruitRetryAt[Child] or 0) then
            return Child
        end
    end

    return nil
end

function AutoFish.FindFruit()
    return AutoFish.FindFruitIn(Player.Object:FindFirstChildOfClass("Backpack"))
        or AutoFish.FindFruitIn(Player.Object.Character)
end

function AutoFish.WaitUntil(Condition, Timeout)
    local Deadline = os.clock() + Timeout

    while os.clock() < Deadline do
        local Ok, Result = pcall(Condition)
        if Ok and Result then
            return true
        end
        task.wait(0.05)
    end

    local Ok, Result = pcall(Condition)
    return Ok and Result or false
end

function AutoFish.RunStore(Tool, Remote, Humanoid, Character, Backpack)
    local FruitName = Tool.Name
    local PreviousTool

    for _, Child in ipairs(Character:GetChildren()) do
        if Child:IsA("Tool") and Child ~= Tool then
            PreviousTool = Child
            break
        end
    end

    local function IsHeld()
        return Tool.Parent == Character
    end

    if not IsHeld() then
        pcall(function()
            Humanoid:EquipTool(Tool)
        end)

        if not AutoFish.WaitUntil(IsHeld, 0.8) and Tool.Parent == Backpack then
            pcall(function()
                Humanoid:EquipTool(Tool)
            end)
            AutoFish.WaitUntil(IsHeld, 0.5)
        end
    end

    if IsHeld() then
        pcall(function()
            Remote:InvokeServer(true)
        end)

        if not AutoFish.FruitNotified[Tool] then
            AutoFish.FruitNotified[Tool] = true
            pcall(Webhook.Send, FruitName)
        end

        AutoFish.WaitUntil(function()
            return Tool.Parent ~= Backpack and Tool.Parent ~= Character
        end, 1)
    end

    local CurrentCharacter = Player.Object.Character
    local CurrentHumanoid = Utils.GetHumanoid()
    local CurrentBackpack = Player.Object:FindFirstChildOfClass("Backpack")

    if not CurrentCharacter or not CurrentHumanoid then
        return
    end

    if AutoFish.Enabled then
        local Rod = AutoFish.FindRodIn(CurrentCharacter) or AutoFish.FindRodIn(CurrentBackpack)

        if Rod and Rod.Parent ~= CurrentCharacter then
            pcall(function()
                CurrentHumanoid:EquipTool(Rod)
            end)
        elseif not Rod and PreviousTool and PreviousTool.Parent == CurrentBackpack and AutoFish.IsRod(PreviousTool) then
            pcall(function()
                CurrentHumanoid:EquipTool(PreviousTool)
            end)
        end
    elseif PreviousTool and PreviousTool.Parent == CurrentBackpack and AutoFish.IsRod(PreviousTool) then
        pcall(function()
            CurrentHumanoid:EquipTool(PreviousTool)
        end)
    end
end

function AutoFish.StoreFruitNow(Tool)
    if not AutoFish.StoreFruit or AutoFish.FruitStorageBusy or AutoFish.Busy or not AutoFish.IsFruit(Tool) then
        return
    end

    local Attempts = AutoFish.FruitAttempts[Tool] or 0
    if Attempts >= AutoFish.MaxFruitAttempts or os.clock() < (AutoFish.FruitRetryAt[Tool] or 0) then
        return
    end

    local Character = Player.Object.Character
    local Backpack = Player.Object:FindFirstChildOfClass("Backpack")
    local Humanoid = Utils.GetHumanoid()

    if not Character or not Backpack or not Humanoid then
        return
    end

    if Tool.Parent ~= Backpack and Tool.Parent ~= Character then
        return
    end

    local Remote = AutoFish.EnsureFruitStorage()
    if not Remote or not Remote:IsA("RemoteFunction") then
        return
    end

    AutoFish.FruitAttempts[Tool] = Attempts + 1
    AutoFish.FruitRetryAt[Tool] = os.clock() + AutoFish.FruitRetryDelay
    AutoFish.FruitStorageBusy = true

    local Success, ErrorMessage = pcall(AutoFish.RunStore, Tool, Remote, Humanoid, Character, Backpack)
    if not Success then
        warn("Auto Store Fruit:", ErrorMessage)
    end

    AutoFish.CastPending = false
    AutoFish.NextAction = os.clock() + AutoFish.RecastDelay
    AutoFish.FruitStorageBusy = false
end

function AutoFish.PruneFruit()
    for Tool in pairs(AutoFish.FruitAttempts) do
        if not Tool.Parent then
            AutoFish.FruitAttempts[Tool] = nil
            AutoFish.FruitNotified[Tool] = nil
            AutoFish.FruitRetryAt[Tool] = nil
        end
    end
end

function AutoFish.StoreFruitTick()
    AutoFish.PruneFruit()

    if not AutoFish.StoreFruit or AutoFish.FruitStorageBusy or AutoFish.Busy then
        return
    end

    local Tool = AutoFish.FindFruit()
    if Tool then
        AutoFish.StoreFruitNow(Tool)
    end
end

function AutoFish.InstallHook()
    local Hook = AutoFish.Hook

    if Hook.Installed or not AutoFish.EnsureFishing() then
        return
    end

    Hook.Installed = true

    local function RunMinigame(Self)
        AutoFish.CastPending = false

        if not Self.Bobble or Self.Animations.Reel.IsPlaying then
            return
        end

        AutoFish.Busy = true

        local Model = Self.Bobble.Model

        Self:_play("Reel")
        Self.Velocity = 0
        Self.MaxVelocity = 2
        Self.Acceleration = Self.Tool:GetAttribute("Acceleration")
        Self.Max = 2
        Self.BarPosition = Self.Max * 0.5
        Self.BarRadius = 0.25
        Self.FishTime = 2
        Self.MaxFishTime = 7.5
        Self.GameSeed = Model:GetAttribute("Seed")
        Self.GameRNG = Random.new(Self.GameSeed)
        Self.MinigameStartTime = os.clock()
        Self.MinigameUpdateCount = 0

        local Assets = Services.ReplicatedStorage.Fishing.Assets
        local Sfx = Assets.SFX.InputSFX

        local Ui = {
            Gui = Assets.UI.FishingUIBill:Clone(),
        }
        Ui.Frame = Ui.Gui.Frame
        Ui.Player = Ui.Frame.Player
        Ui.Goal = Ui.Frame.Goal
        Ui.Time = Ui.Frame.Time
        Ui.Fill = Ui.Time.Fill
        Ui.Icon = Ui.Goal.icon
        Ui.TimeIcon = Ui.Fill.Goal.icon
        Ui.FillX = Ui.Fill.Size.X

        local State = {
            Completed = false,
            Holding = false,
            IconToggle = false,
            TimeIconToggle = false,
            LastClickSound = os.clock(),
            LastIconToggle = os.clock(),
            IconColor = Ui.Icon.ImageColor3,
            GoalPosition = Ui.Goal.Position,
            TweenStartPosition = Ui.Goal.Position,
            TweenTargetPosition = nil,
            TweenStartTime = 0,
            TweenDuration = 0,
        }

        Ui.Player.Size = UDim2.new(Ui.Player.Size.X.Scale, Ui.Player.Size.X.Offset, Self.BarRadius, 0)
        Ui.Info = Ui.Frame.InfoText
        Ui.Info.Text = ""
        Ui.Gui.Adornee = Self.Character.PrimaryPart
        Ui.Gui.Enabled = true
        Ui.Gui.Parent = Player.Gui
        Self.Cleaner.UI = Ui.Gui

        Self.UpdateClock = os.clock()
        Self.UpdateTime = Self.GameRNG:NextNumber(1, 3) / (Model:GetAttribute("MoveMultiplier") or 1)

        local function HoldInput()
            State.Holding = true
            pcall(function()
                Sfx.FishingClick:Play()
            end)
        end

        local function ReleaseInput()
            State.Holding = false
            pcall(function()
                Sfx.FishingUnclick:Play()
            end)
        end

        Self.Cleaner.InputBeganMobile = Services.UserInputService.InputBegan:Connect(function(Input, Processed)
            if not Processed and Input.UserInputType == Enum.UserInputType.Touch then
                HoldInput()
            end
        end)

        Self.Cleaner.InputEndedMobile = Services.UserInputService.InputEnded:Connect(function(Input, Processed)
            if not Processed and Input.UserInputType == Enum.UserInputType.Touch then
                ReleaseInput()
            end
        end)

        if _G.mobile ~= true then
            Self.Cleaner.InputBegan = Self.Tool.Activated:Connect(HoldInput)
            Self.Cleaner.InputEnded = Self.Tool.Deactivated:Connect(ReleaseInput)
        end

        pcall(function()
            Sfx.FishingBarOnTarget:Play()
            Sfx.FishingBarChargeLoop:Play()
            Sfx.FishingBarDrainLoop:Stop()
        end)

        pcall(function()
            Services.TweenService:Create(Ui.Icon, TweenInfo.new(0.25), {
                ImageColor3 = Color3.fromRGB(172, 255, 127),
            }):Play()
        end)

        local function Finish()
            AutoFish.Busy = false
            AutoFish.NextAction = os.clock() + AutoFish.RecastDelay
        end

        local function Step(Dt)
            if not Utils.Running then
                Finish()
                Self:_reelBack()
                return
            end

            Dt = math.min(Dt, 0.1)

            local Now = os.clock()

            if Now - Self.UpdateClock >= Self.UpdateTime then
                Self.MinigameUpdateCount = Self.MinigameUpdateCount + 1
                Self.UpdateClock = Now
                Self.UpdateTime = Self.GameRNG:NextNumber(1, 3) / (Model:GetAttribute("MoveMultiplier") or 1)

                State.TweenStartPosition = State.GoalPosition
                State.TweenTargetPosition = UDim2.fromScale(0.5, Self.GameRNG:NextNumber())
                State.TweenStartTime = Now
                State.TweenDuration = Self.UpdateTime / 2
            end

            if State.TweenTargetPosition then
                local Alpha = math.clamp((Now - State.TweenStartTime) / State.TweenDuration, 0, 1)
                local Value = Services.TweenService:GetValue(Alpha, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
                local Start = State.TweenStartPosition
                local Target = State.TweenTargetPosition

                State.GoalPosition = UDim2.new(
                    Start.X.Scale + (Target.X.Scale - Start.X.Scale) * Value,
                    0,
                    Start.Y.Scale + (Target.Y.Scale - Start.Y.Scale) * Value,
                    0
                )
            end

            Ui.Goal.Position = State.GoalPosition

            local LockedY = State.GoalPosition.Y.Scale
            Self.BarPosition = LockedY * Self.Max
            Self.Velocity = 0
            Ui.Player.Position = UDim2.fromScale(0.5, LockedY)

            Self.FishTime = math.clamp(Self.FishTime + Dt, 0, Self.MaxFishTime)

            if Now - State.LastClickSound >= 0.1 then
                State.LastClickSound = Now
                State.IconToggle = not State.IconToggle
                Ui.Icon.Image = State.IconToggle and "rbxassetid://86151972586326" or "rbxassetid://126419334589592"
            end

            if Now - State.LastIconToggle >= 0.15 then
                State.LastIconToggle = Now
                State.TimeIconToggle = not State.TimeIconToggle
                Ui.TimeIcon.Image = State.TimeIconToggle and "rbxassetid://77450437735760" or "rbxassetid://106397882099629"
            end

            local YScale = math.clamp(Self.FishTime / Self.MaxFishTime, 0, 1)
            Ui.Fill.Size = UDim2.new(Ui.FillX.Scale, Ui.FillX.Offset, YScale, 0)

            if YScale <= 0 then
                Finish()
                Self:_reelBack()
                return
            end

            if YScale >= 1 and not State.Completed then
                State.Completed = true

                local Result
                pcall(function()
                    Result = Self:_invokeFishingAction("Reel")
                end)

                Finish()

                if Result then
                    Self:_reelBack(true)
                else
                    Self:_reelBack()
                end
            end
        end

        Self.Cleaner.Update = Services.RunService.RenderStepped:Connect(function(Dt)
            local Ok, Err = pcall(Step, Dt)

            if not Ok then
                warn("AutoFish minigame:", Err)
                Finish()

                pcall(function()
                    if Self.Cleaner.Update then
                        Self.Cleaner.Update:Disconnect()
                    end
                end)

                pcall(function()
                    Self:_reelBack()
                end)
            end
        end)
    end

    Hook.Module._fishCaught = function(Self, ...)
        local Ok, Err = pcall(RunMinigame, Self)

        if not Ok then
            warn("AutoFish hook:", Err)
            AutoFish.Busy = false
            AutoFish.NextAction = os.clock() + AutoFish.RecastDelay

            local Args = table.pack(...)
            pcall(function()
                Hook.Original(Self, table.unpack(Args, 1, Args.n))
            end)
        end
    end
end

function AutoFish.UninstallHook()
    local Hook = AutoFish.Hook

    if Hook.Installed and Hook.Module and Hook.Original then
        pcall(function()
            Hook.Module._fishCaught = Hook.Original
        end)
        Hook.Installed = false
    end
end

function AutoFish.SetEnabled(Value)
    if Value == AutoFish.Enabled then
        return true
    end

    AutoFish.Enabled = Value

    if Value then
        if not AutoFish.EnsureFishing() then
            AutoFish.Enabled = false
            Utils.Notify("Fishing module not found.")
            Utils.ResetToggle("AutoFishToggle")
            return false
        end

        AutoFish.InstallHook()
        AutoFish.CastPending = false
        AutoFish.Busy = false
        AutoFish.NextAction = 0
    else
        AutoFish.UninstallHook()
        AutoFish.CastPending = false
    end

    Utils.NotifyToggle("AutoFish", Value)
    return true
end

function AutoFish.Tick()
    local Now = os.clock()

    if AutoFish.CastPending and Now - AutoFish.LastCast > AutoFish.CastTimeout then
        AutoFish.CastPending = false
    end

    if AutoFish.Busy or AutoFish.CastPending or AutoFish.FruitStorageBusy or Now < AutoFish.NextAction then
        return
    end

    if AutoFish.Cast() then
        AutoFish.CastPending = true
        AutoFish.LastCast = os.clock()
    else
        AutoFish.NextAction = os.clock() + 1
    end
end

function AntiAFK.Disconnect()
    if AntiAFK.Connection then
        pcall(function()
            AntiAFK.Connection:Disconnect()
        end)
        AntiAFK.Connection = nil
    end
end

function AntiAFK.Apply(Value)
    AntiAFK.Enabled = Value
    AntiAFK.Disconnect()

    if Value then
        pcall(function()
            AntiAFK.Connection = Player.Object.Idled:Connect(function()
                pcall(function()
                    if not AntiAFK.Enabled then
                        return
                    end

                    local Camera = Services.Workspace.CurrentCamera
                    local CameraCFrame = Camera and Camera.CFrame or CFrame.new()
                    Services.VirtualUser:Button2Down(Vector2.zero, CameraCFrame)
                    task.wait(0.1)
                    Services.VirtualUser:Button2Up(Vector2.zero, CameraCFrame)
                end)
            end)
        end)
    end
end

function AntiAFK.SetEnabled(Value)
    if Value == AntiAFK.Enabled and Value == (AntiAFK.Connection ~= nil) then
        return
    end

    AntiAFK.Apply(Value)
    Utils.NotifyToggle("Anti AFK", Value)
end

function Movement.SetFly(Value)
    Movement.Fly = Value

    local Humanoid = Utils.GetHumanoid()
    if Humanoid then
        Humanoid.PlatformStand = Value
    end
end

function Movement.Update(Dt)
    if not Movement.Fly and not Movement.Walk then
        return
    end

    local Root = Utils.GetRoot()
    local Humanoid = Utils.GetHumanoid()
    local Camera = Services.Workspace.CurrentCamera

    if not Root or not Humanoid or not Camera then
        return
    end

    if Movement.Fly then
        local Input = Services.UserInputService

        if Input:GetFocusedTextBox() then
            return
        end

        local CameraCFrame = Camera.CFrame
        local Direction = Vector3.zero

        if Input:IsKeyDown(Enum.KeyCode.W) then Direction = Direction + CameraCFrame.LookVector end
        if Input:IsKeyDown(Enum.KeyCode.S) then Direction = Direction - CameraCFrame.LookVector end
        if Input:IsKeyDown(Enum.KeyCode.A) then Direction = Direction - CameraCFrame.RightVector end
        if Input:IsKeyDown(Enum.KeyCode.D) then Direction = Direction + CameraCFrame.RightVector end
        if Input:IsKeyDown(Enum.KeyCode.Space) then Direction = Direction + Vector3.yAxis end
        if Input:IsKeyDown(Enum.KeyCode.LeftControl) then Direction = Direction - Vector3.yAxis end

        if Direction.Magnitude > 0 then
            Root.CFrame = Root.CFrame + Direction.Unit * Movement.FlySpeed * Dt
        end
    else
        local Direction = Humanoid.MoveDirection

        if Direction.Magnitude > 0 then
            Root.CFrame = Root.CFrame + Direction.Unit * Movement.WalkSpeed * Dt
        end
    end
end

local PikaFly = {
    Enabled = false,
    Installed = false,
    Original = nil,
    Speed = 2,
    MaxSpeed = 2,
    Steer = true,
    Aim = "Mouse",
    Slide = true,
    Probe = 14,
    Clearance = 4,
    Accumulator = 0,
    Warned = false,
}

function PikaFly.GetParams()
    local List = {}

    for _, Name in ipairs({ "Islands", "Ships", "Env" }) do
        local Folder = Services.Workspace:FindFirstChild(Name)
        if Folder then
            List[#List + 1] = Folder
        end
    end

    local Params = RaycastParams.new()
    Params.FilterType = Enum.RaycastFilterType.Include
    Params.FilterDescendantsInstances = List
    return Params
end

function PikaFly.GetAim(Camera, Position)
    if PikaFly.Aim ~= "Mouse" then
        return Camera.CFrame.LookVector
    end

    local Ok, Result = pcall(function()
        local Mouse = Services.UserInputService:GetMouseLocation()
        local MouseRay = Camera:ViewportPointToRay(Mouse.X, Mouse.Y)
        local Hit = Services.Workspace:Raycast(MouseRay.Origin, MouseRay.Direction * 2000, PikaFly.GetParams())
        local Target = Hit and Hit.Position or (MouseRay.Origin + MouseRay.Direction * 2000)
        local Direction = Target - Position

        if Direction.Magnitude < 3 then
            return MouseRay.Direction
        end

        return Direction.Unit
    end)

    if Ok and Result then
        return Result
    end

    return Camera.CFrame.LookVector
end

function PikaFly.GetDirection(Camera, Position)
    local Aim = PikaFly.GetAim(Camera, Position)

    if not PikaFly.Slide then
        return Aim
    end

    local Ok, Hit = pcall(function()
        return Services.Workspace:Raycast(Position, Aim * PikaFly.Probe, PikaFly.GetParams())
    end)

    if not Ok or not Hit then
        return Aim
    end

    local Normal = Hit.Normal
    local Direction = Aim - Normal * Aim:Dot(Normal)

    if Direction.Magnitude < 0.1 then
        local Up = Camera.CFrame.UpVector
        Direction = Up - Normal * Up:Dot(Normal)
    end

    if Direction.Magnitude < 0.1 then
        Direction = Normal
    end

    Direction = Direction.Unit

    if Hit.Distance < PikaFly.Clearance then
        Direction = (Direction + Normal * 0.6).Unit
    end

    return Direction
end

function PikaFly.SteerCFrames(Fn)
    local Camera = Services.Workspace.CurrentCamera
    local GetUpvalues = (debug and debug.getupvalues) or getupvalues
    local SetUpvalue = (debug and debug.setupvalue) or setupvalue

    if not Camera or typeof(GetUpvalues) ~= "function" or typeof(SetUpvalue) ~= "function" then
        if not PikaFly.Warned then
            PikaFly.Warned = true
            warn("PikaFly: executor sem getupvalues/setupvalue.")
        end
        return
    end

    local Ok, Upvalues = pcall(GetUpvalues, Fn)
    if not Ok or type(Upvalues) ~= "table" then
        return
    end

    local Direction
    local Found = 0

    for Index, Value in pairs(Upvalues) do
        if typeof(Value) == "CFrame" then
            Found = Found + 1
            Direction = Direction or PikaFly.GetDirection(Camera, Value.Position)
            pcall(SetUpvalue, Fn, Index, CFrame.lookAt(Value.Position, Value.Position + Direction))
        end
    end

    if Found == 0 and not PikaFly.Warned then
        PikaFly.Warned = true
        warn("PikaFly: nenhum CFrame encontrado nos upvalues.")
    end
end

function PikaFly.Install()
    if PikaFly.Installed then
        return true
    end

    if typeof(hookfunction) ~= "function" or typeof(newcclosure) ~= "function" then
        return false
    end

    local Ok, Module = pcall(function()
        return require(Services.ReplicatedStorage.SkillCallbacks.DevilFruit["PikaV2-PikaV2"])
    end)

    if not Ok or type(Module) ~= "table" or typeof(Module.RadiantFlight) ~= "function" then
        return false
    end

    local Original

    local Hooked = pcall(function()
        Original = hookfunction(Module.RadiantFlight, newcclosure(function(self, Argument1)
            if not PikaFly.Enabled then
                return Original(self, Argument1)
            end

            PikaFly.Accumulator = 0

            local OldToggleSkill = self.ToggleSkill

            self.ToggleSkill = function(Self, Argument, Options)
                if typeof(Options) == "table" and typeof(Options.EndFunction) == "function" then
                    local OriginalEndFunction = Options.EndFunction

                    Options.EndFunction = function(...)
                        if not PikaFly.Enabled then
                            return OriginalEndFunction(...)
                        end

                        PikaFly.Accumulator = PikaFly.Accumulator + math.clamp(PikaFly.Speed, 0.01, PikaFly.MaxSpeed)

                        local Steps = math.floor(PikaFly.Accumulator + 1e-6)
                        PikaFly.Accumulator = PikaFly.Accumulator - Steps

                        for _ = 1, Steps do
                            if PikaFly.Steer then
                                PikaFly.SteerCFrames(OriginalEndFunction)
                            end

                            local Success, Result = pcall(OriginalEndFunction, ...)

                            if not Success then
                                warn(Result)
                                return true
                            end

                            if Result then
                                return true
                            end
                        end

                        return false
                    end
                end

                return OldToggleSkill(Self, Argument, Options)
            end

            local Success, Result = pcall(Original, self, Argument1)
            self.ToggleSkill = OldToggleSkill

            if not Success then
                warn(Result)
            end

            return Result
        end))
    end)

    if not Hooked or typeof(Original) ~= "function" then
        return false
    end

    PikaFly.Original = Original
    PikaFly.Installed = true
    return true
end

function PikaFly.SetEnabled(Value)
    if Value == PikaFly.Enabled then
        return
    end

    if Value then
        if not PikaFly.Install() then
            Utils.Notify("Pika V2 fly module not found.")
            Utils.ResetToggle("PikaFlyToggle")
            return
        end
    end

    PikaFly.Enabled = Value
    Utils.NotifyToggle("Better Pika v2 Fly", Value)
end

local PikaV1 = {
    Enabled = false,
    Installed = false,
    Original = nil,
    Speed = 2,
    MaxSpeed = 2.5,
    SnapAngle = 30,
    BounceDelay = 0.45,
    Aim = "Mouse",
    Direction = nil,
    LastBounce = 0,
    Accumulator = 0,
    Warned = false,
}

function PikaV1.GetAim(Camera, Position)
    if PikaV1.Aim ~= "Mouse" then
        return Camera.CFrame.LookVector
    end

    local Ok, Result = pcall(function()
        local Mouse = Services.UserInputService:GetMouseLocation()
        local MouseRay = Camera:ViewportPointToRay(Mouse.X, Mouse.Y)
        local Hit = Services.Workspace:Raycast(MouseRay.Origin, MouseRay.Direction * 2000, PikaFly.GetParams())
        local Target = Hit and Hit.Position or (MouseRay.Origin + MouseRay.Direction * 2000)
        local Direction = Target - Position

        if Direction.Magnitude < 3 then
            return MouseRay.Direction
        end

        return Direction.Unit
    end)

    if Ok and Result then
        return Result
    end

    return Camera.CFrame.LookVector
end

function PikaV1.ReadDirection(Fn)
    local GetUpvalues = (debug and debug.getupvalues) or getupvalues

    if typeof(GetUpvalues) ~= "function" then
        return nil
    end

    local Ok, Upvalues = pcall(GetUpvalues, Fn)
    if not Ok or type(Upvalues) ~= "table" then
        return nil
    end

    for _, Value in pairs(Upvalues) do
        if typeof(Value) == "CFrame" then
            local Look = Value.LookVector

            if Look == Look and Look.Magnitude > 0.5 then
                return Look.Unit
            end
        end
    end

    return nil
end

function PikaV1.FireReflect(Upvalues, Position, Normal)
    for _, Value in pairs(Upvalues) do
        if typeof(Value) == "Instance" then
            local Ok, IsRemote = pcall(function()
                return Value:IsA("RemoteEvent") or Value:IsA("UnreliableRemoteEvent")
            end)

            if Ok and IsRemote then
                pcall(function()
                    Value:FireServer("reflect", CFrame.new(Position, Position + Normal))
                end)
                return
            end
        end
    end
end

function PikaV1.Steer(Fn)
    local Camera = Services.Workspace.CurrentCamera
    local Root = Utils.GetRoot()
    local GetUpvalues = (debug and debug.getupvalues) or getupvalues
    local SetUpvalue = (debug and debug.setupvalue) or setupvalue

    if not Camera or not Root or typeof(GetUpvalues) ~= "function" or typeof(SetUpvalue) ~= "function" then
        if not PikaV1.Warned then
            PikaV1.Warned = true
            warn("PikaV1: executor sem getupvalues/setupvalue.")
        end
        return
    end

    local Ok, Upvalues = pcall(GetUpvalues, Fn)
    if not Ok or type(Upvalues) ~= "table" then
        return
    end

    if not PikaV1.Direction then
        PikaV1.Direction = PikaV1.ReadDirection(Fn)
    end

    if not PikaV1.Direction then
        if not PikaV1.Warned then
            PikaV1.Warned = true
            warn("PikaV1: nenhum CFrame encontrado nos upvalues.")
        end
        return
    end

    local Aim = PikaV1.GetAim(Camera, Root.Position)
    local Angle = math.deg(math.acos(math.clamp(PikaV1.Direction:Dot(Aim), -1, 1)))
    local Now = os.clock()

    if Angle >= PikaV1.SnapAngle and Now - PikaV1.LastBounce >= PikaV1.BounceDelay then
        local Previous = PikaV1.Direction
        local Normal = Aim - Previous

        PikaV1.Direction = Aim
        PikaV1.LastBounce = Now

        if Normal.Magnitude > 1e-4 then
            PikaV1.FireReflect(Upvalues, Root.Position, Normal.Unit)
        end
    end

    local Direction = PikaV1.Direction

    for Index, Value in pairs(Upvalues) do
        if typeof(Value) == "CFrame" then
            pcall(SetUpvalue, Fn, Index, CFrame.lookAt(Value.Position, Value.Position + Direction))
        elseif typeof(Value) == "Vector3" and math.abs(Value.Magnitude - 1) < 0.001 then
            pcall(SetUpvalue, Fn, Index, Direction)
        end
    end
end

function PikaV1.Install()
    if PikaV1.Installed then
        return true
    end

    if typeof(hookfunction) ~= "function" or typeof(newcclosure) ~= "function" then
        return false
    end

    local Ok, Module = pcall(function()
        return require(Services.ReplicatedStorage.SkillCallbacks.DevilFruit["Pika-Pika"])
    end)

    if not Ok or type(Module) ~= "table" or typeof(Module.LightFlight) ~= "function" then
        return false
    end

    local Original

    local Hooked = pcall(function()
        Original = hookfunction(Module.LightFlight, newcclosure(function(self, Argument1)
            if not PikaV1.Enabled then
                return Original(self, Argument1)
            end

            PikaV1.Accumulator = 0
            PikaV1.Direction = nil
            PikaV1.LastBounce = 0

            local OldToggleSkill = self.ToggleSkill

            self.ToggleSkill = function(Self, Argument, Options)
                if typeof(Options) == "table" and typeof(Options.EndFunction) == "function" then
                    local OriginalEndFunction = Options.EndFunction

                    Options.EndFunction = function(...)
                        if not PikaV1.Enabled then
                            return OriginalEndFunction(...)
                        end

                        PikaV1.Accumulator = PikaV1.Accumulator + math.clamp(PikaV1.Speed, 0.01, PikaV1.MaxSpeed)

                        local Steps = math.floor(PikaV1.Accumulator + 1e-6)
                        PikaV1.Accumulator = PikaV1.Accumulator - Steps

                        for _ = 1, Steps do
                            PikaV1.Steer(OriginalEndFunction)

                            local Success, Result = pcall(OriginalEndFunction, ...)

                            if not Success then
                                warn(Result)
                                return true
                            end

                            if Result then
                                return true
                            end

                            local Updated = PikaV1.ReadDirection(OriginalEndFunction)
                            if Updated then
                                PikaV1.Direction = Updated
                            end
                        end

                        return false
                    end
                end

                return OldToggleSkill(Self, Argument, Options)
            end

            local Success, Result = pcall(Original, self, Argument1)
            self.ToggleSkill = OldToggleSkill

            if not Success then
                warn(Result)
            end

            return Result
        end))
    end)

    if not Hooked or typeof(Original) ~= "function" then
        return false
    end

    PikaV1.Original = Original
    PikaV1.Installed = true
    return true
end

function PikaV1.SetEnabled(Value)
    if Value == PikaV1.Enabled then
        return
    end

    if Value then
        if not PikaV1.Install() then
            Utils.Notify("Pika V1 fly module not found.")
            Utils.ResetToggle("PikaV1FlyToggle")
            return
        end
    end

    PikaV1.Enabled = Value
    Utils.NotifyToggle("Better Pika v1 Fly", Value)
end

Utils.Loop(AutoFish, AutoFish.Tick)
Utils.Loop(AutoStoreFruit, AutoFish.StoreFruitTick)
Utils.Loop(AutoBuyBait, AutoBuyBait.Buy)
Utils.Loop(AutoSellFish, AutoSellFish.Sell)
Utils.Loop(HalloweenFarm, HalloweenFarm.Tick)

task.spawn(function()
    while Utils.Running do
        pcall(HalloweenFarm.UpdateHighlights)
        task.wait(0.5)
    end
end)

AntiAFK.Apply(true)


local Pages = {
	Fishing = Window:Page({ Name = "Fishing", Columns = 2 }),
	Halloween = Window:Page({ Name = "Halloween", Columns = 2 }),
	Player = Window:Page({ Name = "Player", Columns = 2 }),
	Visuals = Window:Page({ Name = "Visuals", Columns = 2 }),
	Utils = Window:Page({ Name = "Utils", Columns = 2 }),
}

local Sections = {
	AutoFish = Pages.Fishing:Section({ Name = "AutoFish", Side = 1 }),
	BuyBait = Pages.Fishing:Section({ Name = "Auto Buy Bait", Side = 2 }),
	StoreFruit = Pages.Fishing:Section({ Name = "Auto Store Fruit", Side = 2 }),
	Sell = Pages.Fishing:Section({ Name = "Auto Sell Fish", Side = 1 }),
	CandyFarm = Pages.Halloween:Section({ Name = "Candy Farm", Side = 1 }),
	CandyShop = Pages.Halloween:Section({ Name = "Candy Shop", Side = 1 }),
	CandyWebhook = Pages.Halloween:Section({ Name = "Candy Webhook", Side = 2 }),
	Player = Pages.Player:Section({ Name = "Player", Side = 1 }),
	Movement = Pages.Player:Section({ Name = "Movement", Side = 2 }),
	PikaFly = Pages.Utils:Section({ Name = "Pika V2", Side = 1 }),
	PikaV1 = Pages.Utils:Section({ Name = "Pika V1", Side = 2 }),
}

Sections.AutoFish:Toggle({ Name = "Auto Fish", Flag = "AutoFishToggle", Default = false, Callback = Safe(AutoFish.SetEnabled) })
Sections.AutoFish:Dropdown({ Name = "Auto Bait", Flag = "BaitDropdown", Default = "Common Fish Bait", Items = { "Common Fish Bait", "Rare Fish Bait", "Legendary Fish Bait" }, Callback = Safe(function(Value) AutoFish.Bait = Value AutoFish.BaitWarned = false AutoFish.LastFallback = nil end) })
Sections.AutoFish:Toggle({ Name = "Smart Bait Selection", Flag = "SmartBaitToggle", Default = false, Callback = Safe(function(Value) AutoFish.SmartBait = Value AutoFish.BaitWarned = false AutoFish.LastFallback = nil Utils.NotifyToggle("Smart Bait Selection", Value) end) })
Sections.BuyBait:Toggle({ Name = "Auto Buy Common Fish Bait", Flag = "AutoBuyCommonBait", Default = false, Callback = Safe(function(Value) AutoBuyBait.Enabled = Value Utils.NotifyToggle("Auto Buy Common Fish Bait", Value) end) })
Sections.StoreFruit:Toggle({ Name = "Auto Store Fruit", Flag = "AutoStoreToggle", Default = false, Callback = Safe(function(Value) AutoFish.StoreFruit = Value AutoStoreFruit.Enabled = Value Utils.NotifyToggle("Auto Store Fruit", Value) end) })
Sections.StoreFruit:Textbox({ Name = "Webhook URL", Flag = "WebhookUrl", Default = "", Placeholder = "https://discord.com/api/webhooks/...", Callback = Safe(function(Value) Webhook.Url = tostring(Value or ""):match("^%s*(.-)%s*$") end) })
Sections.StoreFruit:Toggle({ Name = "Webhook", Flag = "WebhookToggle", Default = false, Callback = Safe(function(Value) Webhook.Enabled = Value Utils.NotifyToggle("Webhook", Value) if Value and Webhook.Url == "" then Utils.Notify("Webhook URL is empty.") end end) })
Sections.Sell:Toggle({ Name = "Auto Sell", Flag = "AutoSellToggle", Default = false, Callback = Safe(function(Value) AutoSellFish.Enabled = Value Utils.NotifyToggle("Auto Sell", Value) end) })
Sections.Sell:Dropdown({ Name = "Rarity", Flag = "SellRarity", Multi = true, Default = { "Common Fish" }, Items = { "Common Fish", "Rare Fish", "Legendary Fish" }, Callback = Safe(function(Value) AutoSellFish.SelectedRarity = Value end) })
Sections.CandyFarm:Toggle({ Name = "Farm Candy", Flag = "CandyFarmToggle", Default = false, Callback = Safe(HalloweenFarm.SetEnabled) })
Sections.CandyShop:Dropdown({ Name = "Buy Items", Flag = "CandyFarmBuyItem", Multi = true, Default = {}, Items = HalloweenFarm.GetShopLabels(), Callback = Safe(HalloweenFarm.SetBuyItems) })
Sections.CandyShop:Toggle({ Name = "Only Buy When Max Candy", Flag = "CandyOnlyBuyAtMax", Default = false, Callback = Safe(function(Value) HalloweenFarm.OnlyBuyAtMax = Value HalloweenFarm.BuyBlockedUntil = 0 Utils.NotifyToggle("Only Buy When Max Candy", Value) end) })
Sections.CandyWebhook:Textbox({ Name = "Webhook URL", Flag = "CandyWebhookUrl", Default = "", Placeholder = "https://discord.com/api/webhooks/...", Callback = Safe(function(Value) CandyWebhook.Url = tostring(Value or ""):match("^%s*(.-)%s*$") end) })
Sections.CandyWebhook:Toggle({ Name = "Candy Webhook", Flag = "CandyWebhookToggle", Default = false, Callback = Safe(function(Value) CandyWebhook.Enabled = Value Utils.NotifyToggle("Candy Webhook", Value) if Value and CandyWebhook.Url == "" then Utils.Notify("Candy Webhook URL is empty.") end end) })
Sections.Player:Toggle({ Name = "Anti AFK", Flag = "AntiAFKToggle", Default = true, Callback = Safe(AntiAFK.SetEnabled) })
do
	local FlyToggle = Sections.Movement:Toggle({ Name = "Fly", Flag = "FlyToggle", Default = false, Callback = Safe(function(Value) Movement.SetFly(Value) Utils.NotifyToggle("Fly", Value) end) })
	FlyToggle:Keybind({ Name = "Fly", Flag = "FlyBind", Default = Enum.KeyCode.F4, Mode = "Toggle" })
	Sections.Movement:Slider({ Name = "Fly Speed", Flag = "FlySpeed", Default = 80, Min = 1, Max = 5000, Decimals = 0, Callback = Safe(function(Value) Movement.FlySpeed = Value end) })
	local WalkToggle = Sections.Movement:Toggle({ Name = "WalkSpeed", Flag = "WalkSpeedToggle", Default = false, Callback = Safe(function(Value) Movement.Walk = Value Utils.NotifyToggle("WalkSpeed", Value) end) })
	WalkToggle:Keybind({ Name = "WalkSpeed", Flag = "WalkSpeedBind", Default = Enum.KeyCode.F3, Mode = "Toggle" })
	Sections.Movement:Slider({ Name = "Walk Speed", Flag = "WalkSpeedValue", Default = 60, Min = 1, Max = 100, Decimals = 0, Callback = Safe(function(Value) Movement.WalkSpeed = Value end) })
end
Sections.PikaFly:Toggle({ Name = "Better Pika v2 Fly", Flag = "PikaFlyToggle", Default = false, Callback = Safe(PikaFly.SetEnabled) })
Sections.PikaFly:Slider({ Name = "Fly Speed", Flag = "PikaFlySpeed", Default = 2, Min = 0.1, Max = 2, Decimals = 1, Callback = Safe(function(Value) PikaFly.Speed = math.clamp(tonumber(Value) or PikaFly.MaxSpeed, 0.1, PikaFly.MaxSpeed) end) })
Sections.PikaV1:Toggle({ Name = "Better Pika v1 Fly", Flag = "PikaV1FlyToggle", Default = false, Callback = Safe(PikaV1.SetEnabled) })
Sections.PikaV1:Slider({ Name = "Fly Speed", Flag = "PikaV1FlySpeed", Default = 2.5, Min = 0.1, Max = 2.5, Decimals = 1, Callback = Safe(function(Value) PikaV1.Speed = math.clamp(tonumber(Value) or PikaV1.MaxSpeed, 0.1, PikaV1.MaxSpeed) end) })
Utils.Give(Services.RunService.RenderStepped:Connect(function(Dt) pcall(Movement.Update, Dt) end))
Utils.Give(Player.Object.CharacterAdded:Connect(function(Character) pcall(function() local Humanoid = Character:WaitForChild("Humanoid", 10) if Humanoid and Movement.Fly then Humanoid.PlatformStand = true end end) end))

task.spawn(function()
	while Utils.Running do
		pcall(Webhook.CheckDrops)
		pcall(CandyWebhook.Check)
		task.wait(2)
	end
end)

local function Unload()
	Utils.Running = false
	AutoFish.Enabled = false AutoStoreFruit.Enabled = false AutoBuyBait.Enabled = false AutoSellFish.Enabled = false Webhook.Enabled = false CandyWebhook.Enabled = false PikaFly.Enabled = false PikaV1.Enabled = false
	pcall(AutoFish.UninstallHook)
	if AutoFish.UsingFallback then _G.MouseCF = nil AutoFish.UsingFallback = false end
	AutoFish.Busy = false AutoFish.CastPending = false AutoFish.FruitStorageBusy = false
	AntiAFK.Enabled = false pcall(AntiAFK.Disconnect)
	Movement.Fly = false Movement.Walk = false
	HalloweenFarm.Enabled = false HalloweenFarm.Busy = false pcall(HalloweenFarm.StopHover) pcall(HalloweenFarm.ClearHighlights, true)
	pcall(function() local Humanoid = Utils.GetHumanoid() if Humanoid then Humanoid.PlatformStand = false end end)
	for _, Conn in pairs(Connections) do pcall(function() if Conn and Conn.Connected then Conn:Disconnect() end end) end
	table.clear(Connections)
end

local function InitVisuals(Page)
local EspPage = Page

local Services = {
	Players = game:GetService("Players"),
	RunService = game:GetService("RunService"),
	ReplicatedStorage = game:GetService("ReplicatedStorage"),
}
local LP = Services.Players.LocalPlayer
local UIS = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")

local Shared = {}
Shared.Alive = true
Shared.EspFont = Enum.Font.RobotoMono
Shared.EspSize = 1.0

local Rates = { Esp = 0.033, Entity = 0.033, Vending = 0.033, Chest = 0.033, Medal = 0.066, Island = 0.066 }
local Conns = {}
local LastTick = { Esp = 0, Entity = 0, Vending = 0, Chest = 0, Medal = 0 }

local function StoredDisconnect(C)
	if not C then return end
	local Inner = C.Connection
	if Inner then
		pcall(function() Inner:Disconnect() end)
	end
end

local function ApplyFont(Lbl)
	if not Lbl then return end
	Lbl.Font = Shared.EspFont
end
Shared.ApplyFont = ApplyFont

local CharFolders
local function GetCharFolders()
	if CharFolders and #CharFolders > 0 then return CharFolders end
	CharFolders = {}
	for _, Name in ipairs({ "PlayerCharacters", "Characters" }) do
		local Folder = workspace:FindFirstChild(Name)
		if Folder then CharFolders[#CharFolders + 1] = Folder end
	end
	return CharFolders
end

local function GetRoot(Char)
	if not Char then return nil end
	local Root = Char:FindFirstChild("HumanoidRootPart", true)
	if Root and Root:IsA("BasePart") then return Root end
	local Head = Char:FindFirstChild("Head", true)
	if Head and Head:IsA("BasePart") then return Head end
	if Char:IsA("Model") and Char.PrimaryPart then return Char.PrimaryPart end
	return Char:FindFirstChildWhichIsA("BasePart", true)
end

local function ResolveCharacter(Player)
	if not Player then return nil, nil end
	local Char
	if Player:IsA("Player") then
		Char = Player.Character
	elseif Player:IsA("Model") then
		Char = Player
	end
	if Char and Char.Parent then
		local Root = GetRoot(Char)
		if Root then return Char, Root end
	end
	if Player:IsA("Player") then
		for _, Folder in ipairs(GetCharFolders()) do
			local Model = Folder:FindFirstChild(Player.Name)
			if Model then
				local Root = GetRoot(Model)
				if Root then return Model, Root end
				for _, Sub in ipairs(Model:GetChildren()) do
					if Sub:IsA("Model") then
						local SubRoot = GetRoot(Sub)
						if SubRoot then return Sub, SubRoot end
					end
				end
			end
		end
	end
	return Char, Char and GetRoot(Char) or nil
end

local function GetCharacter(Player)
	local Char = ResolveCharacter(Player)
	return Char
end
local GetCharacterWithRoot = ResolveCharacter

local StatsCache = setmetatable({}, { __mode = "k" })
local function GetStats(Player)
	if not Player then return nil end
	local Cached = StatsCache[Player]
	if Cached ~= nil then
		if Cached.Parent then return Cached end
		StatsCache[Player] = nil
	end
	local Found = Services.ReplicatedStorage:FindFirstChild("Stats" .. tostring(Player.Name))
	StatsCache[Player] = Found
	return Found
end

local function GetBounty(Player)
	if not Player then return nil end
	local S = GetStats(Player)
	local V = S and S:FindFirstChild("Stats") and S.Stats:FindFirstChild("Bounty")
	if V and V:IsA("IntValue") then return V.Value end
	local LS = Player:FindFirstChild("leaderstats")
	local BV = LS and LS:FindFirstChild("Bounty")
	if BV and BV:IsA("IntValue") then return BV.Value end
	return nil
end

local BOUNTY_INTERVAL = 0.4
local BountyCache = setmetatable({}, { __mode = "k" })
local function GetBountyThrottled(Player, Now)
	local C = BountyCache[Player]
	if C and (Now - C.At) < BOUNTY_INTERVAL then return C.Value end
	local Value = GetBounty(Player)
	BountyCache[Player] = { At = Now, Value = Value }
	return Value
end

local Scratch = {}
local function PushText(Text)
	Scratch.n = (Scratch.n or 0) + 1
	Scratch[Scratch.n] = Text
end
Shared.Scratch = Scratch

local function FormatTag(Current, Max)
	local C = FiniteNumber(Current) and math.ceil(Current) or 0
	local M = FiniteNumber(Max) and math.ceil(Max) or 0
	return "[" .. C .. "/" .. M .. "]"
end

local function CandidateBefore(A, B)
	return A.CDist < B.CDist
end

local function InFront(Pos, CamCF)
	if not CamCF then return true end
	local Delta = Pos - CamCF.Position
	return Delta:Dot(CamCF.LookVector) > 0
end

local function GetStaminaBar(Player)
	if not Player then return nil end
	local S = GetStats(Player)
	local V = S and S:FindFirstChild("Stamina")
	if V and V:IsA("IntConstrainedValue") then
		local Max = V.MaxValue
		if typeof(Max) == "number" and Max > 0 then return V.Value, Max end
	end
	return nil
end

local PartyMap, PartyRef, PartyConns = nil, nil, {}
local function GetPartyValue(Player)
	if not Player then return nil end
	local Name = Player.Name
	local A = Player:GetAttribute("PartyId")
	if typeof(A) == "number" and A > 0 then return A end
	local CP = Services.ReplicatedStorage:FindFirstChild("currentParty")
	if CP then
		if PartyRef ~= CP then
			for _, C in ipairs(PartyConns) do pcall(function() C:Disconnect() end) end
			PartyConns = {}
			PartyMap = nil
			PartyRef = CP
			pcall(function()
				PartyConns[1] = CP.DescendantAdded:Connect(function() PartyMap = nil end)
				PartyConns[2] = CP.DescendantRemoving:Connect(function() PartyMap = nil end)
			end)
		end
		if not PartyMap then
			local Map = {}
			for _, Party in ipairs(CP:GetChildren()) do
				if Party:IsA("Folder") or Party:IsA("Model") then
					for _, Member in ipairs(Party:GetChildren()) do
						Map[Member.Name] = Party.Name
					end
				end
			end
			PartyMap = Map
		end
		local Id = PartyMap[Name]
		if Id then return Id end
	end
	local S = GetStats(Player)
	local Party = S and S:FindFirstChild("Party")
	if Party and Party:IsA("IntValue") then return Party.Value > 0 and Party.Value or nil end
	local Team = S and S:FindFirstChild("Team")
	if Team and Team:IsA("IntValue") then return Team.Value > 0 and Team.Value or nil end
	return nil
end

local function FormatNumber(N)
	if not FiniteNumber(N) then return "?" end
	if N >= 1e9 then return ("%.1fB"):format(N / 1e9) end
	if N >= 1e6 then return ("%.1fM"):format(N / 1e6) end
	if N >= 1e4 then return ("%.1fK"):format(N / 1e3) end
	return tostring(math.floor(N + 0.5))
end

local function DestroyKey(PD, Key)
	if PD and PD[Key] then
		pcall(function() PD[Key]:Destroy() end)
		PD[Key] = nil
	end
end

local HP_EMPTY = Color3.fromRGB(255, 0, 0)
local HP_FULL = Color3.fromRGB(0, 255, 0)
local STAM_COLOR = Color3.fromRGB(99, 175, 251)
local BarBgColor = Color3.fromRGB(0, 0, 0)
local EspLayout = {
	Padding = 1,
	MinWidth = 10,
	MinHeight = 10,
	NameSpace = 16,
	BarSpace = 4,
	SepRange = 300,
}
local Reported = setmetatable({}, { __mode = "k" })
local function ReportOnce(Scope, Message)
	local Seen = Reported[Scope]
	if not Seen then
		Seen = {}
		Reported[Scope] = Seen
	end
	local Text = tostring(Message)
	if Seen[Text] then return end
	Seen[Text] = true
	warn("[Aero] " .. Scope .. ": " .. Text)
end

local function LerpHp(Ratio)
	if not Ratio then return nil end
	return HP_EMPTY:Lerp(HP_FULL, math.clamp(Ratio, 0, 1))
end

local BAR_SIDES = { HealthBar = "left", StamBar = "right" }
local BARS_KEY = BAR_SIDES.HealthBar .. "," .. BAR_SIDES.StamBar

local function InsideStroke(Frame, StrokeColor, InsideOffset)
	local SizeOffset = -InsideOffset * 2
	local Holder = Instance.new("Frame")
	Holder.Name = "Outline_" .. tostring(InsideOffset)
	Holder.Parent = Frame
	Holder.Size = UDim2.new(1, SizeOffset, 1, SizeOffset)
	Holder.Position = UDim2.new(0, InsideOffset, 0, InsideOffset)
	Holder.BackgroundTransparency = 1
	local Stroke = Instance.new("UIStroke")
	Stroke.Color = StrokeColor
	Stroke.Thickness = 1
	Stroke.BorderStrokePosition = Enum.BorderStrokePosition.Inner
	Stroke.Parent = Holder
	return Holder
end

local function CreateBar(Container, Vertical, Separators, Color, Opts)
	local Styled = Opts and Opts.Border
	local BorderColor = (Opts and Opts.BorderColor) or Color3.new(0, 0, 0)
	local Bg = Instance.new("Frame")
	Bg.Name = "Background"
	Bg.Parent = Container
	Bg.Size = UDim2.new(1, 0, 1, 0)
	Bg.Position = UDim2.new(0, 0, 0, 0)
	Bg.AnchorPoint = Vector2.new(0, 0)
	Bg.BackgroundColor3 = BarBgColor
	Bg.BorderSizePixel = 0
	local Border
	if Styled then
		Border = Instance.new("UIStroke")
		Border.Name = "BarStroke"
		Border.Color = BorderColor
		Border.Thickness = 1
		Border.Transparency = 0.1
		Border.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		Border.Parent = Bg
	else
		InsideStroke(Bg, Color3.new(0, 0, 0), 0)
	end
	local Area = Instance.new("Frame")
	Area.Name = "BarArea"
	Area.Parent = Bg
	Area.BackgroundTransparency = 1
	Area.Position = UDim2.new(0, 1, 0, 1)
	Area.Size = UDim2.new(1, -2, 1, -2)
	Area.ZIndex = 1
	local Seps = nil
	if Separators then
		Seps = {}
		for Idx = 1, 4 do
			local Sep = Instance.new("Frame")
			Sep.Name = "Separator"
			Sep.Parent = Area
			Sep.BackgroundColor3 = BorderColor
			Sep.BackgroundTransparency = Styled and 0.3 or 0
			Sep.BorderSizePixel = 0
			Sep.Position = UDim2.new(0, 0, Idx / 5, 0)
			Sep.Size = UDim2.new(1, 0, 0, 1)
			Sep.ZIndex = 3
			Seps[#Seps + 1] = Sep
		end
	end
	local Fill = Instance.new("Frame")
	Fill.Name = "Bar"
	Fill.Parent = Area
	Fill.BorderSizePixel = 0
	Fill.Size = UDim2.new(0, 0, 0, 0)
	Fill.BackgroundColor3 = Color
	if Vertical then
		Fill.AnchorPoint = Vector2.new(0, 1)
		Fill.Position = UDim2.new(0, 0, 1, 0)
	else
		Fill.AnchorPoint = Vector2.new(0, 0)
		Fill.Position = UDim2.new(0, 0, 0, 0)
	end
	if Opts and Opts.Gradient then
		local Grad = Instance.new("UIGradient")
		Grad.Rotation = Vertical and -90 or -180
		Grad.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(225, 225, 225))
		Grad.Parent = Fill
	end
	return { Bg = Bg, Area = Area, Fill = Fill, Seps = Seps, Vertical = Vertical, Border = Border }
end

local function SizeBarFill(Bar, Percentage)
	local P = math.clamp(Percentage or 0, 0, 1)
	if Bar.Vertical then
		Bar.Fill.Size = UDim2.new(1, 0, P, 0)
	else
		Bar.Fill.Size = UDim2.new(P, 0, 1, 0)
	end
end

local function SetBarSeparators(Bar, Visible)
	if not Bar.Seps then return end
	for Idx = 1, #Bar.Seps do
		local Sep = Bar.Seps[Idx]
		if Sep.Visible ~= Visible then Sep.Visible = Visible end
	end
end

local function SetBarTransparency(Bar, Alpha)
	if not Bar then return end
	local A = math.clamp(Alpha or 0, 0, 1)
	if Bar.Bg then Bar.Bg.BackgroundTransparency = A end
	if Bar.Fill then Bar.Fill.BackgroundTransparency = A end
	if Bar.Seps then
		for Idx = 1, #Bar.Seps do Bar.Seps[Idx].BackgroundTransparency = 0.3 + 0.7 * A end
	end
	if Bar.Border then Bar.Border.Transparency = 0.1 + 0.9 * A end
	if Bar.Stored then Bar.Stored.BackgroundTransparency = A end
end

local function CreateStoredDamage(Bar, Color)
	if not Bar or not Bar.Area then return end
	local SD = Instance.new("Frame")
	SD.Name = "StoredDamage"
	SD.BackgroundColor3 = Color or Color3.fromRGB(255, 82, 0)
	SD.BorderSizePixel = 0
	SD.ZIndex = 2
	SD.Visible = false
	SD.Parent = Bar.Area
	local Grad = Instance.new("UIGradient")
	Grad.Rotation = Bar.Vertical and -90 or -180
	Grad.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(225, 225, 225))
	Grad.Parent = SD
	Bar.Stored = SD
	return SD
end

local function UpdateStoredDamage(Bar, HealthRatio, StoredRatio)
	if not Bar or not Bar.Stored then return end
	local SD = Bar.Stored
	local S = math.clamp(StoredRatio or 0, 0, 1)
	if S <= 0.002 then
		if SD.Visible then SD.Visible = false end
		return
	end
	local H = math.clamp(HealthRatio or 0, 0, 1)
	local Top = math.clamp(1 - H - S, 0, 1)
	if not SD.Visible then SD.Visible = true end
	SD.Position = UDim2.new(0, 0, Top, 0)
	SD.Size = UDim2.new(1, 0, S, 0)
end

local function EspTextSize(Scale)
	return math.clamp(math.floor(13 * Scale + 0.5), 9, 28)
end

local function StyleEspLabel(Lbl)
	Lbl.BackgroundTransparency = 1
	Lbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	Lbl.TextStrokeTransparency = 0
	Lbl.TextScaled = false
	Lbl.TextWrapped = false
	Lbl.TextXAlignment = Enum.TextXAlignment.Center
	Lbl.TextYAlignment = Enum.TextYAlignment.Top
	ApplyFont(Lbl)
end

local function LayoutEspLabels(ED, Scale)
	local TS = EspTextSize(Scale)
	local H = math.ceil(TS * 1.25)
	local Lbl, DistLbl = ED.Lbl, ED.DistLbl
	if Lbl then
		StyleEspLabel(Lbl)
		Lbl.TextSize = TS
		Lbl.Size = UDim2.new(1, 0, 0, H)
		Lbl.AnchorPoint = Vector2.new(0.5, 1)
		Lbl.Position = UDim2.new(0.5, 0, 1, -H)
	end
	if DistLbl then
		StyleEspLabel(DistLbl)
		DistLbl.TextSize = TS
		DistLbl.Size = UDim2.new(1, 0, 0, H)
		DistLbl.AnchorPoint = Vector2.new(0.5, 1)
		DistLbl.Position = UDim2.new(0.5, 0, 1, 0)
	end
end

local function SetEspDistance(ED, On, Dist, Color)
	local DistLbl = ED.DistLbl
	if not DistLbl then return end
	if not On then
		if DistLbl.Visible then DistLbl.Visible = false end
		return
	end
	if not DistLbl.Visible then DistLbl.Visible = true end
	local Studs = SafeStuds(Dist)
	if not Studs then
		if ED.LastDistTxt ~= "" then DistLbl.Text = ""; ED.LastDistTxt = "" end
		return
	end
	local T = Studs .. " studs"
	if T ~= ED.LastDistTxt then DistLbl.Text = T; ED.LastDistTxt = T end
	if Color and DistLbl.TextColor3 ~= Color then DistLbl.TextColor3 = Color end
end

local function CreateEspText(Container, Color, Default)
	local Lbl = Instance.new("TextLabel")
	Lbl.Parent = Container
	Lbl.Text = Default
	Lbl.Size = UDim2.new(0, 400, 1, 0)
	Lbl.AnchorPoint = Vector2.new(0.5, 0)
	Lbl.Position = UDim2.new(0.5, 0, 0, 0)
	Lbl.TextColor3 = Color
	Lbl.TextSize = 13
	StyleEspLabel(Lbl)
	return Lbl
end

local function AddEspElement(PD, Name, Side, Bar, Space, Create)
	local Container = Instance.new("Frame")
	Container.Name = string.format("%s_Container_%s", Side or "Dynamic", Name)
	Container.BackgroundTransparency = 1
	PD.Elements[#PD.Elements + 1] = {
		Name = Name,
		Side = Side,
		Bar = Bar,
		Space = Space,
		Container = Container,
		Create = Create,
		Created = false,
	}
	return Container
end

local function EspElementsOnSide(PD, Side)
	local List = {}
	for Idx = 1, #PD.Elements do
		local EL = PD.Elements[Idx]
		if EL.Container.Visible and (EL.Side or BAR_SIDES[EL.Bar]) == Side then
			List[#List + 1] = EL
		end
	end
	return List
end

local Place
local function LayoutEsp(PD, Char)
	local Bill = PD.Bill
	if not Bill or not Char then return end
	local Offsets = { top = 0, bottom = 0, left = 0, right = 0 }
	for _, Side in ipairs({ "top", "bottom", "left", "right" }) do
		local List = EspElementsOnSide(PD, Side)
		local Total = 0
		for Idx = 1, #List do
			Total = Total + List[Idx].Space + EspLayout.Padding
		end
		if #List > 0 then Total = Total - EspLayout.Padding end
		Offsets[Side] = Total
	end
	local PadH = math.max(Offsets.left, Offsets.right)
	local PadV = math.max(Offsets.top, Offsets.bottom)
	local Extents = Char:GetExtentsSize()
	if PD.LastExtents and math.abs(PD.LastExtents.Magnitude - Extents.Magnitude) >= 10 then
		PD.SkeletonExtents = nil
	end
	PD.LastExtents = Extents
	if not PD.SkeletonExtents then
		local Ok, Clone = pcall(function() return Char:Clone() end)
		if Ok and Clone then
			for _, Inst in ipairs(Clone:GetDescendants()) do
				if Inst.Parent and Inst:IsA("BasePart") and not Inst.Parent:IsA("BasePart") then
					if not Inst:FindFirstChildWhichIsA("Weld") and not Inst:FindFirstChildWhichIsA("Motor6D") then
						Inst:Destroy()
					end
				end
			end
			local Got, Skeleton = pcall(function() return Clone:GetExtentsSize() end)
			PD.SkeletonExtents = (Got and Skeleton) or Extents
			pcall(function() Clone:Destroy() end)
		else
			PD.SkeletonExtents = Extents
		end
	end
	local Sext = PD.SkeletonExtents
	Bill.Size = UDim2.new(
		Sext.X + 1.5,
		PadH * 2 + EspLayout.MinWidth,
		Sext.Y + 1.5,
		PadV * 2 + EspLayout.MinHeight
	)
	PD.BBox.Position = UDim2.new(0, PadH, 0, PadV)
	PD.BBox.Size = UDim2.new(1, -(PadH * 2), 1, -(PadV * 2))
	function Place(EL, Anchor, Position, Size, Host)
		local Container = EL.Container
		Container.Parent = Host
		Container.AnchorPoint = Anchor
		Container.Position = Position
		Container.Size = Size
		if not EL.Created and EL.Create then
			EL.Create(Container)
			EL.Created = true
		end
	end
	local List
	List = EspElementsOnSide(PD, "top")
	do
		local Cur = 0
		for Idx = 1, #List do
			local EL = List[Idx]
			Place(EL, Vector2.new(0, 1), UDim2.new(0, PadH, 0, PadV - Cur), UDim2.new(1, -(PadH * 2), 0, EL.Space), PD.Canvas)
			Cur = Cur + EL.Space + EspLayout.Padding
		end
	end
	List = EspElementsOnSide(PD, "bottom")
	do
		local Cur = 0
		for Idx = 1, #List do
			local EL = List[Idx]
			Place(EL, Vector2.new(0, 0), UDim2.new(0, 0, 1, Cur), UDim2.new(1, 0, 0, EL.Space), PD.BBox)
			Cur = Cur + EL.Space + EspLayout.Padding
		end
	end
	List = EspElementsOnSide(PD, "left")
	do
		local Cur = 0
		for Idx = 1, #List do
			local EL = List[Idx]
			Place(EL, Vector2.new(1, 0), UDim2.new(0, PadH - Cur, 0, PadV), UDim2.new(0, EL.Space, 1, -(PadV * 2)), PD.Canvas)
			Cur = Cur + EL.Space + EspLayout.Padding
		end
	end
	List = EspElementsOnSide(PD, "right")
	do
		local Cur = 0
		for Idx = 1, #List do
			local EL = List[Idx]
			Place(EL, Vector2.new(0, 0), UDim2.new(1, Cur, 0, 0), UDim2.new(0, EL.Space, 1, 0), PD.BBox)
			Cur = Cur + EL.Space + EspLayout.Padding
		end
	end
end

local EspSizeListeners = {}
function Shared.RegisterEspSize(Fn)
	EspSizeListeners[#EspSizeListeners + 1] = Fn
end
function Shared.SetEspSize(Value)
	Shared.EspSize = Value
	for _, Fn in ipairs(EspSizeListeners) do
		pcall(Fn, Value)
	end
end

Shared.EspProfile = {
	Color = Color3.fromRGB(255, 255, 255),
	NameColor = Color3.fromRGB(255, 255, 255),
	DistanceColor = Color3.fromRGB(255, 255, 255),
	HealthLowColor = Color3.fromRGB(255, 60, 60),
	HealthHighColor = Color3.fromRGB(0, 255, 60),
	BoxType = "Full",
}

Shared.EspActive = {}
Shared.EspUpdaters = {}
function Shared.RegisterEsp(Active, Update)
	table.insert(Shared.EspActive, Active)
	table.insert(Shared.EspUpdaters, Update)
end

local SyncWanted = false
function Shared.Sync()
	local Want = false
	for _, Active in ipairs(Shared.EspActive) do
		if Active() then Want = true break end
	end
	SyncWanted = Want
end

Library:Connect(Services.RunService.Heartbeat, function()
	if not SyncWanted then return end
	for _, Update in ipairs(Shared.EspUpdaters) do
		Update()
	end
end)

local function AddCommonEspUi(Section, Config)
	Section:Toggle({
		Name = "Enable",
		Flag = Config.EnableFlag,
		Default = false,
		Callback = Config.OnEnable,
	})
	Section:Toggle({
		Name = Config.NameText or "Name",
		Flag = Config.NameFlag,
		Default = true,
		Callback = Config.OnName,
	})
	Section:Toggle({
		Name = "Distance",
		Flag = Config.DistanceFlag,
		Default = true,
		Callback = Config.OnDistance,
	})
	Section:Slider({
		Name = "ESP Distance",
		Flag = Config.MaxDistFlag,
		Min = 100,
		Max = Config.MaxDistMax or 50000,
		Default = Config.MaxDistDefault or 5000,
		Decimals = 0,
		Suffix = " studs",
		Callback = Config.OnMaxDist,
	})
end

-- Player ESP

local Esp = {
	On = false,
	Color = Color3.fromRGB(255, 255, 255),
	Name = true, Bounty = true, HP = true, Stamina = true, Dist = true,
	HPBar = true, StamBar = true, BBox = false,
	MarkAllies = false, HideIfAlly = false,
	AllyColor = Color3.fromRGB(96, 255, 132),
	BarColor = Color3.fromRGB(0, 0, 0), StoredColor = Color3.fromRGB(255, 82, 0),
	Stored = true, Fade = false, FadeDist = 250,
	MaxDist = 5000, MaxTargets = 8,
	Players = {},
	Cand = {},
	PassId = 0,
}

local function RemovePlayerEsp(Player)
	local PD = Esp.Players[Player]
	if not PD then return end
	if PD.CharConn then pcall(function() PD.CharConn:Disconnect() end) end
	DestroyKey(PD, "Bill")
	Esp.Players[Player] = nil
end

local function ClearEsp()
	for P in pairs(Esp.Players) do RemovePlayerEsp(P) end
	Esp.Players = {}
end

local function WaitChar(Char)
	for _ = 1, 50 do
		local HRP = Char:FindFirstChild("HumanoidRootPart", true)
		local Head = Char:FindFirstChild("Head", true)
		local Hum = Char:FindFirstChildOfClass("Humanoid")
		if HRP and Head and Hum then return true end
		if not Char.Parent then return false end
		task.wait(0.1)
	end
	return false
end

local function CreateEspBill(Player, Char)
	local Root = GetRoot(Char)
	if not Root then return end
	local PD = Esp.Players[Player]
	if PD and PD.Bill then
		if PD.Root == Root and PD.LayoutKey and PD.Sides == BARS_KEY then return end
		pcall(function() PD.Bill:Destroy() end)
	end
	PD = PD or {}
	PD.Player = Player
	PD.Root = Root
	PD.Elements = {}
	PD.LayoutKey = nil
	PD.LastTxt = nil
	PD.LastDistTxt = nil
	PD.NameLbl = nil
	PD.DistLbl = nil
	PD.HpBar = nil
	PD.StamBar = nil
	PD.Sides = BARS_KEY
	PD.SkeletonExtents = nil
	PD.LastExtents = nil
	PD.LastHR = nil
	PD.LastAlpha = nil
	PD.StoredRatio = 0
	PD.StoredTime = 0
	local TextSize = math.clamp(math.floor(13 * Shared.EspSize + 0.5), 9, 26)
	local NameSpace = math.max(EspLayout.NameSpace, math.floor(EspLayout.NameSpace * Shared.EspSize))
	local Bill = Instance.new("BillboardGui")
	Bill.Name = "PlayerESP"
	Bill.Adornee = Root
	Bill.AlwaysOnTop = true
	Bill.Enabled = false
	Bill.ClipsDescendants = false
	Bill.AutoLocalize = false
	Bill.LightInfluence = 0
	Bill.ResetOnSpawn = false
	Bill.Parent = workspace
	local Canvas = Instance.new("Frame")
	Canvas.Name = "Canvas"
	Canvas.BackgroundTransparency = 1
	Canvas.Size = UDim2.new(1, 0, 1, 0)
	Canvas.Parent = Bill
	local BBox = Instance.new("Frame")
	BBox.Name = "ESPBoundingBox"
	BBox.BackgroundTransparency = 1
	BBox.Parent = Canvas
	PD.Bill = Bill
	PD.Canvas = Canvas
	PD.BBox = BBox
	PD.BBBlack = InsideStroke(BBox, Color3.new(0, 0, 0), 0)
	PD.BBWhite = InsideStroke(BBox, Color3.new(1, 1, 1), 1)
	PD.BBBlack.Visible = false
	PD.BBWhite.Visible = false
	AddEspElement(PD, "Name", "top", nil, NameSpace, function(Container)
		PD.NameLbl = CreateEspText(Container, Shared.EspProfile.Color or Esp.Color, "N/A")
		PD.NameLbl.TextSize = TextSize
	end)
	AddEspElement(PD, "Distance", "bottom", nil, NameSpace, function(Container)
		PD.DistLbl = CreateEspText(Container, Shared.EspProfile.Color or Esp.Color, "0 studs")
		PD.DistLbl.TextSize = TextSize
	end)
	AddEspElement(PD, "HealthBar", nil, "HealthBar", EspLayout.BarSpace, function(Container)
		PD.HpBar = CreateBar(Container, true, true, HP_FULL,
			{ Gradient = true, Border = true, BorderColor = Esp.BarColor })
		CreateStoredDamage(PD.HpBar, Esp.StoredColor)
	end)
	AddEspElement(PD, "StamBar", nil, "StamBar", EspLayout.BarSpace, function(Container)
		PD.StamBar = CreateBar(Container, true, false, STAM_COLOR,
			{ Gradient = true, Border = true, BorderColor = Esp.BarColor })
	end)
	PD.NameEL = PD.Elements[1]
	PD.DistEL = PD.Elements[2]
	PD.HpEL = PD.Elements[3]
	PD.StamEL = PD.Elements[4]
	Esp.Players[Player] = PD
end

local function ApplyEsp(Player, Char)
	if not Esp.On or Player == LP then return end
	if not Char or not Char.Parent then return end
	CreateEspBill(Player, Char)
end

local function SetupPlayerEsp(Player)
	if Player == LP then return end
	Esp.Players[Player] = Esp.Players[Player] or {}
	local PD = Esp.Players[Player]
	PD.Player = Player
	if PD.CharConn then pcall(function() PD.CharConn:Disconnect() end); PD.CharConn = nil end
	PD.CharConn = Player.CharacterAdded:Connect(function(Char)
		task.spawn(function()
			if not Shared.Alive or not Esp.On then return end
			if not WaitChar(Char) then return end
			if not Shared.Alive or not Esp.On or GetCharacter(Player) ~= Char then return end
			ApplyEsp(Player, Char)
		end)
	end)
	if GetCharacter(Player) then
		local Char = GetCharacter(Player)
		task.spawn(function()
			if not Shared.Alive or not Esp.On then return end
			if not WaitChar(Char) then return end
			if not Shared.Alive or not Esp.On or GetCharacter(Player) ~= Char then return end
			ApplyEsp(Player, Char)
		end)
	end
end

local function UpdateEspBar(Bar, Ratio, Color)
	if not Bar then return end
	local Value = Ratio or 0
	local Last = Bar.LastRatio
	if Last ~= nil and math.abs(Value - Last) <= 0.004 then return end
	Bar.LastRatio = Value
	SizeBarFill(Bar, Value)
	if Color and Bar.LastColor ~= Color then
		Bar.LastColor = Color
		Bar.Fill.BackgroundColor3 = Color
	end
end

local function ApplyFade(PD, Alpha)
	if PD.LastAlpha == Alpha then return end
	PD.LastAlpha = Alpha
	if PD.NameLbl then
		PD.NameLbl.TextTransparency = Alpha
		PD.NameLbl.TextStrokeTransparency = Alpha
	end
	if PD.DistLbl then
		PD.DistLbl.TextTransparency = Alpha
		PD.DistLbl.TextStrokeTransparency = Alpha
	end
	SetBarTransparency(PD.HpBar, Alpha)
	SetBarTransparency(PD.StamBar, Alpha)
	for _, H in ipairs({ PD.BBBlack, PD.BBWhite }) do
		local Stroke = H and H:FindFirstChildOfClass("UIStroke")
		if Stroke and Stroke.Transparency ~= Alpha then Stroke.Transparency = Alpha end
	end
end

local function UpdateEsp()
	if not Shared.Alive or not Esp.On then return end
	local Now = tick()
	if Now - LastTick.Esp < Rates.Esp then return end
	LastTick.Esp = Now
	local MyChar = GetCharacter(LP)
	local MyRoot = MyChar and GetRoot(MyChar)
	if not MyRoot then return end
	local Cam = workspace.CurrentCamera
	local MyBase = SafePosOf(MyRoot)
	if Cam then
		local Subj = Cam.CameraSubject
		local MyHum = MyChar:FindFirstChildOfClass("Humanoid")
		if Subj and Subj ~= MyHum then
			MyBase = CameraPos()
		end
	end
	local MyPos = MyBase or CameraPos()
	if not MyPos then return end
	local CamCF = Cam and Cam.CFrame
	local MaxDistSq = Esp.MaxDist * Esp.MaxDist
	local NameSpace = math.max(EspLayout.NameSpace, math.floor(EspLayout.NameSpace * Shared.EspSize))
	local PassId = Esp.PassId + 1
	Esp.PassId = PassId
	local Cand = Esp.Cand
	local Count = 0
	local MyParty = (Esp.MarkAllies or Esp.HideIfAlly) and GetPartyValue(LP) or nil
	for Player, PD0 in pairs(Esp.Players) do
		if Player ~= LP then
			local Ok, Err = pcall(function()
				local Char, Root = GetCharacterWithRoot(Player)
				if not Char or not Char.Parent or not Root then return end
				local RPos = SafePosOf(Root)
				local DistSq = RPos and DistSqBetween(RPos, MyPos) or nil
				if DistSq and DistSq <= MaxDistSq and InFront(RPos, CamCF) then
					PD0.CPass = PassId
					PD0.CDist = math.sqrt(DistSq)
					PD0.CChar = Char
					PD0.CRoot = Root
					Count = Count + 1
					Cand[Count] = PD0
				end
			end)
			if not Ok then ReportOnce("ESP scan (" .. Player.Name .. ")", Err) end
		end
	end
	for i = Count + 1, #Cand do Cand[i] = nil end
	table.sort(Cand, CandidateBefore, 1, Count)
	if Esp.MaxTargets > 0 and Count > Esp.MaxTargets then Count = Esp.MaxTargets end
	for Player, PD in pairs(Esp.Players) do
		if Player ~= LP and PD and PD.CPass ~= PassId and PD.Bill and PD.Bill.Enabled then
			PD.Bill.Enabled = false
		end
	end
	for i = 1, Count do
		local PD = Cand[i]
		local Player = PD.Player
		local Char = PD.CChar
		local Root = PD.CRoot
		local Dist = PD.CDist
		local Ok, Err = pcall(function()
			local Ally = MyParty ~= nil and GetPartyValue(Player) == MyParty
			if Esp.HideIfAlly and Ally then
				if PD.Bill and PD.Bill.Enabled then PD.Bill.Enabled = false end
				return
			end
			if not PD.Bill or PD.Root ~= Root or PD.Sides ~= BARS_KEY then
				CreateEspBill(Player, Char)
				PD = Esp.Players[Player]
				if not PD or not PD.Bill then return end
			end
			if not PD.Bill.Enabled then PD.Bill.Enabled = true end
			PD.Bill.Adornee = Root
			PD.BBBlack.Visible = Esp.BBox
			PD.BBWhite.Visible = Esp.BBox
			local Hum = PD.Hum
			if Hum and Hum.Parent then
				if not Hum:IsA("Humanoid") then PD.Hum = nil; Hum = nil end
			else
				PD.Hum = nil
				Hum = Char:FindFirstChildOfClass("Humanoid")
				if Hum then PD.Hum = Hum end
			end
			local HasHum = Hum and FiniteNumber(Hum.Health) and FiniteNumber(Hum.MaxHealth) and Hum.MaxHealth > 0
			local StamV, StamMax = GetStaminaBar(Player)
			if not HasHum then StamV, StamMax = nil, nil end
			local HasStam = StamV ~= nil and StamMax ~= nil
			PD.NameEL.Container.Visible = Esp.Name or Esp.HP or Esp.Stamina or Esp.Bounty
			PD.DistEL.Container.Visible = Esp.Dist
			PD.HpEL.Container.Visible = Esp.HPBar
			PD.StamEL.Container.Visible = Esp.StamBar and HasStam
			PD.NameEL.Space = NameSpace
			PD.DistEL.Space = NameSpace
			local LayoutKey = BARS_KEY
				.. tostring(Esp.Name) .. tostring(Esp.HP) .. tostring(Esp.Stamina)
				.. tostring(Esp.Bounty) .. tostring(Esp.Dist)
				.. tostring(Esp.HPBar) .. tostring(Esp.StamBar and HasStam)
				.. tostring(NameSpace) .. tostring(Esp.BBox)
			if PD.LayoutKey ~= LayoutKey then
				PD.LayoutKey = LayoutKey
				LayoutEsp(PD, Char)
			end
			local NameColor = (Esp.MarkAllies and Ally) and Esp.AllyColor or (Shared.EspProfile.Color or Esp.Color)
			if PD.NameLbl then
				Scratch.n = 0
				if Esp.Name then PushText(Player.Name) end
				if Esp.HP and HasHum then PushText(FormatTag(Hum.Health, Hum.MaxHealth)) end
				if Esp.Stamina and HasStam then PushText(FormatTag(StamV, StamMax)) end
				if Esp.Bounty then
					local B = GetBountyThrottled(Player, Now)
					if B then PushText("Bounty: " .. FormatNumber(B)) end
				end
				if Scratch.n == 1 then
					local NT = Scratch[1]
					if NT ~= PD.LastTxt then PD.NameLbl.Text = NT; PD.LastTxt = NT end
				elseif Scratch.n > 1 then
					local NT = table.concat(Scratch, " ", 1, Scratch.n)
					if NT ~= PD.LastTxt then PD.NameLbl.Text = NT; PD.LastTxt = NT end
				else
					if PD.LastTxt ~= "" then PD.NameLbl.Text = ""; PD.LastTxt = "" end
				end
				if PD.NameLbl.TextColor3 ~= NameColor then PD.NameLbl.TextColor3 = NameColor end
			end
			if PD.DistLbl then
				if Esp.Dist then
					local Studs = SafeStuds(Dist)
					if Studs then
						local DT = Studs .. " studs"
						if DT ~= PD.LastDistTxt then PD.DistLbl.Text = DT; PD.LastDistTxt = DT end
					elseif PD.LastDistTxt ~= "" then
						PD.DistLbl.Text = ""
						PD.LastDistTxt = ""
					end
				elseif PD.LastDistTxt ~= "" then
					PD.DistLbl.Text = ""
					PD.LastDistTxt = ""
				end
				if PD.DistLbl.TextColor3 ~= NameColor then PD.DistLbl.TextColor3 = NameColor end
			end
			local HR = HasHum and math.clamp(Hum.Health / Hum.MaxHealth, 0, 1) or nil
			UpdateEspBar(PD.HpBar, HR, LerpHp(HR))
			if PD.HpBar then
				SetBarSeparators(PD.HpBar, PD.HpBar.Vertical and Dist <= EspLayout.SepRange)
			end
			if HR and PD.LastHR and HR < PD.LastHR - 0.001 then
				PD.StoredRatio = math.min(PD.StoredRatio + (PD.LastHR - HR), 1 - HR)
				PD.StoredTime = Now
			end
			if HR then PD.LastHR = HR end
			if PD.HpBar then
				if Esp.Stored then
					local Stored = PD.StoredRatio
					if Stored > 0 then
						local Left = 1 - math.clamp((Now - PD.StoredTime) / 0.7, 0, 1)
						Stored = Stored * Left
						if Left <= 0 then PD.StoredRatio = 0 end
					end
					UpdateStoredDamage(PD.HpBar, HR, Stored)
				elseif PD.StoredRatio ~= 0 then
					PD.StoredRatio = 0
					UpdateStoredDamage(PD.HpBar, HR, 0)
				end
			end
			local SR = HasStam and math.clamp(StamV / StamMax, 0, 1) or nil
			UpdateEspBar(PD.StamBar, SR, STAM_COLOR)
			local Alpha = 0
			if Esp.Fade then
				Alpha = math.clamp((Dist - Esp.FadeDist) / math.max(Esp.FadeDist, 1), 0, 1) * 0.8
			end
			ApplyFade(PD, Alpha)
		end)
		if not Ok then ReportOnce("ESP draw (" .. Player.Name .. ")", Err) end
	end
end

local function EnableEsp()
	if not Shared.Alive then return end
	Esp.On = true
	local Resolved, Missing = 0, {}
	for _, P in ipairs(Services.Players:GetPlayers()) do
		if P ~= LP then
			local C = GetCharacter(P)
			if C and C.Parent and GetRoot(C) then
				Resolved = Resolved + 1
			else
				Missing[#Missing + 1] = P.Name
			end
		end
	end
	warn("[Aero] ESP: " .. Resolved .. " character(s) with a root; unresolved: "
		.. (#Missing > 0 and table.concat(Missing, ", ") or "none"))
	for _, P in ipairs(Services.Players:GetPlayers()) do
		if P ~= LP then SetupPlayerEsp(P) end
	end
	StoredDisconnect(Conns.PlayerAdded)
	Conns.PlayerAdded = Library:Connect(Services.Players.PlayerAdded, function(P)
		if Shared.Alive and Esp.On then SetupPlayerEsp(P) end
	end)
	StoredDisconnect(Conns.PlayerRemoving)
	Conns.PlayerRemoving = Library:Connect(Services.Players.PlayerRemoving, function(P)
		RemovePlayerEsp(P)
	end)
	Shared.Sync()
end

local function DisableEsp()
	Esp.On = false
	StoredDisconnect(Conns.PlayerAdded)
	Conns.PlayerAdded = nil
	StoredDisconnect(Conns.PlayerRemoving)
	Conns.PlayerRemoving = nil
	ClearEsp()
	Shared.Sync()
end

local function RefreshEspBars()
	if not Esp.On then return end
	for _, PD in pairs(Esp.Players) do
		if PD then PD.LayoutKey = nil end
	end
end

local function ResizeLabels()
	for _, PD in pairs(Esp.Players) do
		if PD then
			local Size = EspTextSize(Shared.EspSize)
			if PD.NameLbl then
				PD.NameLbl.TextSize = Size
				ApplyFont(PD.NameLbl)
			end
			if PD.DistLbl then
				PD.DistLbl.TextSize = Size
				ApplyFont(PD.DistLbl)
			end
			PD.LayoutKey = nil
			PD.LastAlpha = nil
		end
	end
end

Shared.RegisterEspSize(ResizeLabels)
Shared.RegisterEsp(function() return Esp.On end, UpdateEsp)

local SectionPlayer = EspPage:Section({ Name = "Player ESP", Side = 1 })

SectionPlayer:Toggle({
	Name = "Enable",
	Flag = "gpoEspToggle",
	Default = false,
	Callback = function(Value)
		if Value then EnableEsp() else DisableEsp() end
	end,
})
SectionPlayer:Slider({
	Name = "ESP Size",
	Flag = "gpoEspSize",
	Min = 0.5,
	Max = 3,
	Default = 1,
	Decimals = 1,
	Callback = function(Value)
		Shared.SetEspSize(Value)
	end,
})
SectionPlayer:Label("ESP Color"):Colorpicker({
	Name = "ESP Color",
	Flag = "gpoEspPreviewColor",
	Default = Color3.fromRGB(255, 255, 255),
	Callback = function(Color)
		Shared.EspProfile.Color = Color
		Esp.Color = Color
		RefreshEspBars()
	end,
})
SectionPlayer:Toggle({
	Name = "Name",
	Flag = "gpoEspName",
	Default = true,
	Callback = function(Value)
		Esp.Name = Value
	end,
})
SectionPlayer:Toggle({
	Name = "Bounty",
	Flag = "gpoEspBounty",
	Default = true,
	Callback = function(Value)
		Esp.Bounty = Value
	end,
})
SectionPlayer:Toggle({
	Name = "Health",
	Flag = "gpoEspHealth",
	Default = true,
	Callback = function(Value)
		Esp.HP = Value
	end,
})
SectionPlayer:Toggle({
	Name = "Stamina",
	Flag = "gpoEspStamina",
	Default = true,
	Callback = function(Value)
		Esp.Stamina = Value
	end,
})
SectionPlayer:Toggle({
	Name = "Mark Allies",
	Flag = "gpoEspMarkAllies",
	Default = false,
	Callback = function(Value)
		Esp.MarkAllies = Value
		RefreshEspBars()
	end,
})
SectionPlayer:Toggle({
	Name = "Hide Allies",
	Flag = "gpoEspHideIfAlly",
	Default = false,
	Callback = function(Value)
		Esp.HideIfAlly = Value
		RefreshEspBars()
	end,
})
SectionPlayer:Toggle({
	Name = "Distance",
	Flag = "gpoEspDistance",
	Default = true,
	Callback = function(Value)
		Esp.Dist = Value
		RefreshEspBars()
	end,
})
SectionPlayer:Toggle({
	Name = "Bounding Box",
	Flag = "gpoEspBoundingBox",
	Default = false,
	Callback = function(Value)
		Esp.BBox = Value
		RefreshEspBars()
	end,
})
SectionPlayer:Slider({
	Name = "ESP Distance",
	Flag = "gpoEspMaxDist",
	Min = 100,
	Max = 50000,
	Default = 5000,
	Decimals = 0,
	Suffix = " studs",
	Callback = function(Value)
		Esp.MaxDist = Value
	end,
})
SectionPlayer:Slider({
	Name = "Max Targets",
	Flag = "gpoEspMaxTargets",
	Min = 1,
	Max = 20,
	Default = 8,
	Decimals = 0,
	Callback = function(Value)
		Esp.MaxTargets = Value
	end,
})
SectionPlayer:Toggle({
	Name = "Fade With Distance",
	Flag = "gpoEspFade",
	Default = false,
	Callback = function(Value)
		Esp.Fade = Value
		for _, PD in pairs(Esp.Players) do
			if PD then PD.LastAlpha = nil end
		end
	end,
})
SectionPlayer:Slider({
	Name = "Fade Distance",
	Flag = "gpoEspFadeDist",
	Min = 50,
	Max = 5000,
	Default = 250,
	Decimals = 0,
	Suffix = " studs",
	Callback = function(Value)
		Esp.FadeDist = Value
		for _, PD in pairs(Esp.Players) do
			if PD then PD.LastAlpha = nil end
		end
	end,
})
SectionPlayer:Toggle({
	Name = "Health Bar",
	Flag = "gpoEspHpBar",
	Default = true,
	Callback = function(Value)
		Esp.HPBar = Value
		RefreshEspBars()
	end,
})
SectionPlayer:Toggle({
	Name = "Stamina Bar",
	Flag = "gpoEspStamBar",
	Default = true,
	Callback = function(Value)
		Esp.StamBar = Value
		RefreshEspBars()
	end,
})
SectionPlayer:Toggle({
	Name = "Stored Damage",
	Flag = "gpoEspStoredDamage",
	Default = true,
	Callback = function(Value)
		Esp.Stored = Value
	end,
})

-- Chest ESP

local ChestTypes = {
	{ Type = "Rare", Color = Color3.fromRGB(80, 220, 255) },
	{ Type = "Legendary", Color = Color3.fromRGB(255, 200, 40) },
	{ Type = "Mythical", Color = Color3.fromRGB(255, 80, 255) },
	{ Type = "Common", Color = Color3.fromRGB(210, 210, 210) },
	{ Type = "Uncommon", Color = Color3.fromRGB(90, 220, 120) },
}
local ChestEsp = {
	On = false,
	Name = true, Dist = true,
	MaxDist = 5000, Size = 1.0,
	Entities = {},
	Cache = nil,
	Filter = {},
	PassId = 0,
}
ChestEsp.Filter["Mythical"] = true
ChestEsp.Filter["Legendary"] = true
local ChestTypeByLower = {}
for _, CT in ipairs(ChestTypes) do
	ChestTypeByLower[string.lower(CT.Type)] = CT
end
local ChestTypeCache = setmetatable({}, { __mode = "k" })
local function ChestTypeFor(P)
	if not P:IsA("BasePart") then return nil end
	local Prompt = P:FindFirstChildOfClass("ProximityPrompt")
	if not Prompt then return nil end
	local Item = Prompt:GetAttribute("itemName")
	if typeof(Item) ~= "string" then return nil end
	local Name = string.match(Item, "^(.-)%s*[Cc]hest$")
	if not Name then return nil end
	local Known = ChestTypeByLower[string.lower(Name)]
	if Known then return Known end
	local Custom = ChestTypeCache[P]
	if not Custom or Custom.Type ~= Name then
		Custom = { Type = Name, Color = Color3.fromRGB(255, 255, 255) }
		ChestTypeCache[P] = Custom
	end
	return Custom
end
local function ChestTypeEnabled(Type)
	return ChestEsp.Filter[Type] == true
end
local function ReindexChests()
	ChestEsp.Cache = setmetatable({}, { __mode = "k" })
	local C = ChestEsp.Cache
	for _, Inst in ipairs(workspace:GetDescendants()) do
		if Inst:IsA("ProximityPrompt") then
			local Parent = Inst.Parent
			if Parent and Parent:IsA("BasePart") and not C[Parent] and ChestTypeFor(Parent) then
				C[Parent] = true
			end
		end
	end
end
local function OnChestDescendantAdded(Inst)
	if not ChestEsp.On then return end
	if not Inst:IsA("ProximityPrompt") then return end
	local Parent = Inst.Parent
	if not Parent or not Parent:IsA("BasePart") then return end
	local C = ChestEsp.Cache
	if not C then return end
	if not C[Parent] and ChestTypeFor(Parent) then
		C[Parent] = true
	end
end
local function OnChestDescendantRemoving(Inst)
	local C = ChestEsp.Cache
	if not C then return end
	if Inst:IsA("BasePart") then
		C[Inst] = nil
	elseif Inst:IsA("ProximityPrompt") and Inst.Parent and Inst.Parent:IsA("BasePart") then
		C[Inst.Parent] = nil
	end
end
local function ResizeChestLabels()
	for _, ED in pairs(ChestEsp.Entities) do
		if ED and ED.Lbl then LayoutEspLabels(ED, Shared.EspSize) end
	end
end
local function UpdateChestEsp()
	if not Shared.Alive or not ChestEsp.On then return end
	local Now = tick()
	if Now - LastTick.Chest < Rates.Chest then return end
	LastTick.Chest = Now
	local MyChar = LP.Character
	local MyRoot = MyChar and GetRoot(MyChar)
	if not MyRoot then return end
	local MyPos = SafePosOf(MyRoot) or CameraPos()
	if not MyPos then return end
	local MaxDistSq = ChestEsp.MaxDist * ChestEsp.MaxDist
	local Cam = workspace.CurrentCamera
	local CamCF = Cam and Cam.CFrame
	if (not ChestEsp.Cache or not next(ChestEsp.Cache)) and Now - (LastTick.ChestIndex or 0) > 5 then
		LastTick.ChestIndex = Now
		ReindexChests()
	end
	local PassId = ChestEsp.PassId + 1
	ChestEsp.PassId = PassId
	local Refresh = Now - (LastTick.ChestType or 0) > 2
	if Refresh then LastTick.ChestType = Now end
	for P in pairs(ChestEsp.Cache) do
		local ED = ChestEsp.Entities[P]
		local CT = ED and ED.CType
		if CT == nil or Refresh then
			CT = ChestTypeFor(P)
		end
		if P.Parent and CT and ChestTypeEnabled(CT.Type) then
			if not ED then
				ED = {}
				ChestEsp.Entities[P] = ED
			end
			ED.CPass = PassId
			ED.CType = CT
		end
	end
	for P, ED in pairs(ChestEsp.Entities) do
		if ED.CPass ~= PassId then
			if ED.Bill then pcall(function() ED.Bill:Destroy() end) end
			ChestEsp.Entities[P] = nil
		end
	end
	for P, ED in pairs(ChestEsp.Entities) do
		local RPos = SafePosOf(P)
		local DistSq = RPos and DistSqBetween(RPos, MyPos) or nil
		if not DistSq or DistSq > MaxDistSq or not InFront(RPos, CamCF) then
			if ED.Bill and ED.Bill.Enabled then ED.Bill.Enabled = false end
		else
			pcall(function()
				local CT = ED.CType
				if not P.Parent or not CT then return end
				if not ED.Bill or ED.Bill.Adornee ~= P then
					local BG = Instance.new("BillboardGui")
					BG.Name = "ChestESP"
					BG.Adornee = P
					BG.StudsOffsetWorldSpace = Vector3.new(0, P.Size.Y + 1.2, 0)
					BG.AlwaysOnTop = true
					BG.ResetOnSpawn = false
					BG.LightInfluence = 0
					BG.Parent = P
					local Lbl = Instance.new("TextLabel")
					Lbl.Text = ""
					Lbl.Parent = BG
					local DistLbl = Instance.new("TextLabel")
					DistLbl.Text = ""
					DistLbl.Parent = BG
					BG.Size = UDim2.new(0, 200, 0, 120)
					ED.Bill = BG
					ED.Lbl = Lbl
					ED.DistLbl = DistLbl
					ED.Type = nil
					Lbl.TextColor3 = CT.Color
					DistLbl.TextColor3 = CT.Color
					LayoutEspLabels(ED, Shared.EspSize)
				end
				if ED.Type ~= CT then
					ED.Type = CT
					ED.LastTxt = nil
				end
				ED.Lbl.TextColor3 = CT.Color
				local Dist = math.sqrt(DistSq)
				if not ED.Bill.Enabled then ED.Bill.Enabled = true end
				if ChestEsp.Name then
					if ED.LastTxt ~= CT.Type then ED.Lbl.Text = CT.Type; ED.LastTxt = CT.Type end
				elseif ED.LastTxt ~= "" then
					ED.Lbl.Text = ""
					ED.LastTxt = ""
				end
				SetEspDistance(ED, ChestEsp.Dist, Dist, CT.Color)
			end)
		end
	end
end
local function EnableChestEsp()
	if not Conns.ChestAdded then
		ReindexChests()
		Conns.ChestAdded = Library:Connect(workspace.DescendantAdded, OnChestDescendantAdded)
		Conns.ChestRemoved = Library:Connect(workspace.DescendantRemoving, OnChestDescendantRemoving)
	end
	Shared.Sync()
end
local function DisableChestEsp()
	StoredDisconnect(Conns.ChestAdded)
	Conns.ChestAdded = nil
	StoredDisconnect(Conns.ChestRemoved)
	Conns.ChestRemoved = nil
	for _, ED in pairs(ChestEsp.Entities) do
		if ED and ED.Bill then pcall(function() ED.Bill:Destroy() end) end
	end
	ChestEsp.Entities = {}
	ChestEsp.Cache = nil
	Shared.Sync()
end

local SectionChest = EspPage:Section({ Name = "Chest ESP", Side = 1 })

SectionChest:Toggle({
	Name = "Enable",
	Flag = "gpoChestEspToggle",
	Default = false,
	Callback = function(Value)
		ChestEsp.On = Value
		if Value then EnableChestEsp() else DisableChestEsp() end
	end,
})
SectionChest:Toggle({
	Name = "Type",
	Flag = "gpoChestEspName",
	Default = true,
	Callback = function(Value)
		ChestEsp.Name = Value
	end,
})
SectionChest:Toggle({
	Name = "Distance",
	Flag = "gpoChestEspDistance",
	Default = true,
	Callback = function(Value)
		ChestEsp.Dist = Value
	end,
})
SectionChest:Slider({
	Name = "ESP Distance",
	Flag = "gpoChestEspMaxDist",
	Min = 100,
	Max = 50000,
	Default = 5000,
	Decimals = 0,
	Suffix = " studs",
	Callback = function(Value)
		ChestEsp.MaxDist = Value
	end,
})
local ChestTypeValues = {}
for _, CT in ipairs(ChestTypes) do
	ChestTypeValues[#ChestTypeValues + 1] = CT.Type
end
SectionChest:Dropdown({
	Name = "Types",
	Flag = "gpoChestEspTypes",
	Values = ChestTypeValues,
	Default = { "Mythical", "Legendary" },
	Multi = true,
	MaxSize = 100,
	Callback = function(Value)
		ChestEsp.Filter = {}
		for _, Type in ipairs(Value) do
			ChestEsp.Filter[Type] = true
		end
	end,
})

-- Island ESP

local IslandEsp = {
	On = false,
	Name = true, Dist = true,
	MaxDist = 50000, Size = 1.0,
	Color = Color3.fromRGB(130, 220, 255),
	Entities = {},
	Cache = nil,
	Indexed = false,
}
local function IslandsFolder()
	return workspace:FindFirstChild("Islands")
end
local function IslandInfo(Inst)
	local Model, Base
	if Inst:IsA("BasePart") then
		Model, Base = Inst, Inst
	elseif Inst:IsA("Model") then
		Model = Inst
		Base = Inst.PrimaryPart or Inst:FindFirstChildWhichIsA("BasePart")
	end
	if not Base or not Base.Parent then return nil end
	local Top = Base.Position.Y
	if Model:IsA("Model") then
		for _, Desc in ipairs(Model:GetDescendants()) do
			if Desc:IsA("BasePart") then
				local Ceil = Desc.Position.Y + Desc.Size.Y * 0.5
				if Ceil > Top then Top = Ceil end
			end
		end
	end
	return {
		Base = Base,
		Label = Model.Name,
		Offset = Vector3.new(0, Top - Base.Position.Y + 3, 0),
	}
end
local function ReindexIslands()
	local Folder = IslandsFolder()
	if not Folder then return false end
	local C = setmetatable({}, { __mode = "k" })
	IslandEsp.Cache = C
	for _, Inst in ipairs(Folder:GetChildren()) do
		local Info = IslandInfo(Inst)
		if Info then C[Inst] = Info end
	end
	IslandEsp.Indexed = true
	return true
end
local function OnIslandChildAdded(Inst)
	if not IslandEsp.On then return end
	local C = IslandEsp.Cache
	if not C then return end
	local Info = IslandInfo(Inst)
	if Info then C[Inst] = Info end
end
local function OnIslandChildRemoving(Inst)
	local C = IslandEsp.Cache
	if not C then return end
	C[Inst] = nil
end
local function ResizeIslandLabels()
	for _, ED in pairs(IslandEsp.Entities) do
		if ED and ED.Lbl then LayoutEspLabels(ED, Shared.EspSize) end
	end
end
local function UpdateIslandEsp()
	if not Shared.Alive or not IslandEsp.On then return end
	local Now = tick()
	if Now - (LastTick.Island or 0) < Rates.Island then return end
	LastTick.Island = Now
	local Folder = IslandsFolder()
	if not Folder then
		if not IslandEsp.Warned then
			IslandEsp.Warned = true
			warn("[GPO] Island ESP: workspace.Islands no existe")
		end
		return
	end
	if not IslandEsp.Indexed then ReindexIslands() end
	if Now - (LastTick.IslandIndex or 0) > 5 then
		LastTick.IslandIndex = Now
		ReindexIslands()
	end
	local C = IslandEsp.Cache
	if not C then return end
	local MyRoot = GetRoot(GetCharacter(LP))
	if not MyRoot then return end
	local MyPos = SafePosOf(MyRoot) or CameraPos()
	if not MyPos then return end
	local MaxDistSq = IslandEsp.MaxDist * IslandEsp.MaxDist
	local Cam = workspace.CurrentCamera
	local CamCF = Cam and Cam.CFrame
	local WantName = IslandEsp.Name
	local WantDist = IslandEsp.Dist
	local Col = IslandEsp.Color
	for Inst, Info in pairs(C) do
		local Base = Info and Info.Base
		if Base and Base.Parent then
			local ED = IslandEsp.Entities[Inst]
			local RPos = SafePosOf(Base)
			local DistSq = RPos and DistSqBetween(RPos, MyPos) or nil
			local Show = DistSq ~= nil and DistSq <= MaxDistSq and InFront(RPos, CamCF)
			if not ED or not ED.Bill or ED.Bill.Adornee ~= Base then
				if ED and ED.Bill then pcall(function() ED.Bill:Destroy() end) end
				if Show then
					local BG = Instance.new("BillboardGui")
					BG.Name = "IslandESP"
					BG.Adornee = Base
					BG.StudsOffsetWorldSpace = Info.Offset
					BG.AlwaysOnTop = true
					BG.ResetOnSpawn = false
					BG.LightInfluence = 0
					BG.Size = UDim2.new(0, 200, 0, 120)
					BG.Parent = Base
					local Lbl = Instance.new("TextLabel")
					Lbl.Text = ""
					Lbl.Parent = BG
					local DistLbl = Instance.new("TextLabel")
					DistLbl.Text = ""
					DistLbl.Parent = BG
					ED = { Bill = BG, Lbl = Lbl, DistLbl = DistLbl }
					Lbl.TextColor3 = Col
					DistLbl.TextColor3 = Col
					LayoutEspLabels(ED, Shared.EspSize)
					IslandEsp.Entities[Inst] = ED
				end
			end
			if ED then
				if Show then
					if not ED.Bill.Enabled then ED.Bill.Enabled = true end
					if WantName then
						if ED.LastTxt ~= Info.Label then ED.Lbl.Text = Info.Label; ED.LastTxt = Info.Label end
					elseif ED.LastTxt ~= "" then
						ED.Lbl.Text = ""
						ED.LastTxt = ""
					end
					if ED.Lbl.TextColor3 ~= Col then ED.Lbl.TextColor3 = Col end
					SetEspDistance(ED, WantDist, math.sqrt(DistSq), Col)
				elseif ED.Bill.Enabled then
					ED.Bill.Enabled = false
				end
			end
		else
			local ED = IslandEsp.Entities[Inst]
			if ED and ED.Bill then pcall(function() ED.Bill:Destroy() end) end
			IslandEsp.Entities[Inst] = nil
		end
	end
	for Inst, ED in pairs(IslandEsp.Entities) do
		if C[Inst] == nil then
			if ED and ED.Bill then pcall(function() ED.Bill:Destroy() end) end
			IslandEsp.Entities[Inst] = nil
		end
	end
end
local function EnableIslandEsp()
	if not Conns.IslandAdded then
		local Folder = IslandsFolder()
		if Folder then
			ReindexIslands()
			Conns.IslandAdded = Library:Connect(Folder.ChildAdded, OnIslandChildAdded)
			Conns.IslandRemoved = Library:Connect(Folder.ChildRemoved, OnIslandChildRemoving)
		end
	end
	Shared.Sync()
end
local function DisableIslandEsp()
	StoredDisconnect(Conns.IslandAdded)
	Conns.IslandAdded = nil
	StoredDisconnect(Conns.IslandRemoved)
	Conns.IslandRemoved = nil
	for _, ED in pairs(IslandEsp.Entities) do
		if ED and ED.Bill then pcall(function() ED.Bill:Destroy() end) end
	end
	IslandEsp.Entities = {}
	IslandEsp.Cache = nil
	IslandEsp.Indexed = false
	Shared.Sync()
end

local SectionIsland = EspPage:Section({ Name = "Island ESP", Side = 1 })

SectionIsland:Toggle({
	Name = "Enable",
	Flag = "gpoIslandEspToggle",
	Default = false,
	Callback = function(Value)
		IslandEsp.On = Value
		if Value then EnableIslandEsp() else DisableIslandEsp() end
	end,
})
SectionIsland:Toggle({
	Name = "Name",
	Flag = "gpoIslandEspName",
	Default = true,
	Callback = function(Value)
		IslandEsp.Name = Value
	end,
})
SectionIsland:Toggle({
	Name = "Distance",
	Flag = "gpoIslandEspDistance",
	Default = true,
	Callback = function(Value)
		IslandEsp.Dist = Value
	end,
})
SectionIsland:Slider({
	Name = "ESP Distance",
	Flag = "gpoIslandEspMaxDist",
	Min = 100,
	Max = 200000,
	Default = 50000,
	Decimals = 0,
	Suffix = " studs",
	Callback = function(Value)
		IslandEsp.MaxDist = Value
	end,
})

-- Entity ESP (NPC + Mob)

local NpcEsp = {
	On = false,
	Kind = "Npc",
	Color = Color3.fromRGB(255, 231, 122),
	Name = true, Dist = true, MaxDist = 5000, Size = 1.0,
	Entities = {},
	LastTick = 0,
	Folder = nil,
	DeepAt = 0,
	DeepCache = nil,
}
local MobEsp = {
	On = false,
	Kind = "Mob",
	Color = Color3.fromRGB(255, 96, 120),
	Name = true, HP = true, Dist = true, MaxDist = 5000, Size = 1.0,
	Entities = {},
	LastTick = 0,
}
local EntityMods = { NpcEsp, MobEsp }
local function InDeadFolder(M)
	local P = M.Parent
	while P do
		local N = P.Name
		if N == "Ragdolls" or N == "Effects" then return true end
		P = P.Parent
	end
	return false
end
local function HasEntities(Folder)
	for _, D in ipairs(Folder:GetChildren()) do
		if D:IsA("Model") then
			local Info = D:FindFirstChild("Info")
			if Info and Info:FindFirstChild("Hostile") then return true end
		end
	end
	return false
end
local function ResolveNpcFolder()
	local Cached = NpcEsp.Folder
	if Cached and Cached.Parent and HasEntities(Cached) then return Cached end
	local Want = { npcs = true, npc = true, entities = true, liveng = true }
	for _, A in ipairs(workspace:GetChildren()) do
		local Lower = string.lower(A.Name)
		if Want[Lower] and (A:IsA("Folder") or A:IsA("Model"))
			and not InDeadFolder(A) and HasEntities(A) then
			NpcEsp.Folder = A
			return A
		end
		for _, B in ipairs(A:GetChildren()) do
			if Want[string.lower(B.Name)] and (B:IsA("Folder") or B:IsA("Model"))
				and not InDeadFolder(B) and HasEntities(B) then
				NpcEsp.Folder = B
				return B
			end
		end
	end
	NpcEsp.Folder = nil
	return nil
end
local function DeepScanEntities()
	local Now = tick()
	if NpcEsp.DeepAt and Now - NpcEsp.DeepAt < 2 then
		return NpcEsp.DeepCache or {}
	end
	NpcEsp.DeepAt = Now
	local Found = {}
	for _, D in ipairs(workspace:GetDescendants()) do
		if D:IsA("Model") then
			local Info = D:FindFirstChild("Info")
			local Hostile = Info and Info:FindFirstChild("Hostile")
			if Hostile and typeof(Hostile.Value) == "boolean" and not InDeadFolder(D) then
				Found[#Found + 1] = D
			end
		end
	end
	NpcEsp.DeepCache = Found
	return Found
end
local function GetEntityKind(M)
	if not M or M.ClassName ~= "Model" then return nil end
	if not M:FindFirstChildOfClass("Humanoid") then return nil end
	local Root = M:FindFirstChild("HumanoidRootPart")
	local Head = M:FindFirstChild("Head")
	if not Root and not Head then
		Root = M:FindFirstChildWhichIsA("BasePart")
		if not Root then return nil end
	end
	local Info = M:FindFirstChild("Info")
	local Hostile = Info and Info:FindFirstChild("Hostile")
	if Hostile and Hostile.Value == true then return "Mob" end
	return "Npc"
end
local function MakeEntityBill(M, Mod)
	local Head = M:FindFirstChild("Head")
	local Root = Head or GetRoot(M)
	if not Root then return end
	local ED = Mod.Entities[M]
	if ED and ED.Bill then
		if ED.Bill.Parent == Root then
			ED.Head = Head
			return
		end
		pcall(function() ED.Bill:Destroy() end)
		ED.Bill = nil; ED.Lbl = nil; ED.DistLbl = nil; ED.LastTxt = nil; ED.LastDistTxt = nil
	end
	local YOff = Head and 2.5 or 3.5
	local BG = Instance.new("BillboardGui")
	BG.Name = "EntityESP"
	BG.Adornee = Root
	BG.StudsOffsetWorldSpace = Vector3.new(0, YOff, 0)
	BG.AlwaysOnTop = true
	BG.ResetOnSpawn = false
	BG.LightInfluence = 0
	BG.Parent = Root
	local Lbl = Instance.new("TextLabel")
	Lbl.Text = ""
	Lbl.Parent = BG
	local DistLbl = Instance.new("TextLabel")
	DistLbl.Text = ""
	DistLbl.Parent = BG
	BG.Size = UDim2.new(0, 200, 0, 120)
	ED = { Bill = BG, Lbl = Lbl, DistLbl = DistLbl, Kind = Mod.Kind, Head = Head }
	Lbl.TextColor3 = Mod.Color
	DistLbl.TextColor3 = Mod.Color
	LayoutEspLabels(ED, Shared.EspSize)
	Mod.Entities[M] = ED
end
local function ResizeEntityLabels(Mod)
	for _, ED in pairs(Mod.Entities) do
		if ED and ED.Bill and ED.Lbl then LayoutEspLabels(ED, Shared.EspSize) end
	end
end
local function UpdateEntityEsp()
	if not Shared.Alive then return end
	local Now = tick()
	if Now - LastTick.Entity < Rates.Entity then return end
	LastTick.Entity = Now
	local NpcsFolder = ResolveNpcFolder()
	local MyChar = LP.Character
	local MyRoot = MyChar and GetRoot(MyChar)
	if not MyRoot then return end
	local MyPos = SafePosOf(MyRoot) or CameraPos()
	if not MyPos then return end
	local Cam = workspace.CurrentCamera
	local CamCF = Cam and Cam.CFrame
	if Now - (LastTick.EntityScan or 0) > 0.5 then
		LastTick.EntityScan = Now
		local Kids = NpcsFolder and NpcsFolder:GetChildren() or DeepScanEntities()
		for i = 1, #Kids do
			local M = Kids[i]
			local Kind = GetEntityKind(M)
			for j = 1, #EntityMods do
				local Mod = EntityMods[j]
				local ED = Mod.Entities[M]
				if ED and ED.Kind and ED.Kind ~= Kind then
					if ED.Bill then pcall(function() ED.Bill:Destroy() end) end
					Mod.Entities[M] = nil
					ED = nil
				end
				if Kind == Mod.Kind and Mod.On then
					MakeEntityBill(M, Mod)
				end
			end
		end
		for j = 1, #EntityMods do
			local Mod = EntityMods[j]
			for M, ED in pairs(Mod.Entities) do
				if not M.Parent or GetEntityKind(M) ~= Mod.Kind or InDeadFolder(M) then
					if ED.Bill then pcall(function() ED.Bill:Destroy() end) end
					Mod.Entities[M] = nil
				end
			end
		end
	end
	for i = 1, #EntityMods do
		local Mod = EntityMods[i]
		if not Mod.On then continue end
		local MaxDistSq = Mod.MaxDist * Mod.MaxDist
		for M, ED in pairs(Mod.Entities) do
			if not M.Parent then
				if ED.Bill then pcall(function() ED.Bill:Destroy() end) end
				Mod.Entities[M] = nil
			else
				pcall(function()
					local Head = ED.Head
					if not Head or not Head.Parent then
						Head = M:FindFirstChild("Head")
						ED.Head = Head
					end
					local Root = Head or GetRoot(M)
					if not Root then
						if ED.Bill and ED.Bill.Enabled then ED.Bill.Enabled = false end
						return
					end
					if not ED.Bill or ED.Bill.Parent ~= Root then
						MakeEntityBill(M, Mod)
						ED = Mod.Entities[M]
						if not ED then return end
					end
					local RPos = SafePosOf(Root)
					local DistSq = RPos and DistSqBetween(RPos, MyPos) or nil
					local Dist = DistSq and math.sqrt(DistSq) or nil
					if not DistSq or DistSq > MaxDistSq or not InFront(RPos, CamCF) then
						if ED.Bill.Enabled then ED.Bill.Enabled = false end
						return
					end
					if not ED.Bill.Enabled then ED.Bill.Enabled = true end
					local Hum = ED.Hum
					if Hum and Hum.Parent then
						if not Hum:IsA("Humanoid") then ED.Hum = nil; Hum = nil end
					else
						ED.Hum = nil
						Hum = M:FindFirstChildOfClass("Humanoid")
						if Hum then ED.Hum = Hum end
					end
					Scratch.n = 0
					if Mod.Name then PushText(M.Name) end
					if Mod.HP and Hum and FiniteNumber(Hum.Health) and FiniteNumber(Hum.MaxHealth) and Hum.MaxHealth > 0 then
						local Pct = math.floor(math.clamp(Hum.Health / Hum.MaxHealth, 0, 1) * 100 + 0.5)
						if ED.LastPct ~= Pct then
							ED.LastPct = Pct
							ED.PctTxt = "[" .. Pct .. "%]"
						end
						if ED.PctTxt then PushText(ED.PctTxt) end
					else
						ED.LastPct = nil
						ED.PctTxt = nil
					end
					if Scratch.n == 1 then
						local NT = Scratch[1]
						if NT ~= ED.LastTxt then
							ED.Lbl.Text = NT
							ED.LastTxt = NT
						end
					else
						local NT = table.concat(Scratch, "\n", 1, Scratch.n)
						if NT ~= ED.LastTxt then
							ED.Lbl.Text = NT
							ED.LastTxt = NT
						end
					end
					local Ec = Shared.EspProfile.Color or Mod.Color
					if ED.Lbl.TextColor3 ~= Ec then ED.Lbl.TextColor3 = Ec end
					SetEspDistance(ED, Mod.Dist, Dist, Ec)
				end)
			end
		end
	end
end
local function ClearEntityMod(Mod)
	for M, ED in pairs(Mod.Entities) do
		if ED and ED.Bill then pcall(function() ED.Bill:Destroy() end) end
	end
	Mod.Entities = {}
end
local function SyncEntityEsp()
	if NpcEsp.On or MobEsp.On then
		Shared.Sync()
	else
		ClearEntityMod(NpcEsp)
		ClearEntityMod(MobEsp)
		Shared.Sync()
	end
end

local SectionEntityNpc = EspPage:Section({ Name = "Entity ESP", Side = 1 })

SectionEntityNpc:Toggle({
	Name = "NPC Enable",
	Flag = "gpoNpcEspToggle",
	Default = false,
	Callback = function(Value)
		NpcEsp.On = Value
		SyncEntityEsp()
	end,
})
SectionEntityNpc:Toggle({
	Name = "Name",
	Flag = "gpoNpcEspName",
	Default = true,
	Callback = function(Value)
		NpcEsp.Name = Value
	end,
})
SectionEntityNpc:Toggle({
	Name = "Distance",
	Flag = "gpoNpcEspDistance",
	Default = true,
	Callback = function(Value)
		NpcEsp.Dist = Value
	end,
})
SectionEntityNpc:Slider({
	Name = "ESP Distance",
	Flag = "gpoNpcEspMaxDist",
	Min = 100,
	Max = 50000,
	Default = 5000,
	Decimals = 0,
	Suffix = " studs",
	Callback = function(Value)
		NpcEsp.MaxDist = Value
	end,
})
SectionEntityNpc:Toggle({
	Name = "Mob Enable",
	Flag = "gpoMobEspToggle",
	Default = false,
	Callback = function(Value)
		MobEsp.On = Value
		SyncEntityEsp()
	end,
})
SectionEntityNpc:Toggle({
	Name = "Mob Name",
	Flag = "gpoMobEspName",
	Default = true,
	Callback = function(Value)
		MobEsp.Name = Value
	end,
})
SectionEntityNpc:Toggle({
	Name = "Mob Health",
	Flag = "gpoMobEspHealth",
	Default = true,
	Callback = function(Value)
		MobEsp.HP = Value
	end,
})
SectionEntityNpc:Toggle({
	Name = "Mob Distance",
	Flag = "gpoMobEspDistance",
	Default = true,
	Callback = function(Value)
		MobEsp.Dist = Value
	end,
})
SectionEntityNpc:Slider({
	Name = "Mob ESP Distance",
	Flag = "gpoMobEspMaxDist",
	Min = 100,
	Max = 50000,
	Default = 5000,
	Decimals = 0,
	Suffix = " studs",
	Callback = function(Value)
		MobEsp.MaxDist = Value
	end,
})

Shared.RegisterEspSize(function()
	ResizeChestLabels()
	ResizeIslandLabels()
	ResizeEntityLabels(NpcEsp)
	ResizeEntityLabels(MobEsp)
end)

-- Vendor ESP

local VendTypes = {
	DevilFruit = { Label = "Devil Fruit" },
	Geppo = { Label = "Geppo" },
	Weapons = { Label = "Weapons" },
	Drinks = { Label = "Drinks" },
	Armor = { Label = "Armor" },
	FightingStyle = { Label = "Fighting Style" },
}
local VendColors = {
	DevilFruit = Color3.fromRGB(255, 82, 242),
	Geppo = Color3.fromRGB(96, 216, 255),
	Weapons = Color3.fromRGB(255, 122, 61),
	Drinks = Color3.fromRGB(111, 255, 148),
	Armor = Color3.fromRGB(139, 150, 255),
	FightingStyle = Color3.fromRGB(255, 226, 89),
}
local VendEsp = {
	On = false,
	Name = true, Dist = true,
	MaxDist = 5000, Size = 1.0,
	Entities = {},
	PassId = 0,
}
local function GetVendingType(M)
	local T = M:GetAttribute("VendingType")
	if typeof(T) ~= "string" then return nil end
	return T
end
local function VendingRoot(M)
	if M:IsA("BasePart") then return M end
	local H = M:FindFirstChild("HumanoidRootPart") or M:FindFirstChild("Head")
	if H then return H end
	local First
	for _, D in ipairs(M:GetDescendants()) do
		if D:IsA("BasePart") then
			if D.Name == "Center" then return D end
			if not First then First = D end
		end
	end
	return First
end
local function MakeVendingBill(M, VType)
	local Root = VendingRoot(M)
	if not Root then return end
	local ED = VendEsp.Entities[M]
	if ED and ED.Bill then
		if ED.Bill.Parent == Root then return end
		pcall(function() ED.Bill:Destroy() end)
		ED.Bill = nil; ED.Lbl = nil; ED.DistLbl = nil; ED.LastTxt = nil; ED.LastDistTxt = nil
	end
	local Info = VendTypes[VType]
	local BG = Instance.new("BillboardGui")
	BG.Name = "VendingESP"
	BG.Adornee = Root
	BG.StudsOffsetWorldSpace = Vector3.new(0, 3.25, 0)
	BG.AlwaysOnTop = true
	BG.ResetOnSpawn = false
	BG.LightInfluence = 0
	BG.Parent = Root
	local Lbl = Instance.new("TextLabel")
	Lbl.Text = ""
	Lbl.Parent = BG
	local DistLbl = Instance.new("TextLabel")
	DistLbl.Text = ""
	DistLbl.Parent = BG
	BG.Size = UDim2.new(0, 220, 0, 140)
	local Name = (Info and Info.Label) or VType
	local VColor = VendColors[VType] or Color3.fromRGB(255, 255, 255)
	ED = { Bill = BG, Lbl = Lbl, DistLbl = DistLbl, Type = Name }
	Lbl.TextColor3 = VColor
	DistLbl.TextColor3 = VColor
	LayoutEspLabels(ED, Shared.EspSize)
	VendEsp.Entities[M] = ED
end
local function ReindexVending()
	VendEsp.Cache = setmetatable({}, { __mode = "k" })
	local Env = workspace:FindFirstChild("Env")
	VendEsp.Env = Env
	if not Env then
		VendEsp.IndexTime = tick()
		return
	end
	local Cache = VendEsp.Cache
	local function Mark(Root)
		if Root and GetVendingType(Root) then Cache[Root] = true end
	end
	Mark(Env)
	for _, D in ipairs(Env:GetDescendants()) do
		Mark(D)
	end
	VendEsp.IndexTime = tick()
end
local function UpdateVendingEsp()
	if not Shared.Alive or not VendEsp.On then return end
	local Now = tick()
	if Now - LastTick.Vending < Rates.Vending then return end
	LastTick.Vending = Now
	local MyChar = LP.Character
	local MyRoot = MyChar and GetRoot(MyChar)
	if not MyRoot then return end
	local MyPos = SafePosOf(MyRoot) or CameraPos()
	if not MyPos then return end
	local MaxDistSq = VendEsp.MaxDist * VendEsp.MaxDist
	local Cam = workspace.CurrentCamera
	local CamCF = Cam and Cam.CFrame
	if not VendEsp.Cache or not VendEsp.IndexTime or Now - VendEsp.IndexTime > 3 then
		ReindexVending()
	end
	local PassId = VendEsp.PassId + 1
	VendEsp.PassId = PassId
	for M in pairs(VendEsp.Cache) do
		local ED = VendEsp.Entities[M]
		if M.Parent and GetVendingType(M) then
			if not ED then
				ED = {}
				VendEsp.Entities[M] = ED
			end
			ED.VPass = PassId
		elseif ED then
			if ED.Bill then pcall(function() ED.Bill:Destroy() end) end
			VendEsp.Entities[M] = nil
		end
	end
	for M, ED in pairs(VendEsp.Entities) do
		if ED.VPass ~= PassId then
			if ED.Bill then pcall(function() ED.Bill:Destroy() end) end
			VendEsp.Entities[M] = nil
		end
	end
	for M, ED in pairs(VendEsp.Entities) do
		pcall(function()
			local VType = GetVendingType(M)
			if not VType then return end
			local Root = VendingRoot(M)
			if not Root then return end
			if not ED.Bill or ED.Bill.Parent ~= Root then
				MakeVendingBill(M, VType)
				ED = VendEsp.Entities[M]
				if not ED then return end
			end
			local RPos = SafePosOf(Root)
			local DistSq = RPos and DistSqBetween(RPos, MyPos) or nil
			local Dist = DistSq and math.sqrt(DistSq) or nil
			if not DistSq or DistSq > MaxDistSq or not InFront(RPos, CamCF) then
				if ED.Bill.Enabled then ED.Bill.Enabled = false end
				return
			end
			if not ED.Bill.Enabled then ED.Bill.Enabled = true end
			local VColor = VendColors[VType] or Color3.fromRGB(255, 255, 255)
			if ED.Lbl.TextColor3 ~= VColor then ED.Lbl.TextColor3 = VColor end
			if VendEsp.Name then
				if ED.Type ~= ED.LastTxt then ED.Lbl.Text = ED.Type; ED.LastTxt = ED.Type end
			elseif ED.LastTxt ~= "" then
				ED.Lbl.Text = ""
				ED.LastTxt = ""
			end
			SetEspDistance(ED, VendEsp.Dist, Dist, VColor)
		end)
	end
end
local function ResizeVendingLabels()
	for _, ED in pairs(VendEsp.Entities) do
		if ED and ED.Lbl then LayoutEspLabels(ED, Shared.EspSize) end
	end
end
local function OnVendDescendantAdded(Inst)
	if not VendEsp.On then return end
	local Env = VendEsp.Env
	if not Env or not Inst:IsDescendantOf(Env) then return end
	if GetVendingType(Inst) then
		local Cache = VendEsp.Cache
		if Cache then Cache[Inst] = true end
	end
end
local function OnVendDescendantRemoving(Inst)
	local Cache = VendEsp.Cache
	if not Cache then return end
	if Inst:IsA("Model") or Inst:IsA("Folder") or Inst:IsA("BasePart") then
		Cache[Inst] = nil
	end
end
local function EnableVendingEsp()
	if not Conns.VendAdded then
		ReindexVending()
		Conns.VendAdded = Library:Connect(workspace.DescendantAdded, OnVendDescendantAdded)
		Conns.VendRemoved = Library:Connect(workspace.DescendantRemoving, OnVendDescendantRemoving)
	end
	Shared.Sync()
end
local function DisableVendingEsp()
	StoredDisconnect(Conns.VendAdded)
	Conns.VendAdded = nil
	StoredDisconnect(Conns.VendRemoved)
	Conns.VendRemoved = nil
	for M, ED in pairs(VendEsp.Entities) do
		if ED and ED.Bill then pcall(function() ED.Bill:Destroy() end) end
	end
	VendEsp.Entities = {}
	VendEsp.Cache = nil
	VendEsp.IndexTime = 0
	Shared.Sync()
end

local SectionVend = EspPage:Section({ Name = "Vendor ESP", Side = 2 })

SectionVend:Toggle({
	Name = "Enable",
	Flag = "gpoVendEspToggle",
	Default = false,
	Callback = function(Value)
		VendEsp.On = Value
		if Value then EnableVendingEsp() else DisableVendingEsp() end
	end,
})
SectionVend:Toggle({
	Name = "Type",
	Flag = "gpoVendEspName",
	Default = true,
	Callback = function(Value)
		VendEsp.Name = Value
	end,
})
SectionVend:Toggle({
	Name = "Distance",
	Flag = "gpoVendEspDistance",
	Default = true,
	Callback = function(Value)
		VendEsp.Dist = Value
	end,
})
SectionVend:Slider({
	Name = "ESP Distance",
	Flag = "gpoVendEspMaxDist",
	Min = 100,
	Max = 50000,
	Default = 5000,
	Decimals = 0,
	Suffix = " studs",
	Callback = function(Value)
		VendEsp.MaxDist = Value
	end,
})

-- Medal ESP

local MedalEsp = {
	On = false,
	Name = true, Dist = true,
	MaxDist = 5000, Size = 1.0,
	Color = Color3.fromRGB(255, 200, 70),
	Entities = {},
	Cache = nil,
}
local function MedalStyleFor(M)
	if not M:IsA("Model") then return nil end
	local Lower = string.lower(M.Name)
	if not string.find(Lower, "medal", 1, true) then return nil end
	if string.find(Lower, "piller", 1, true) or string.find(Lower, "pillar", 1, true) then return nil end
	local Style = M:GetAttribute("FightingStyle")
	if typeof(Style) ~= "string" or Style == "" then
		Style = string.match(M.Name, "^(.-)%s*[Mm]edal$")
	end
	if not Style or Style == "" then return nil end
	local Base = M.PrimaryPart or M:FindFirstChildWhichIsA("BasePart")
	if not Base or not Base.Parent then return nil end
	return { Style = Style, Base = Base, Label = Style .. " Medal" }
end
local function ReindexMedals()
	local C = setmetatable({}, { __mode = "k" })
	MedalEsp.Cache = C
	for _, M in ipairs(workspace:GetDescendants()) do
		if M:IsA("Model") then
			local MT = MedalStyleFor(M)
			if MT then C[M] = MT end
		end
	end
	MedalEsp.Indexed = true
end
local function OnMedalDescendantAdded(Inst)
	if not MedalEsp.On or not Inst:IsA("Model") then return end
	local C = MedalEsp.Cache
	if not C then return end
	local MT = MedalStyleFor(Inst)
	if MT then C[Inst] = MT end
end
local function OnMedalDescendantRemoving(Inst)
	local C = MedalEsp.Cache
	if not C then return end
	if Inst:IsA("Model") then C[Inst] = nil end
end
local function ResizeMedalLabels()
	for _, ED in pairs(MedalEsp.Entities) do
		if ED and ED.Lbl then LayoutEspLabels(ED, Shared.EspSize) end
	end
end
local function UpdateMedalEsp()
	if not Shared.Alive or not MedalEsp.On then return end
	local Now = tick()
	if Now - LastTick.Medal < Rates.Medal then return end
	LastTick.Medal = Now
	if not MedalEsp.Indexed then ReindexMedals() end
	local C = MedalEsp.Cache
	if not C then return end
	local MyRoot = GetRoot(GetCharacter(LP))
	if not MyRoot then return end
	local MyPos = SafePosOf(MyRoot) or CameraPos()
	if not MyPos then return end
	local MaxDistSq = MedalEsp.MaxDist * MedalEsp.MaxDist
	local Cam = workspace.CurrentCamera
	local CamCF = Cam and Cam.CFrame
	local WantName = MedalEsp.Name
	local WantDist = MedalEsp.Dist
	local Col = MedalEsp.Color
	for M, MT in pairs(C) do
		local Base = MT and MT.Base
		if Base and Base.Parent then
			local ED = MedalEsp.Entities[M]
			local RPos = SafePosOf(Base)
			local DistSq = RPos and DistSqBetween(RPos, MyPos) or nil
			local Show = DistSq ~= nil and DistSq <= MaxDistSq and InFront(RPos, CamCF)
			if not ED or not ED.Bill or ED.Bill.Adornee ~= Base then
				if ED and ED.Bill then pcall(function() ED.Bill:Destroy() end) end
				if Show then
					local BG = Instance.new("BillboardGui")
					BG.Name = "MedalESP"
					BG.Adornee = Base
					BG.StudsOffsetWorldSpace = Vector3.new(0, 2.2, 0)
					BG.AlwaysOnTop = true
					BG.ResetOnSpawn = false
					BG.LightInfluence = 0
					BG.Size = UDim2.new(0, 200, 0, 120)
					BG.Parent = Base
					local Lbl = Instance.new("TextLabel")
					Lbl.Text = ""
					Lbl.Parent = BG
					local DistLbl = Instance.new("TextLabel")
					DistLbl.Text = ""
					DistLbl.Parent = BG
					ED = { Bill = BG, Lbl = Lbl, DistLbl = DistLbl, Style = MT.Style }
					Lbl.TextColor3 = Col
					DistLbl.TextColor3 = Col
					LayoutEspLabels(ED, Shared.EspSize)
					MedalEsp.Entities[M] = ED
				end
			end
			if ED then
				if ED.Style ~= MT.Style then
					ED.Style = MT.Style
					ED.LastTxt = nil
				end
				if Show then
					if not ED.Bill.Enabled then ED.Bill.Enabled = true end
					if WantName then
						if ED.LastTxt ~= MT.Label then ED.Lbl.Text = MT.Label; ED.LastTxt = MT.Label end
					elseif ED.LastTxt ~= "" then
						ED.Lbl.Text = ""
						ED.LastTxt = ""
					end
					if ED.Lbl.TextColor3 ~= Col then ED.Lbl.TextColor3 = Col end
					SetEspDistance(ED, WantDist, math.sqrt(DistSq), Col)
				elseif ED.Bill.Enabled then
					ED.Bill.Enabled = false
				end
			end
		else
			local ED = MedalEsp.Entities[M]
			if ED and ED.Bill then pcall(function() ED.Bill:Destroy() end) end
			MedalEsp.Entities[M] = nil
		end
	end
	for M, ED in pairs(MedalEsp.Entities) do
		if C[M] == nil then
			if ED and ED.Bill then pcall(function() ED.Bill:Destroy() end) end
			MedalEsp.Entities[M] = nil
		end
	end
end
local function EnableMedalEsp()
	if not Conns.MedalAdded then
		ReindexMedals()
		Conns.MedalAdded = Library:Connect(workspace.DescendantAdded, OnMedalDescendantAdded)
		Conns.MedalRemoved = Library:Connect(workspace.DescendantRemoving, OnMedalDescendantRemoving)
	end
	Shared.Sync()
end
local function DisableMedalEsp()
	StoredDisconnect(Conns.MedalAdded)
	Conns.MedalAdded = nil
	StoredDisconnect(Conns.MedalRemoved)
	Conns.MedalRemoved = nil
	for _, ED in pairs(MedalEsp.Entities) do
		if ED and ED.Bill then pcall(function() ED.Bill:Destroy() end) end
	end
	MedalEsp.Entities = {}
	MedalEsp.Cache = nil
	MedalEsp.Indexed = false
	Shared.Sync()
end

local SectionMedal = EspPage:Section({ Name = "Medal ESP", Side = 2 })

SectionMedal:Toggle({
	Name = "Enable",
	Flag = "gpoMedalEspToggle",
	Default = false,
	Callback = function(Value)
		MedalEsp.On = Value
		if Value then EnableMedalEsp() else DisableMedalEsp() end
	end,
})
SectionMedal:Toggle({
	Name = "Style",
	Flag = "gpoMedalEspName",
	Default = true,
	Callback = function(Value)
		MedalEsp.Name = Value
	end,
})
SectionMedal:Toggle({
	Name = "Distance",
	Flag = "gpoMedalEspDistance",
	Default = true,
	Callback = function(Value)
		MedalEsp.Dist = Value
	end,
})
SectionMedal:Slider({
	Name = "ESP Distance",
	Flag = "gpoMedalEspMaxDist",
	Min = 100,
	Max = 50000,
	Default = 5000,
	Decimals = 0,
	Suffix = " studs",
	Callback = function(Value)
		MedalEsp.MaxDist = Value
	end,
})

Shared.RegisterEspSize(ResizeVendingLabels)
Shared.RegisterEspSize(ResizeMedalLabels)
Shared.RegisterEsp(function() return ChestEsp.On end, UpdateChestEsp)
Shared.RegisterEsp(function() return IslandEsp.On end, UpdateIslandEsp)
Shared.RegisterEsp(function() return NpcEsp.On or MobEsp.On end, UpdateEntityEsp)
Shared.RegisterEsp(function() return VendEsp.On end, UpdateVendingEsp)
Shared.RegisterEsp(function() return MedalEsp.On end, UpdateMedalEsp)

-- World

local LIGHT_PROPS = { "Ambient", "OutdoorAmbient", "Brightness", "ClockTime", "ExposureCompensation", "EnvironmentDiffuseScale", "EnvironmentSpecularScale", "FogEnd", "FogStart", "GlobalShadows", "ShadowSoftness" }
local World = {
	Fullbright = false,
	NoFog = false,
	NoShadows = false,
	OptimizeGame = false,
	Aggressive = false,
	Conn = nil,
	SavedLighting = nil,
	SavedAtmosphere = nil,
	OptConns = {},
	OptDisabledConns = {},
	AggrOriginals = setmetatable({}, { __mode = "k" }),
	AggrConn = nil,
	AggrOwnConns = {},
	AggrDisabledConns = {},
}
local function LightingSave()
	if World.SavedLighting then return end
	local Saved = {}
	for _, Prop in ipairs(LIGHT_PROPS) do
		local Ok, Value = pcall(function() return Lighting[Prop] end)
		if Ok then Saved[Prop] = Value end
	end
	World.SavedLighting = Saved
end
local function LightingApply()
	local Saved = World.SavedLighting
	if not Saved then return end
	local function Set(Prop, Value)
		if Value == nil then Value = Saved[Prop] end
		if Value == nil then return end
		pcall(function() Lighting[Prop] = Value end)
	end
	Set("Ambient", World.Fullbright and Color3.fromRGB(235, 235, 235) or nil)
	Set("OutdoorAmbient", World.Fullbright and Color3.fromRGB(235, 235, 235) or nil)
	Set("Brightness", World.Fullbright and 2.5 or nil)
	Set("ClockTime", World.Fullbright and 14 or nil)
	Set("ExposureCompensation", World.Fullbright and 0.25 or nil)
	Set("EnvironmentDiffuseScale", World.Fullbright and 1 or nil)
	Set("EnvironmentSpecularScale", World.Fullbright and 1 or nil)
	Set("FogEnd", World.NoFog and 1e6 or nil)
	Set("FogStart", World.NoFog and 0 or nil)
	Set("GlobalShadows", World.NoShadows and false or nil)
	Set("ShadowSoftness", World.NoShadows and 0 or nil)
	local Atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
	if Atmosphere then
		if not World.SavedAtmosphere then
			local Ok, Density = pcall(function() return Atmosphere.Density end)
			World.SavedAtmosphere = { Inst = Atmosphere, Density = Ok and Density or 0 }
		end
		pcall(function() Atmosphere.Density = (World.NoFog or World.Fullbright) and 0 or World.SavedAtmosphere.Density end)
	end
end
local function LightingRestore()
	local Saved = World.SavedLighting
	if Saved then
		for Prop, Value in pairs(Saved) do
			pcall(function() Lighting[Prop] = Value end)
		end
		World.SavedLighting = nil
	end
	local Atmosphere = World.SavedAtmosphere
	if Atmosphere and Atmosphere.Inst and Atmosphere.Inst.Parent then
		pcall(function() Atmosphere.Inst.Density = Atmosphere.Density end)
	end
	World.SavedAtmosphere = nil
end
local function LightingEnabled()
	return World.Fullbright or World.NoFog or World.NoShadows
end
local function WorldUpdate()
	if LightingEnabled() then
		LightingSave()
		LightingApply()
	else
		LightingRestore()
	end
end
local function WarnOnce(Key, Message)
	if World["Warned" .. Key] then return end
	World["Warned" .. Key] = true
	warn("[GPO] " .. Message)
end
local function GetFuncInfo(Func)
	if type(getinfo) == "function" then return getinfo(Func) end
	if type(debug) == "table" and type(debug.getinfo) == "function" then return debug.getinfo(Func) end
	return nil
end
local SeaClientHooked = false
local function SetupSeaClient()
	if SeaClientHooked then return end
	if type(hookfunction) ~= "function" or type(getgc) ~= "function" or type(getconstants) ~= "function" or type(GetFuncInfo) ~= "function" then
		WarnOnce("Sea", "executor lacks getgc/getconstants/hookfunction; SeaClient not optimized.")
		return
	end
	task.spawn(function()
		local Func
		local function Consider(Object)
			if type(Object) ~= "function" then return false end
			local Info = GetFuncInfo(Object)
			local Src = Info and Info.source
			if type(Src) ~= "string" or not Src:find("SeaClient") then return false end
			local Ok, Consts = pcall(getconstants, Object)
			if not Ok or type(Consts) ~= "table" then return false end
			if not table.find(Consts, "getWaveAt") then return false end
			Func = Object
			return true
		end
		if type(filtergc) == "function" then
			pcall(function()
				for _, Object in next, filtergc("function", {
					IgnoreExecutor = true,
					Constants = { "getWaveAt" },
				}) do
					if Consider(Object) then break end
				end
			end)
		end
		if not Func then
			for _, Object in next, getgc(false) do
				if Consider(Object) then break end
			end
		end
		if not Func then
			WarnOnce("SeaMiss", "SeaClient not found; water not optimized.")
			return
		end
		local Last = tick()
		local Old
		Old = hookfunction(Func, function(...)
			if not (World.OptimizeGame or World.Aggressive) then return Old(...) end
			if tick() - Last < 1 / 30 then return end
			Last = tick()
			return Old(...)
		end)
		SeaClientHooked = Old ~= nil
	end)
end
local function OptimizeReplication()
	if type(getconnections) ~= "function" then
		WarnOnce("Repl", "executor lacks getconnections; replication not optimized.")
		return
	end
	local RepFunc
	for _, Conn in next, getconnections(Services.RunService.RenderStepped) do
		local Func = Conn.Function
		if Func then
			local Info = GetFuncInfo(Func)
			local Src = Info and Info.source
			if type(Src) == "string" and Src:find("PlayerScripts") and Src:find("Replication") then
				Conn:Disable()
				World.OptDisabledConns[#World.OptDisabledConns + 1] = Conn
				RepFunc = RepFunc or Func
			end
		end
	end
	if not RepFunc then return end
	local Last = tick()
	local Our = Services.RunService.RenderStepped:Connect(function()
		if not World.OptimizeGame then return end
		local Now = tick()
		if Now - Last < 1 / 10 then return end
		local Dt = Now - Last
		Last = Now
		return RepFunc(Dt)
	end)
	World.OptConns[#World.OptConns + 1] = Our
end
local function OptimizeEnable()
	task.spawn(SetupSeaClient)
	task.spawn(OptimizeReplication)
end
local function OptimizeDisable()
	for _, Conn in ipairs(World.OptConns) do pcall(function() Conn:Disconnect() end) end
	table.clear(World.OptConns)
	for _, Conn in ipairs(World.OptDisabledConns) do pcall(function() Conn:Enable() end) end
	table.clear(World.OptDisabledConns)
end
local AGGR_LOW_TEXTURE = "rbxassetid://130143779"
local function AggrRemember(Obj, Key, Value)
	local Rec = World.AggrOriginals[Obj]
	if not Rec then
		Rec = {}
		World.AggrOriginals[Obj] = Rec
	end
	if Rec[Key] == nil then Rec[Key] = Value end
end
local function AggrDowngrade(Obj)
	if not Obj or not Obj.Parent then return end
	if Obj:IsA("BasePart") then
		pcall(function()
			AggrRemember(Obj, "Material", Obj.Material)
			AggrRemember(Obj, "Reflectance", Obj.Reflectance)
			AggrRemember(Obj, "CastShadow", Obj.CastShadow)
			Obj.Material = Enum.Material.Plastic
			Obj.Reflectance = 0
			Obj.CastShadow = false
		end)
	end
	if Obj:IsA("Texture") or Obj:IsA("Decal") then
		pcall(function()
			AggrRemember(Obj, "Texture", Obj.Texture)
			Obj.Texture = AGGR_LOW_TEXTURE
		end)
	elseif Obj:IsA("SurfaceAppearance") then
		pcall(function()
			AggrRemember(Obj, "ColorMap", Obj.ColorMap)
			Obj.ColorMap = AGGR_LOW_TEXTURE
		end)
	end
	if Obj:IsA("ParticleEmitter") or Obj:IsA("Trail") then
		pcall(function()
			AggrRemember(Obj, "Enabled", Obj.Enabled)
			Obj.Enabled = false
			if Obj:IsA("ParticleEmitter") then
				AggrRemember(Obj, "Rate", Obj.Rate)
				AggrRemember(Obj, "Speed", Obj.Speed)
				Obj.Rate = 0
				Obj.Speed = NumberRange.new(0)
			end
		end)
	end
	if Obj:IsA("PointLight") or Obj:IsA("SpotLight") or Obj:IsA("SurfaceLight") then
		pcall(function()
			AggrRemember(Obj, "Enabled", Obj.Enabled)
			AggrRemember(Obj, "Brightness", Obj.Brightness)
			AggrRemember(Obj, "Range", Obj.Range)
			Obj.Enabled = false
			Obj.Brightness = 0
			Obj.Range = 2
		end)
	end
end
local function AggrRunVisual()
	if World.AggrConn then return end
	World.AggrConn = game.DescendantAdded:Connect(function(Obj)
		if not World.Aggressive then return end
		task.defer(AggrDowngrade, Obj)
	end)
	task.spawn(function()
		local Count = 0
		for _, Obj in ipairs(game:GetDescendants()) do
			if not World.Aggressive then return end
			AggrDowngrade(Obj)
			Count = Count + 1
			if Count % 1000 == 0 then task.wait() end
		end
		warn(("[GPO] Aggressive Optimize: %d objects downgraded (toggle off to restore)."):format(Count))
	end)
end
local function AggrRestoreVisual()
	if World.AggrConn then
		World.AggrConn:Disconnect()
		World.AggrConn = nil
	end
	local Restored = 0
	for Obj, Rec in next, World.AggrOriginals do
		if Obj.Parent then
			for Key, Value in next, Rec do
				pcall(function() Obj[Key] = Value end)
			end
			Restored = Restored + 1
		end
		World.AggrOriginals[Obj] = nil
	end
	World.AggrOriginals = setmetatable({}, { __mode = "k" })
end
local AggrWorldClientFunc = nil
local function AggrWorldClientApply()
	if type(getconnections) ~= "function" then
		WarnOnce("WorldClient", "executor lacks getconnections; WorldClient not optimized.")
		return
	end
	task.wait(1)
	local Conn
	for _, Obj in next, getconnections(Services.RunService.PreRender) do
		local Func = Obj.Function
		if Func then
			local Info = GetFuncInfo(Func)
			local Src = Info and Info.source
			if type(Src) == "string" and Src:find("WorldClient") then
				if AggrWorldClientFunc == Func then return end
				AggrWorldClientFunc = Func
				Obj:Disable()
				World.AggrDisabledConns[#World.AggrDisabledConns + 1] = Obj
				Conn = Obj
			end
		end
	end
	if not Conn then return end
	local Last = tick()
	local Our = Services.RunService.PreRender:Connect(function()
		local Now = tick()
		local Dt = Now - Last
		Last = Now
		if not World.Aggressive or Dt >= 1 / 30 then
			return task.spawn(Conn.Fire, Conn, Dt)
		end
	end)
	World.AggrOwnConns[#World.AggrOwnConns + 1] = Our
end
local function AggressiveEnable()
	AggrRunVisual()
	task.spawn(SetupSeaClient)
	task.spawn(AggrWorldClientApply)
	if LP.PlayerGui then
		local C = LP.PlayerGui.ChildAdded:Connect(function(Obj)
			if not World.Aggressive then return end
			if Obj.Name ~= "WorldClient" then return end
			task.spawn(AggrWorldClientApply)
		end)
		World.AggrOwnConns[#World.AggrOwnConns + 1] = C
	end
end
local function AggressiveDisable()
	AggrRestoreVisual()
	for _, Conn in ipairs(World.AggrOwnConns) do pcall(function() Conn:Disconnect() end) end
	table.clear(World.AggrOwnConns)
	for _, Conn in ipairs(World.AggrDisabledConns) do pcall(function() Conn:Enable() end) end
	table.clear(World.AggrDisabledConns)
	AggrWorldClientFunc = nil
end
local function WorldEnsureLoop()
	local Active = World.Fullbright or World.NoFog or World.NoShadows
	if Active then
		if not World.Conn then
			World.Conn = Services.RunService.Heartbeat:Connect(function()
				if not Shared.Alive then return end
				if LightingEnabled() then
					LightingApply()
				end
			end)
		end
	elseif World.Conn then
		World.Conn:Disconnect()
		World.Conn = nil
	end
end

local SectionWorld = EspPage:Section({ Name = "World", Side = 2 })

SectionWorld:Toggle({
	Name = "Fullbright",
	Flag = "gpoFullbright",
	Default = false,
	Callback = function(Value)
		World.Fullbright = Value
		WorldUpdate()
		WorldEnsureLoop()
	end,
})
SectionWorld:Toggle({
	Name = "No Fog",
	Flag = "gpoNoFog",
	Default = false,
	Callback = function(Value)
		World.NoFog = Value
		WorldUpdate()
		WorldEnsureLoop()
	end,
})
SectionWorld:Toggle({
	Name = "No Shadows",
	Flag = "gpoNoShadows",
	Default = false,
	Callback = function(Value)
		World.NoShadows = Value
		WorldUpdate()
		WorldEnsureLoop()
	end,
})
SectionWorld:Toggle({
	Name = "Optimize Game",
	Flag = "gpoOptimizeGame",
	Default = false,
	Callback = function(Value)
		World.OptimizeGame = Value
		if Value then
			OptimizeEnable()
		else
			OptimizeDisable()
		end
	end,
})
SectionWorld:Toggle({
	Name = "Aggressive Optimize Game",
	Flag = "gpoAggressiveOptimize",
	Default = false,
	Callback = function(Value)
		World.Aggressive = Value
		if Value then
			AggressiveEnable()
		else
			AggressiveDisable()
		end
	end,
})

-- Infinite Geppo

local InfGeppo = {
	Buff = false,
	Conn = nil,
	Last = 0,
}
local function InfGeppoCall()
	local Ch = LP.Character
	if not Ch then return end
	local Hum = Ch:FindFirstChildOfClass("Humanoid")
	if not Hum then return end
	if Hum.FloorMaterial ~= Enum.Material.Air then return end
	if not UIS:IsKeyDown(Enum.KeyCode.Space) then return end
	pcall(function() LP:SetAttribute("IgnoreGeppoCombatRestriction", true) end)
	local Backpack = LP:FindFirstChildOfClass("Backpack")
	local Callbacks = Backpack and Backpack:FindFirstChild("InputCallbacks")
	local Geppo = Callbacks and Callbacks:FindFirstChild("Geppo")
	if not Geppo then return end
	local Ok, Mod = pcall(require, Geppo)
	if not (Ok and Mod) then return end
	pcall(function()
		Mod:PC_Activate({ Utils = { inCombatCheck = function() return false end } })
	end)
end
local function InfGeppoEnable()
	pcall(function() LP:SetAttribute("IgnoreGeppoCombatRestriction", true) end)
	if InfGeppo.Conn then return end
	InfGeppo.Conn = Services.RunService.Heartbeat:Connect(function()
		if not Shared.Alive or not InfGeppo.Buff then return end
		local Now = os.clock()
		if Now - InfGeppo.Last >= 0.2 then
			InfGeppo.Last = Now
			InfGeppoCall()
		end
	end)
end
local function InfGeppoDisable()
	if InfGeppo.Conn then
		InfGeppo.Conn:Disconnect()
		InfGeppo.Conn = nil
	end
	pcall(function() LP:SetAttribute("IgnoreGeppoCombatRestriction", false) end)
end

local SectionGeppo = EspPage:Section({ Name = "Geppo", Side = 2 })

SectionGeppo:Toggle({
	Name = "Infinite Geppo",
	Flag = "gpoInfiniteGeppo",
	Default = false,
	Callback = function(Value)
		InfGeppo.Buff = Value
		if Value then
			InfGeppoEnable()
		else
			InfGeppoDisable()
		end
	end,
})
end

InitVisuals(Pages.Visuals)

local SettingsPage = Library:CreateSettingsPage(Window, KeybindList, Watermark)

Library:LoadAutoload()
