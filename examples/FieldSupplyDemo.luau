-- Field Supply: original responsive fixture for ViewportBoard.
-- Set ScreenGui.BrokenLayout=true to demonstrate a fixed-width catalog defect.
local TweenService = game:GetService("TweenService")

local T = {
	Paper = Color3.fromHex("F3F0E7"), Surface = Color3.fromHex("FAF8F1"),
	Ink = Color3.fromHex("25352E"), Muted = Color3.fromHex("7A8073"),
	Sage = Color3.fromHex("6E846B"), Pale = Color3.fromHex("E7EBDD"),
	Line = Color3.fromHex("D9DDCE"), Brass = Color3.fromHex("B59A65"),
	Dark = Color3.fromHex("34483D"), Cream = Color3.fromHex("E9DFC7"),
	Body = Enum.Font.Gotham, Bold = Enum.Font.GothamBold,
	Tween = TweenInfo.new(0.13, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
}

local ITEMS = {
	{ Name = "Alpine field pack", Kind = "CARRY / 24 L", Price = "240", Group = "Essentials", Art = "Pack", Tag = "READY FOR THE LONG WAY", Desc = "A dependable daypack. Room for the essentials, and a little more.", Stat1 = "24 L", Stat2 = "0.8 KG", Note1 = "CAPACITY", Note2 = "WEIGHT" },
	{ Name = "Trail lantern", Kind = "LIGHT / WARM", Price = "120", Group = "Essentials", Art = "Lantern", Tag = "A LITTLE LIGHT GOES FAR", Desc = "Warm light for late arrivals and quiet evenings at camp.", Stat1 = "12 H", Stat2 = "360°", Note1 = "BURN TIME", Note2 = "LIGHT" },
	{ Name = "Summit flask", Kind = "HYDRATION / 750 ML", Price = "85", Group = "Essentials", Art = "Flask", Tag = "TAKE THE SCENIC ROUTE", Desc = "A sturdy trail companion. Made for the next ridge, and the one after.", Stat1 = "750 ML", Stat2 = "0.3 KG", Note1 = "CAPACITY", Note2 = "WEIGHT" },
	{ Name = "Ranger optics", Kind = "EXPLORE / 8 × 32", Price = "310", Group = "Tools", Art = "Optics", Tag = "LOOK A LITTLE CLOSER", Desc = "Spot a distant trail, a hidden landmark, or your next destination.", Stat1 = "8×", Stat2 = "32 MM", Note1 = "MAGNIFY", Note2 = "LENS" },
	{ Name = "Wayfinder compass", Kind = "NAVIGATION / ANALOG", Price = "95", Group = "Tools", Art = "Compass", Tag = "FIND YOUR OWN NORTH", Desc = "Simple, reliable direction. For paths that do not come with signs.", Stat1 = "360°", Stat2 = "0.1 KG", Note1 = "BEARING", Note2 = "WEIGHT" },
	{ Name = "Utility cord", Kind = "UTILITY / 15 M", Price = "60", Group = "Tools", Art = "Cord", Tag = "SMALL KIT. BIG POSSIBILITIES.", Desc = "Tie down your shelter, secure your gear, and keep moving.", Stat1 = "15 M", Stat2 = "4 MM", Note1 = "LENGTH", Note2 = "DIAMETER" },
}

local function make(class, parent, props)
	local obj = Instance.new(class)
	for key, value in pairs(props or {}) do obj[key] = value end
	obj.Parent = parent
	return obj
end

local function corner(parent, value)
	return make("UICorner", parent, { CornerRadius = UDim.new(value or 0.055, 0) })
end

local function pad(parent, x, y)
	return make("UIPadding", parent, { PaddingLeft = UDim.new(x, 0), PaddingRight = UDim.new(x, 0), PaddingTop = UDim.new(y, 0), PaddingBottom = UDim.new(y, 0) })
end

local function frame(parent, name, size, color)
	return make("Frame", parent, { Name = name, Size = size, BackgroundColor3 = color or T.Surface, BackgroundTransparency = if color then 0 else 1, BorderSizePixel = 0 })
end

local function stack(parent, direction, gap)
	return make("UIListLayout", parent, { FillDirection = direction, Padding = UDim.new(gap, 0), SortOrder = Enum.SortOrder.LayoutOrder })
end

local function label(parent, name, text, size, max, bold, color)
	local obj = make("TextLabel", parent, { Name = name, Size = size, BackgroundTransparency = 1, BorderSizePixel = 0, Text = text, Font = if bold then T.Bold else T.Body, TextColor3 = color or T.Ink, TextScaled = true, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Center })
	make("UITextSizeConstraint", obj, { MinTextSize = 9, MaxTextSize = max })
	return obj
end

local function shape(parent, x, y, w, h, color, radius, rotation, z)
	local obj = frame(parent, "Shape", UDim2.fromScale(w, h), color)
	obj.Position = UDim2.fromScale(x, y)
	obj.Rotation = rotation or 0
	obj.ZIndex = z or 2
	if radius then corner(obj, radius) end
	return obj
end

local function ring(parent, x, y, w, h, color, thickness, z)
	local obj = shape(parent, x, y, w, h, T.Pale, 0.5, 0, z)
	obj.BackgroundTransparency = 1
	make("UIStroke", obj, { Color = color, Thickness = thickness })
	return obj
end

local function draw(parent, kind)
	local art = frame(parent, "Illustration", UDim2.fromScale(0.88, 0.94))
	art.AnchorPoint = Vector2.new(0.5, 0.5)
	art.Position = UDim2.fromScale(0.5, 0.5)
	make("UIAspectRatioConstraint", art, { AspectRatio = 1 })
	shape(art, 0.08, 0.10, 0.84, 0.84, T.Pale, 0.5, 0, 1)
	shape(art, 0.22, 0.83, 0.58, 0.065, Color3.fromHex("CFD6C6"), 0.5, 0, 1)
	if kind == "Pack" then
		ring(art, 0.39, 0.08, 0.22, 0.23, T.Dark, 5, 2)
		shape(art, 0.21, 0.38, 0.11, 0.39, T.Dark, 0.17, -5)
		shape(art, 0.68, 0.38, 0.11, 0.39, T.Dark, 0.17, 5)
		shape(art, 0.27, 0.23, 0.46, 0.61, T.Sage, 0.14)
		shape(art, 0.28, 0.23, 0.44, 0.22, Color3.fromHex("85957B"), 0.18, 0, 3)
		shape(art, 0.34, 0.55, 0.32, 0.23, T.Dark, 0.13, 0, 3)
		shape(art, 0.34, 0.55, 0.32, 0.055, Color3.fromHex("4A5E4C"), 0.12, 0, 4)
		shape(art, 0.45, 0.31, 0.10, 0.27, T.Cream, 0.08, 0, 4)
		shape(art, 0.435, 0.43, 0.13, 0.10, T.Brass, 0.08, 0, 5)
		shape(art, 0.475, 0.445, 0.05, 0.07, T.Dark, 0.08, 0, 6)
	elseif kind == "Lantern" then
		ring(art, 0.34, 0.08, 0.32, 0.27, T.Dark, 5)
		shape(art, 0.31, 0.31, 0.38, 0.48, Color3.fromHex("E5C680"), 0.12)
		shape(art, 0.39, 0.35, 0.22, 0.38, Color3.fromHex("F4DDA5"), 0.1, 0, 3)
		shape(art, 0.25, 0.27, 0.50, 0.12, T.Dark, 0.2, 0, 4)
		shape(art, 0.27, 0.73, 0.46, 0.13, T.Dark, 0.18, 0, 4)
		shape(art, 0.31, 0.35, 0.045, 0.42, T.Dark, 0, 0, 4)
		shape(art, 0.645, 0.35, 0.045, 0.42, T.Dark, 0, 0, 4)
		shape(art, 0.47, 0.41, 0.06, 0.27, T.Cream, 0.5, 0, 4)
	elseif kind == "Flask" then
		local group = shape(art, 0.25, 0.16, 0.48, 0.71, T.Pale, nil, 12)
		group.BackgroundTransparency = 1
		shape(group, 0.32, 0, 0.36, 0.17, T.Dark, 0.12)
		shape(group, 0.19, 0.14, 0.62, 0.82, T.Cream, 0.18)
		shape(group, 0.19, 0.38, 0.62, 0.32, T.Sage, 0, 0, 3)
		shape(group, 0.30, 0.22, 0.08, 0.61, Color3.fromHex("F5EDD9"), 0.4, 0, 4).BackgroundTransparency = 0.45
		shape(group, 0.44, 0.45, 0.12, 0.13, T.Cream, 0.12, 45, 4)
	elseif kind == "Optics" then
		shape(art, 0.34, 0.38, 0.32, 0.22, T.Dark, 0.1)
		shape(art, 0.20, 0.24, 0.24, 0.53, T.Sage, 0.2, 7)
		shape(art, 0.56, 0.24, 0.24, 0.53, T.Sage, 0.2, -7)
		shape(art, 0.23, 0.20, 0.17, 0.16, T.Dark, 0.15, 7, 3)
		shape(art, 0.60, 0.20, 0.17, 0.16, T.Dark, 0.15, -7, 3)
		shape(art, 0.15, 0.60, 0.32, 0.24, T.Dark, 0.5, 0, 3)
		shape(art, 0.53, 0.60, 0.32, 0.24, T.Dark, 0.5, 0, 3)
		shape(art, 0.205, 0.64, 0.21, 0.15, Color3.fromHex("91A6A0"), 0.5, 0, 4)
		shape(art, 0.585, 0.64, 0.21, 0.15, Color3.fromHex("91A6A0"), 0.5, 0, 4)
		shape(art, 0.26, 0.66, 0.07, 0.05, T.Cream, 0.5, 0, 5)
		shape(art, 0.64, 0.66, 0.07, 0.05, T.Cream, 0.5, 0, 5)
	elseif kind == "Compass" then
		ring(art, 0.42, 0.07, 0.16, 0.17, T.Brass, 4)
		shape(art, 0.19, 0.21, 0.62, 0.62, T.Brass, 0.5)
		shape(art, 0.25, 0.27, 0.50, 0.50, T.Surface, 0.5, 0, 3)
		shape(art, 0.485, 0.29, 0.03, 0.06, T.Dark, 0, 0, 4)
		shape(art, 0.485, 0.69, 0.03, 0.06, T.Dark, 0, 0, 4)
		shape(art, 0.27, 0.505, 0.07, 0.03, T.Dark, 0, 0, 4)
		shape(art, 0.66, 0.505, 0.07, 0.03, T.Dark, 0, 0, 4)
		shape(art, 0.46, 0.36, 0.08, 0.32, T.Dark, 0.06, 27, 4)
		shape(art, 0.495, 0.36, 0.07, 0.16, Color3.fromHex("B2664D"), 0.06, 27, 5)
		shape(art, 0.46, 0.48, 0.08, 0.08, T.Brass, 0.5, 0, 6)
	elseif kind == "Cord" then
		for index = 0, 4 do
			ring(art, 0.22 + index * 0.047, 0.18, 0.36, 0.61, if index % 2 == 0 then T.Brass else Color3.fromHex("C9B588"), 6, 2 + index)
		end
		shape(art, 0.20, 0.43, 0.61, 0.16, T.Sage, 0.1, -6, 8)
		shape(art, 0.44, 0.43, 0.13, 0.14, T.Dark, 0.08, -6, 9)
		shape(art, 0.59, 0.68, 0.065, 0.18, T.Brass, 0.2, -28, 8)
	end
	return art
end

return function(parent)
	local gui = make("ScreenGui", parent, { Name = "FieldSupplyDemo", ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets, DisplayOrder = 10 })
	gui:SetAttribute("BrokenLayout", false)
	gui:SetAttribute("SelectedItem", "Alpine field pack")
	gui:SetAttribute("FixtureVersion", "1.0")
	local connections = {}
	local function listen(signal, callback)
		local connection = signal:Connect(callback)
		table.insert(connections, connection)
		return connection
	end
	local root = frame(gui, "FieldSupply", UDim2.fromScale(1, 1), T.Paper)
	root.ClipsDescendants = true
	pad(root, 0.045, 0.045)
	stack(root, Enum.FillDirection.Vertical, 0.014)
	local header = frame(root, "Header", UDim2.fromScale(1, 0.075)); header.LayoutOrder = 1
	local brand = label(header, "Brand", "FIELD / SUPPLY", UDim2.fromScale(0.58, 1), 23, true)
	local wallet = label(header, "Wallet", "1,280  CREDITS", UDim2.fromScale(0.39, 1), 12, true, T.Muted)
	wallet.AnchorPoint = Vector2.new(1, 0); wallet.Position = UDim2.fromScale(1, 0); wallet.TextXAlignment = Enum.TextXAlignment.Right
	local intro = frame(root, "Introduction", UDim2.fromScale(1, 0.125)); intro.LayoutOrder = 2
	stack(intro, Enum.FillDirection.Vertical, 0.04)
	label(intro, "Eyebrow", "OUTPOST 07  /  THE EQUIPMENT ROOM", UDim2.fromScale(1, 0.22), 11, true, T.Muted).LayoutOrder = 1
	label(intro, "Title", "Good gear. Great outdoors.", UDim2.fromScale(1, 0.63), 40, true).LayoutOrder = 2
	local nav = frame(root, "Navigation", UDim2.fromScale(1, 0.075)); nav.LayoutOrder = 3
	local tabs = frame(nav, "Categories", UDim2.fromScale(0.68, 1))
	stack(tabs, Enum.FillDirection.Horizontal, 0.025)
	local count = label(nav, "ItemCount", "06 ESSENTIALS", UDim2.fromScale(0.3, 1), 10, true, T.Muted)
	count.AnchorPoint = Vector2.new(1, 0); count.Position = UDim2.fromScale(1, 0); count.TextXAlignment = Enum.TextXAlignment.Right
	local scroll = make("ScrollingFrame", root, { Name = "Equipment", LayoutOrder = 4, Size = UDim2.fromScale(1, 0.63), BackgroundTransparency = 1, BorderSizePixel = 0, CanvasSize = UDim2.fromScale(0, 0), ScrollBarThickness = 3, ScrollBarImageColor3 = T.Sage, ScrollingDirection = Enum.ScrollingDirection.Y })
	local bodyList = stack(scroll, Enum.FillDirection.Horizontal, 0.03)
	local catalog = frame(scroll, "Catalog", UDim2.fromScale(0.65, 1)); catalog.LayoutOrder = 1
	local grid = make("UIGridLayout", catalog, { SortOrder = Enum.SortOrder.LayoutOrder, CellSize = UDim2.fromScale(0.32, 0.48), CellPadding = UDim2.fromScale(0.02, 0.04), FillDirectionMaxCells = 3 })
	local detail = frame(scroll, "ItemDetails", UDim2.fromScale(0.32, 1), T.Surface); detail.LayoutOrder = 2
	corner(detail, 0.035); pad(detail, 0.075, 0.055)
	make("UIStroke", detail, { Color = T.Line, Thickness = 1 })
	stack(detail, Enum.FillDirection.Vertical, 0.015)
	local tag = label(detail, "Tagline", "", UDim2.fromScale(1, 0.035), 9, true, T.Sage); tag.LayoutOrder = 1
	local title = label(detail, "ItemName", "", UDim2.fromScale(1, 0.10), 28, true); title.LayoutOrder = 2
	local desc = label(detail, "Description", "", UDim2.fromScale(1, 0.085), 12, false, T.Muted); desc.LayoutOrder = 3
	local hero = frame(detail, "ItemArtwork", UDim2.fromScale(1, 0.31)); hero.LayoutOrder = 4
	local line = frame(detail, "Divider", UDim2.fromScale(1, 0.003), T.Line); line.LayoutOrder = 5
	local stats = frame(detail, "Specifications", UDim2.fromScale(1, 0.095)); stats.LayoutOrder = 6
	stack(stats, Enum.FillDirection.Horizontal, 0.04)
	local statFields = {}
	for i = 1, 2 do
		local cell = frame(stats, "Specification" .. i, UDim2.fromScale(0.48, 1)); cell.LayoutOrder = i
		stack(cell, Enum.FillDirection.Vertical, 0.07)
		local value = label(cell, "Value", "", UDim2.fromScale(1, 0.60), 19, true); value.LayoutOrder = 1
		local note = label(cell, "Caption", "", UDim2.fromScale(1, 0.29), 9, true, T.Muted); note.LayoutOrder = 2
		statFields[i] = { value, note }
	end
	local price = label(detail, "Price", "", UDim2.fromScale(1, 0.07), 22, true); price.LayoutOrder = 7
	local equip = make("TextButton", detail, { Name = "EquipButton", LayoutOrder = 8, Size = UDim2.fromScale(1, 0.115), Text = "ADD TO LOADOUT", TextScaled = true, Font = T.Bold, TextColor3 = T.Surface, BackgroundColor3 = T.Dark, BorderSizePixel = 0, AutoButtonColor = true })
	corner(equip, 0.16); pad(equip, 0.1, 0.25); make("UITextSizeConstraint", equip, { MinTextSize = 10, MaxTextSize = 12 })
	local foot = frame(root, "Footer", UDim2.fromScale(1, 0.03)); foot.LayoutOrder = 5
	label(foot, "FooterText", "PACK LIGHT. WANDER FAR.", UDim2.fromScale(0.7, 1), 9, true, T.Muted)
	local edition = label(foot, "Edition", "EST. 2026", UDim2.fromScale(0.28, 1), 9, false, T.Muted)
	edition.AnchorPoint = Vector2.new(1, 0); edition.Position = UDim2.fromScale(1, 0); edition.TextXAlignment = Enum.TextXAlignment.Right

	local selected = 1
	local activeCategory = "All gear"
	local cards, tabButtons, equipped = {}, {}, {}
	local updateLayout
	local function updateSelection(index)
		selected = index
		local item = ITEMS[index]
		gui:SetAttribute("SelectedItem", item.Name)
		tag.Text = item.Tag; title.Text = item.Name; desc.Text = item.Desc
		price.Text = item.Price .. "  credits"
		statFields[1][1].Text = item.Stat1; statFields[1][2].Text = item.Note1
		statFields[2][1].Text = item.Stat2; statFields[2][2].Text = item.Note2
		for _, child in hero:GetChildren() do child:Destroy() end
		draw(hero, item.Art)
		equip.Text = if equipped[index] then "IN YOUR LOADOUT" else "ADD TO LOADOUT"
		equip.BackgroundColor3 = if equipped[index] then T.Sage else T.Dark
		for i, card in ipairs(cards) do
			card.Button.BackgroundColor3 = if i == index then T.Pale else T.Surface
			card.Stroke.Color = if i == index then T.Sage else T.Line
			card.Stroke.Thickness = if i == index then 2 else 1
		end
	end

	for i, item in ipairs(ITEMS) do
		local card = make("TextButton", catalog, { Name = item.Art .. "Card", LayoutOrder = i, Text = "", AutoButtonColor = false, BackgroundColor3 = T.Surface, BorderSizePixel = 0, Size = UDim2.fromScale(0.32, 0.48) })
		corner(card, 0.045); pad(card, 0.075, 0.055)
		local stroke = make("UIStroke", card, { Color = T.Line, Thickness = 1 })
		stack(card, Enum.FillDirection.Vertical, 0.012)
		local image = frame(card, "ItemArtwork", UDim2.fromScale(1, 0.61)); image.LayoutOrder = 1
		draw(image, item.Art)
		label(card, "Category", item.Kind, UDim2.fromScale(1, 0.075), 8, true, T.Muted).LayoutOrder = 2
		label(card, "ItemName", item.Name, UDim2.fromScale(1, 0.14), 16, true).LayoutOrder = 3
		label(card, "Price", item.Price .. " cr", UDim2.fromScale(1, 0.11), 12, false, T.Sage).LayoutOrder = 4
		cards[i] = { Button = card, Stroke = stroke }
		listen(card.Activated, function() updateSelection(i) end)
		listen(card.MouseEnter, function() TweenService:Create(stroke, T.Tween, { Color = T.Sage }):Play() end)
		listen(card.MouseLeave, function() TweenService:Create(stroke, T.Tween, { Color = if selected == i then T.Sage else T.Line }):Play() end)
		listen(card.MouseButton1Down, function() card.BackgroundColor3 = T.Pale end)
		listen(card.MouseButton1Up, function() card.BackgroundColor3 = if selected == i then T.Pale else T.Surface end)
	end
	for order, category in ipairs({ "All gear", "Essentials", "Tools" }) do
		local button = make("TextButton", tabs, { Name = category, LayoutOrder = order, Size = UDim2.fromScale(0.31, 1), Text = category, TextScaled = true, Font = T.Bold, TextColor3 = T.Ink, BackgroundColor3 = T.Pale, BorderSizePixel = 0, AutoButtonColor = true })
		corner(button, 0.18); pad(button, 0.07, 0.25); make("UITextSizeConstraint", button, { MinTextSize = 9, MaxTextSize = 12 })
		tabButtons[category] = button
		listen(button.Activated, function()
			activeCategory = category
			for name, tab in pairs(tabButtons) do
				tab.BackgroundColor3 = if name == category then T.Dark else T.Pale
				tab.TextColor3 = if name == category then T.Surface else T.Ink
			end
			local first, total = nil, 0
			for i, item in ipairs(ITEMS) do
				local visible = category == "All gear" or item.Group == category
				cards[i].Button.Visible = visible
				if visible then first = first or i; total += 1 end
			end
			count.Text = string.format("%02d ITEMS", total)
			if not cards[selected].Button.Visible then updateSelection(first or 1) end
			updateLayout()
		end)
	end
	tabButtons["All gear"].BackgroundColor3 = T.Dark; tabButtons["All gear"].TextColor3 = T.Surface
	listen(equip.Activated, function()
		equipped[selected] = not equipped[selected]
		updateSelection(selected)
	end)

	updateLayout = function()
		local size = scroll.AbsoluteSize
		if size.X < 1 or size.Y < 1 then return end
		local broken = gui:GetAttribute("BrokenLayout") == true
		local narrow = size.X < 680 and not broken
		local columns = if narrow then 2 else 3
		local visibleCount = if activeCategory == "All gear" then 6 else 3
		local rows = math.ceil(visibleCount / columns)
		local catalogWidth = if narrow then size.X else size.X * 0.65
		if broken then catalogWidth = 690 end
		local gapX = 0.035
		local cellWidth = catalogWidth * (1 - gapX * (columns - 1)) / columns
		local cellHeight = cellWidth / (if narrow then 1.04 else 1.28)
		local gapY = cellHeight * 0.07
		local catalogHeight = rows * cellHeight + (rows - 1) * gapY
		local detailHeight = if narrow then math.max(380, size.X * 1.15) else math.max(catalogHeight, math.min(365, size.Y))
		catalog.Size = UDim2.fromScale(catalogWidth / size.X, catalogHeight / size.Y)
		detail.Size = UDim2.fromScale(if narrow then 1 else 0.32, detailHeight / size.Y)
		grid.FillDirectionMaxCells = columns
		grid.CellSize = UDim2.fromScale(cellWidth / catalogWidth, cellHeight / catalogHeight)
		grid.CellPadding = UDim2.fromScale(gapX, gapY / catalogHeight)
		bodyList.FillDirection = if narrow then Enum.FillDirection.Vertical else Enum.FillDirection.Horizontal
		bodyList.Padding = UDim.new(0.03, 0)
		scroll.CanvasSize = UDim2.fromOffset(0, if narrow then catalogHeight + detailHeight + size.Y * 0.04 else math.max(catalogHeight, detailHeight) + 4)
		tabs.Size = UDim2.fromScale(if narrow then 1 else 0.68, 1)
		count.Visible = not narrow
		brand:FindFirstChildOfClass("UITextSizeConstraint").MaxTextSize = if narrow then 17 else 23
	end
	listen(scroll:GetPropertyChangedSignal("AbsoluteSize"), updateLayout)
	listen(gui:GetAttributeChangedSignal("BrokenLayout"), updateLayout)
	listen(gui.Destroying, function()
		for _, connection in ipairs(connections) do connection:Disconnect() end
		table.clear(connections)
	end)
	updateSelection(1)
	updateLayout()
	return gui
end
