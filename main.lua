--[[
    SuperForest – Shop Stock Webhook Bot
]]

--// =========================
--// CONFIGURATION
--// =========================

_G.Configuration = {
	Enabled = true,
	Webhook = "https://discord.com/api/webhooks/1465557779791085690/Dmg1hqNm3I3mF5iQgImKH_miSzKk_atd5Hokr_tyLumkjIqWd6B1OAgmO1u8BF4_MQRU", -- PUT YOUR WEBHOOK HERE
	
	-- Global role ping on any restock
	RestockRolePing = "",

	-- Item-specific role pings (ONLY pinged if item is available)
	ItemRolePings = {
		["Toadstool Tree"] = "<@&1465559753915896034>",
		["Illustrious Tree"] = "<@&1465559833456414867>",
		["Enchanted Tulip"] = "<@&1465560026427953202>",
		["Crystal Tulip"] = "<@&1465560076759732367>",
		["Enchanted Orchid"] = "<@&1465560138029994095>",
		["Enchanted Willow"] = "<@&1465577332051017741>",
		["Illustrious Tile"] = "<@&1465560287615779023>",
		["Crystal Tile"] = "<@&1465560355450261783>",
		["Bush Tile"] = "<@&1465560245525942336>",
		["TimeBoost Rare"] = "<@&1465560472932716687>",
		["CloudBoost Legendary"] = "<@&1465560524799606827>",
		["Large Floating Lantern"] = "<@&1465560682400317646>",
		["Fireflies"] = "<@&1465560599390978070>",
		["Spirit Spring"] = "<@&1465560643703803964>",
		["Waterfall"] = "<@&1466574492213055729>",
		["Red Maple"] = "<@&1466959767498129489>",
		["Spade"] = "<@&1466691381044187439>",
		
		
	},

	AntiAFK = true,
	AutoReconnect = true,
}

--// =========================
--// SERVICES
--// =========================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local VirtualUser = cloneref(game:GetService("VirtualUser"))
local TeleportService = game:GetService("TeleportService")

local LocalPlayer = Players.LocalPlayer
local PlaceId = game.PlaceId
local JobId = game.JobId
--// =========================
--// KNIT REMOTES
--// =========================

local ShopRestockedRE = ReplicatedStorage.Packages._Index["sleitnick_knit@1.7.0"]
	.knit.Services.ShopService.RE.ShopRestocked

local GetCategoryStockRF = ReplicatedStorage.Packages._Index["sleitnick_knit@1.7.0"]
	.knit.Services.ShopService.RF.GetCategoryStock

--// =========================
--// CATEGORY DEFINITIONS
--// =========================

local ShopCategories = {
	[1] = { Name = "Tiles",      Color = Color3.fromRGB(80, 170, 255) },
	[2] = { Name = "Trees",      Color = Color3.fromRGB(80, 255, 140) },
	[3] = { Name = "Booster",    Color = Color3.fromRGB(255, 215, 80) },
	[4] = { Name = "Decoration", Color = Color3.fromRGB(200, 120, 255) },
}

--// =========================
--// INTERNAL STATE
--// =========================

local LastKnownStock = {}
local LastFetchTime = {}
local FETCH_COOLDOWN = 2 -- seconds

--// =========================
--// UTILITIES
--// =========================

local function Color3ToDecimal(color: Color3): number
	return tonumber(color:ToHex(), 16)
end

--// =========================
--// FORMAT STOCK (3 COLUMNS)
--// =========================

local function FormatStockColumns(stockTable: table)
	local items = {}
	local filtered = {}

	for itemName, amount in pairs(stockTable) do
		if amount > 0 then
			local readable = itemName:gsub("_", " ")
			table.insert(items, string.format("%s x%d", readable, amount))
			filtered[itemName] = amount
		end
	end

	if #items == 0 then
		return {
			{
				name = "Stock",
				value = "*No items available*",
				inline = false
			}
		}, filtered
	end

	local fields = {}
	local maxItems = math.min(#items, 15)
	local column = 1

	for i = 1, maxItems, 5 do
		local chunk = table.concat(items, "\n", i, math.min(i + 4, maxItems))

		table.insert(fields, {
			name = column == 1 and "Stock" or "‎",
			value = chunk,
			inline = true
		})

		column += 1
		if column > 3 then break end
	end

	return fields, filtered
end

--// =========================
--// CHANGE DETECTION
--// =========================

local function HasStockChanged(categoryId: number, newStock: table): boolean
	local oldStock = LastKnownStock[categoryId]

	if not oldStock then
		LastKnownStock[categoryId] = newStock
		return true
	end

	for item, amount in pairs(newStock) do
		if oldStock[item] ~= amount then
			LastKnownStock[categoryId] = newStock
			return true
		end
	end

	return false
end

--// =========================
--// ITEM ROLE PINGS
--// =========================

local function GetItemRolePings(filteredStock: table): string
	local pings = {}
	local itemRoles = _G.Configuration.ItemRolePings or {}

	for itemName in pairs(filteredStock) do
		local readable = itemName:gsub("_", " ")
		local rolePing = itemRoles[readable]
		if rolePing then
			table.insert(pings, rolePing)
		end
	end

	return table.concat(pings, " ")
end

--// =========================
--// WEBHOOK
--// =========================

local function SendWebhook(categoryId: number, stockTable: table)
	if not _G.Configuration.Enabled then return end

	local category = ShopCategories[categoryId]
	if not category then return end

	local fields, filteredStock = FormatStockColumns(stockTable)
	if not HasStockChanged(categoryId, filteredStock) then return end

	local itemPings = GetItemRolePings(filteredStock)

	local content = table.concat({
		_G.Configuration.RestockRolePing or "",
		itemPings
	}, " ")

	local body = {
		content = content ~= "" and content or nil,
		embeds = {
			{
				title = category.Name .. " Restock",
				fields = fields,
				color = Color3ToDecimal(category.Color),
				footer = {
					text = "SuperForest • Stock Tracker"
				},
				timestamp = DateTime.now():ToIsoDate()
			}
		}
	}

	task.spawn(request, {
		Url = _G.Configuration.Webhook,
		Method = "POST",
		Headers = { ["Content-Type"] = "application/json" },
		Body = HttpService:JSONEncode(body)
	})
end

--// =========================
--// REAL-TIME RESTOCK LISTENER
--// =========================

ShopRestockedRE.OnClientEvent:Connect(function(categoryId: number)
	local category = ShopCategories[categoryId]
	if not category then return end

	local now = tick()
	if now - (LastFetchTime[categoryId] or 0) < FETCH_COOLDOWN then
		return
	end
	LastFetchTime[categoryId] = now

	local success, stock = pcall(function()
		return GetCategoryStockRF:InvokeServer(categoryId)
	end)

	if success and type(stock) == "table" then
		SendWebhook(categoryId, stock)
	end
end)

--// =========================
--// ANTI-AFK
--// =========================

if _G.Configuration.AntiAFK then
	LocalPlayer.Idled:Connect(function()
		VirtualUser:CaptureController()
		VirtualUser:ClickButton2(Vector2.new())
	end)
end

--// =========================
--// AUTO RECONNECT
--// =========================

if _G.Configuration.AutoReconnect then
	Players.LocalPlayer.OnTeleport:Connect(function()
		-- Nothing needed, already teleporting
	end)

	game:GetService("GuiService").ErrorMessageChanged:Connect(function()
		-- If disconnected, teleport back to same server
		if true then
			task.spawn(function()
				TeleportService:Teleport(game.PlaceId, player)
			end)
		end
	end)
end
