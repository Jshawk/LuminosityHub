
-- Table mapping game IDs to script paths
local gameScripts = {
	["338574920"] = "https://luminosityhub-web.onrender.com/raw/wog.lua",
}

-- Key required to execute the script
local requiredKey = "LUMI" -- Change this to your desired key

-- Function to get the current game ID
local function getGameId()
	if game and game.PlaceId then
		return tostring(game.PlaceId)
	elseif _G and _G.GAME_ID then
		return tostring(_G.GAME_ID)
	else
		return "123456"
	end
end

-- Simple key input window (Roblox Drawing API)
local function showKeyWindow(callback)
	local Drawing = Drawing or getgenv().Drawing
	if not Drawing then warn("Drawing API not available"); return end

	local window = Drawing.new("Square")
	window.Size = Vector2.new(300, 120)
	window.Position = Vector2.new(300, 200)
	window.Color = Color3.fromRGB(30, 30, 30)
	window.Filled = true
	window.Visible = true
	window.Thickness = 2

	local outline = Drawing.new("Square")
	outline.Size = Vector2.new(300, 120)
	outline.Position = Vector2.new(300, 200)
	outline.Color = Color3.fromRGB(80, 80, 80)
	outline.Filled = false
	outline.Visible = true
	outline.Thickness = 3

	local title = Drawing.new("Text")
	title.Text = "Enter Key to Continue"
	title.Size = 22
	title.Position = Vector2.new(310, 210)
	title.Color = Color3.fromRGB(255,255,255)
	title.Outline = true
	title.Visible = true

	local inputText = Drawing.new("Text")
	inputText.Text = "Key: "
	inputText.Size = 20
	inputText.Position = Vector2.new(310, 250)
	inputText.Color = Color3.fromRGB(200,200,200)
	inputText.Outline = true
	inputText.Visible = true

	local userInput = ""

	local UIS = game:GetService("UserInputService")
	local conn
	conn = UIS.InputBegan:Connect(function(input, gpe)
		if gpe then return end
		if input.UserInputType == Enum.UserInputType.Keyboard then
			if input.KeyCode == Enum.KeyCode.Return then
				if userInput == requiredKey then
					-- Cleanup
					window:Remove(); outline:Remove(); title:Remove(); inputText:Remove(); conn:Disconnect()
					callback(true)
				else
					inputText.Text = "Key: " .. userInput .. " (Invalid)"
				end
			elseif input.KeyCode == Enum.KeyCode.Backspace then
				userInput = userInput:sub(1, -2)
				inputText.Text = "Key: " .. userInput
			elseif #input.KeyCode.Name == 1 then
				userInput = userInput .. input.KeyCode.Name
				inputText.Text = "Key: " .. userInput
			end
		end
	end)
end

local gameid = getGameId()
local scriptPath = gameScripts[gameid]

local function runScript()
	local httpget = (syn and syn.request) and function(url) return syn.request({Url=url,Method="GET"}).Body end
		or (http and http.request) and function(url) return http.request({Url=url,Method="GET"}).Body end
		or (request) and function(url) return request({Url=url,Method="GET"}).Body end
		or (http and http.get) and http.get
		or (game and game.HttpGet) and function(url) return game:HttpGet(url) end
		or nil
	if scriptPath and httpget then
		local success, err = pcall(function()
			local code = httpget(scriptPath)
			assert(code, "Failed to fetch script")
			loadstring(code)()
		end)
		if not success then
			warn("Failed to load script for gameid " .. gameid .. ": " .. tostring(err))
		end
	elseif not scriptPath then
		warn("No script mapped for gameid: " .. tostring(gameid))
	else
		warn("No HTTP GET method available to fetch script.")
	end
end

if scriptPath then
	showKeyWindow(function(allowed)
		if allowed then
			runScript()
		end
	end)
else
	warn("No script mapped for gameid: " .. tostring(gameid))
end
