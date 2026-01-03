-- Always define RunService at the very top

local RunService = game:GetService("RunService")


-- Cleanup from previous executions
if getgenv then
	local g = getgenv()
	if g.LUMI_WOG_CLEANUP then
		pcall(g.LUMI_WOG_CLEANUP)
	end
	g.LUMI_WOG_CLEANUP = function()
		if g.LUMI_WOG_ESPObjects then
			for _, lines in pairs(g.LUMI_WOG_ESPObjects) do
				for _, obj in pairs(lines) do pcall(function() obj:Remove() end) end
			end
		end
		if g.LUMI_WOG_MissileESPObjects then
			for _, v in pairs(g.LUMI_WOG_MissileESPObjects) do
				if v.box then pcall(function() v.box:Remove() end) end
				if v.label then pcall(function() v.label:Remove() end) end
			end
		end
		-- Restore expanded LeftWings
		if _G and _G.ExpandedLeftWings and _G.OriginalLeftWingSizes then
			for leftwing, _ in pairs(_G.ExpandedLeftWings) do
				local orig = _G.OriginalLeftWingSizes[leftwing]
				pcall(function()
					if leftwing and leftwing:IsA("BasePart") and orig then
						leftwing.Size = orig
					end
				end)
			end
			_G.ExpandedLeftWings = {}
			_G.OriginalLeftWingSizes = {}
		end
		if g.LUMI_WOG_Connection then
			pcall(function() g.LUMI_WOG_Connection:Disconnect() end)
		end
	end
end


local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Teams = game:GetService("Teams")

-- Thrust slider state


local ESPEnabled = true
local MissileESPEnabled = true
local ExpanderScale = 2
local ESPBoxScale = tonumber(ESPBoxScale) or 3
local ESPObjects = {}
local MissileESPObjects = {}

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local function GetRandomEnemyPosition()
       local planeViewmodels = workspace.Camera:FindFirstChild("plane_viewmodels")
       if not planeViewmodels then return nil end
       local enemies = {}
       for _, model in ipairs(planeViewmodels:GetChildren()) do
	       local player = Players:FindFirstChild(model.Name)
	       if player and player ~= LocalPlayer and player.Team ~= LocalPlayer.Team then
		       local cf, _ = model:GetBoundingBox()
		       table.insert(enemies, cf.Position)
	       end
       end
       if #enemies == 0 then return nil end
       return enemies[math.random(1, #enemies)]
end

local function FindMissileMesh(model)
       -- Recursively search for a BasePart named 'missile' inside the model
       for _, obj in ipairs(model:GetDescendants()) do
	       if obj:IsA("BasePart") and obj.Name == "missile" then
		       return obj
	       end
       end
       return nil
end


-- Removed hitbox expander tracking tables
if getgenv then
	local g = getgenv()
	g.LUMI_WOG_ESPObjects = ESPObjects
	g.LUMI_WOG_MissileESPObjects = MissileESPObjects
end
-- Remove one-time call; will be called every frame below
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local function UpdateMissileESP()
	if not MissileESPEnabled then
		for _, v in pairs(MissileESPObjects) do
			if v.box then v.box.Visible = false end
			if v.label then v.label.Visible = false end
		end
		return
	end
	local nodes = workspace:FindFirstChild("nodes")
	if not nodes then return end
	local missiles = nodes:FindFirstChild("clientmissiles")
	if not missiles then return end
	-- Track which missiles are still present
	local seen = {}
	for _, missile in ipairs(missiles:GetChildren()) do
		seen[missile] = true
		if not MissileESPObjects[missile] then
			-- Create box and label
			local box = Drawing.new("Quad")
			box.Visible = false
			box.Color = Color3.fromRGB(0, 255, 255)
			box.Thickness = 2
			box.Filled = false
			local label = Drawing.new("Text")
			label.Visible = false
			label.Color = Color3.fromRGB(255, 255, 255)
			label.Size = 16
			label.Center = true
			MissileESPObjects[missile] = {box = box, label = label}
		end
		local box = MissileESPObjects[missile].box
		local label = MissileESPObjects[missile].label
		if missile:IsA("Model") then
			local meshPart = missile:FindFirstChild("missile")
			if meshPart and meshPart:IsA("BasePart") then
				local cf, size = meshPart.CFrame, meshPart.Size
				local corners = {
					cf * Vector3.new(-size.X/2, -size.Y/2, -size.Z/2),
					cf * Vector3.new(-size.X/2,  size.Y/2, -size.Z/2),
					cf * Vector3.new( size.X/2,  size.Y/2, -size.Z/2),
					cf * Vector3.new( size.X/2, -size.Y/2, -size.Z/2)
				}
				local screenCorners = {}
				local onScreen = true
				for i, corner in ipairs(corners) do
					local pos, visible = Camera:WorldToViewportPoint(corner)
					if not visible then onScreen = false break end
					screenCorners[i] = Vector2.new(pos.X, pos.Y)
				end
				if onScreen then
					-- Scale up from center
					local minX, minY = math.huge, math.huge
					local maxX, maxY = -math.huge, -math.huge
					for _, pt in ipairs(screenCorners) do
						minX = math.min(minX, pt.X)
						minY = math.min(minY, pt.Y)
						maxX = math.max(maxX, pt.X)
						maxY = math.max(maxY, pt.Y)
					end
					local centerX = (minX + maxX) / 2
					local centerY = (minY + maxY) / 2
					-- Scale up from center based on distance (stronger effect)
					local missilePos = cf.Position
					local camPos = Camera.CFrame.Position
					local distance = (missilePos - camPos).Magnitude
					local scale = 1 + (distance / 25)
					local function scalePt(x, y)
						return Vector2.new(centerX + (x - centerX) * scale, centerY + (y - centerY) * scale)
					end
					local scaledCorners = {
						scalePt(screenCorners[1].X, screenCorners[1].Y),
						scalePt(screenCorners[2].X, screenCorners[2].Y),
						scalePt(screenCorners[3].X, screenCorners[3].Y),
						scalePt(screenCorners[4].X, screenCorners[4].Y)
					}
					box.PointA = scaledCorners[1]
					box.PointB = scaledCorners[2]
					box.PointC = scaledCorners[3]
					box.PointD = scaledCorners[4]
					box.Visible = true
					-- Label above the box with missile name
					local top = scaledCorners[2]
					label.Position = Vector2.new(top.X, top.Y - 10)
					label.Text = missile.Name
					label.Visible = true
				else
					box.Visible = false
					label.Visible = false
				end
			else
				box.Visible = false
				label.Visible = false
			end
		else
			box.Visible = false
			label.Visible = false
		end
	end
	-- Remove ESP for missiles that no longer exist or are invalid
	for missile, objs in pairs(MissileESPObjects) do
		if not seen[missile] or not missile:IsDescendantOf(game) then
			objs.box:Remove()
			objs.label:Remove()
			MissileESPObjects[missile] = nil
		end
	end
end


local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera


local function CreateESP(target)
	local lines = {}
	-- 12 lines for 3D box
	for i = 1, 12 do
		local line = Drawing.new("Line")
		line.Visible = false
		line.Color = Color3.fromRGB(255, 0, 0)
		line.Thickness = 2
		table.insert(lines, line)
	end
	-- Add label for name+distance
	local label = Drawing.new("Text")
	label.Visible = false
	label.Color = Color3.fromRGB(255, 255, 255)
	label.Size = 18
	label.Center = true
	label.Outline = true
	ESPObjects[target] = {lines = lines, label = label}
end

local function RemoveESP(target)
	if ESPObjects[target] then
		for _, line in ipairs(ESPObjects[target].lines) do
			line:Remove()
		end
		if ESPObjects[target].label then
			ESPObjects[target].label:Remove()
		end
		ESPObjects[target] = nil
	end
end

-- Hitbox expander tracking
local OriginalLeftWingSizes = {}
local ExpandedLeftWings = {}


function UpdateESP()
	if not ESPEnabled then
		for _, obj in pairs(ESPObjects) do
			for _, line in ipairs(obj.lines) do line.Visible = false end
			if obj.label then obj.label.Visible = false end
		end
		return
	end
	local planeViewmodels = workspace.Camera:FindFirstChild("plane_viewmodels")
	if not planeViewmodels then return end

	-- Track which leftwings are still valid this frame
	local seenLeftwings = {}

	for _, model in ipairs(planeViewmodels:GetChildren()) do
		local playerName = model.Name
		local player = Players:FindFirstChild(playerName)
		if player and player ~= LocalPlayer and player.Team ~= LocalPlayer.Team then
			-- Hitbox expander for enemy planes
			local leftwing = model:FindFirstChild("LeftWing")
			if leftwing and leftwing:IsA("BasePart") then
				seenLeftwings[leftwing] = true
				-- Check for mesh or specialmesh
				local mesh = leftwing:FindFirstChildWhichIsA("SpecialMesh") or leftwing:FindFirstChildWhichIsA("Mesh")
				if mesh then
					if not OriginalLeftWingSizes[leftwing] then
						OriginalLeftWingSizes[leftwing] = mesh.Scale
					end
					local desiredScale = OriginalLeftWingSizes[leftwing] * ExpanderScale
					if mesh.Scale ~= desiredScale then
						mesh.Scale = desiredScale
						ExpandedLeftWings[leftwing] = true
					end
				else
					if not OriginalLeftWingSizes[leftwing] then
						OriginalLeftWingSizes[leftwing] = leftwing.Size
					end
					local desiredSize = OriginalLeftWingSizes[leftwing] * ExpanderScale
					if leftwing.Size ~= desiredSize then
						leftwing.Size = desiredSize
						ExpandedLeftWings[leftwing] = true
					end
				end
			end
			if not ESPObjects[player] then
				CreateESP(player)
			end
			local cf, size = model:GetBoundingBox()
			-- 8 corners of the 3D box
			local corners3D = {}
			local onScreen = true
			-- Calculate center for scaling
			local center = cf.Position
			for x = -1, 1, 2 do
				for y = -1, 1, 2 do
					for z = -1, 1, 2 do
						local offset = Vector3.new(size.X/2 * x, size.Y/2 * y, size.Z/2 * z)
						-- Apply ESPBoxScale
						offset = offset * ESPBoxScale
						local world = cf * (offset / ESPBoxScale)
						local pos, visible = Camera:WorldToViewportPoint(world)
						if not visible then onScreen = false break end
						table.insert(corners3D, Vector2.new(pos.X, pos.Y))
					end
					if not onScreen then break end
				end
				if not onScreen then break end
			end
			local obj = ESPObjects[player]
			local lines = obj.lines
			local label = obj.label
			if onScreen and ESPEnabled then
				-- 3D box edges (12 lines)
				local edges = {
					{1,2},{2,4},{4,3},{3,1}, -- bottom
					{5,6},{6,8},{8,7},{7,5}, -- top
					{1,5},{2,6},{3,7},{4,8}  -- verticals
				}
				for i, edge in ipairs(edges) do
					local a, b = corners3D[edge[1]], corners3D[edge[2]]
					lines[i].From = a
					lines[i].To = b
					lines[i].Visible = true
				end
				-- Hide any unused lines (shouldn't happen, but for safety)
				for i = #edges+1, #lines do
					lines[i].Visible = false
				end
				-- Label above the top center
				-- Find topmost Y (lowest screen Y value)
				local topY, topX = math.huge, 0
				for _, pt in ipairs(corners3D) do
					if pt.Y < topY then topY = pt.Y; topX = pt.X end
				end
				-- Calculate distance
				local camPos = Camera.CFrame.Position
				local planePos = cf.Position
				local distance = (planePos - camPos).Magnitude
				-- Get plane name: prefer StringValue child 'PlaneName', else model.Name
				local planeName = model.Name
				local planeNameValue = model:FindFirstChild("PlaneName")
				if planeNameValue and planeNameValue:IsA("StringValue") then
					planeName = planeNameValue.Value
				end
				label.Text = string.format("%s [%.1f]", planeName, distance)
				label.Position = Vector2.new(topX, topY - 18)
				label.Visible = true
			else
				for i = 1, #lines do
					lines[i].Visible = false
				end
				if label then label.Visible = false end
			end
		else
			if player and ESPObjects[player] then
				RemoveESP(player)
			end
		end
	end

	-- Restore leftwings that are no longer valid
	for leftwing, _ in pairs(ExpandedLeftWings) do
		if not seenLeftwings[leftwing] then
			local mesh = leftwing:FindFirstChildWhichIsA("SpecialMesh") or leftwing:FindFirstChildWhichIsA("Mesh")
			if mesh and OriginalLeftWingSizes[leftwing] then
				mesh.Scale = OriginalLeftWingSizes[leftwing]
			elseif OriginalLeftWingSizes[leftwing] and leftwing and leftwing:IsA("BasePart") then
				leftwing.Size = OriginalLeftWingSizes[leftwing]
			end
			ExpandedLeftWings[leftwing] = nil
			OriginalLeftWingSizes[leftwing] = nil
		end
	end

	-- Remove ESP for players not in viewmodels anymore or are invalid
	for player, box in pairs(ESPObjects) do
		local found = false
		if planeViewmodels then
			for _, model in ipairs(planeViewmodels:GetChildren()) do
				if model.Name == player.Name then found = true break end
			end
		end
		if not found or not player:IsDescendantOf(game) then
			RemoveESP(player)
		end
	end
end

-- Load LuminosityUI from the provided URL
local LuminosityUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Jshawk/luminosity-lite/refs/heads/main/Luminosity%20Lite%20UI.lua"))()

-- Create the main window
local window = LuminosityUI:CreateWindow("Luminosity Wings Of Glory")
window:SetTheme("Dark")

-- Add a main tab
local mainTab = window:AddTab("Main")

-- Add toggles and sliders for ESP and settings
mainTab:AddToggle("ESP Enabled", ESPEnabled, function(val)
    ESPEnabled = val
end)

mainTab:AddToggle("Missile ESP Enabled", MissileESPEnabled, function(val)
    MissileESPEnabled = val
end)

mainTab:AddSlider("ESP Box Scale", 1, 6, ESPBoxScale, function(val)
    ESPBoxScale = val
end)

mainTab:AddSlider("Hitbox Expander Scale", 1, 30, ExpanderScale, function(val)
    ExpanderScale = val
end)


mainTab:AddLabel("Press RightShift to toggle menu", 12, "left")

-- Add a Settings tab
local settingsTab = window:AddTab("Settings")

-- Theme selection dropdown
local themes = {"Dark", "Light", "Blue", "Purple", "Red"}
settingsTab:AddList("Theme", themes, function(selected)
	window:SetTheme(selected)
end)

-- Watermark position
settingsTab:AddList("Watermark Position", {"Left", "Right"}, function(selected)
	window:SetWatermarkPosition(selected)
end)


settingsTab:AddToggle("Show Watermark", true, function(val)
	window:SetWatermarkVisible(val)
end)


-- Add keybind selector to settings (uses UI library's built-in system)

settingsTab:AddKeybind("Menu Toggle Key", Enum.KeyCode.RightShift, function(key)
    window:SetToggleKey(key)
end)

if getgenv then
	local g = getgenv()
	if g.LUMI_WOG_Connection then pcall(function() g.LUMI_WOG_Connection:Disconnect() end) end
	g.LUMI_WOG_Connection = RunService.RenderStepped:Connect(function()
		UpdateESP()
		UpdateMissileESP()
	end)
else
	RunService.RenderStepped:Connect(function()
		UpdateESP()
		UpdateMissileESP()
	end)
end
