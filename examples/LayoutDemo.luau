--!nonstrict

return function(parent)
	local palette = { paper = Color3.fromRGB(246, 243, 235), ink = Color3.fromRGB(36, 45, 39), muted = Color3.fromRGB(103, 110, 96), green = Color3.fromRGB(69, 89, 61) }
	local function make(class, owner, props)
		local object = Instance.new(class)
		for key, value in props do object[key] = value end
		object.Parent = owner
		return object
	end
	local function label(owner, value, position, size, fontSize, color)
		return make("TextLabel", owner, {
			Text = value, Position = position, Size = size, TextSize = fontSize,
			Font = Enum.Font.GothamMedium, TextColor3 = color or palette.ink,
			TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true, BackgroundTransparency = 1,
		})
	end
	local function shape(owner, color, position, size, radius)
		local frame = make("Frame", owner, { BackgroundColor3 = color, Position = position, Size = size, BorderSizePixel = 0 })
		make("UICorner", frame, { CornerRadius = UDim.new(0, radius or 5) })
		return frame
	end
	local gui = make("ScreenGui", parent, { Name = "FieldSupplyLayout", ResetOnSpawn = false, IgnoreGuiInset = true })
	local page = make("Frame", gui, { Name = "Page", Size = UDim2.fromScale(1, 1), BackgroundColor3 = palette.paper, BorderSizePixel = 0 })
	local content = make("ScrollingFrame", page, {
		Name = "Content", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0,
		CanvasSize = UDim2.new(0, 0, 0, 850), ScrollBarThickness = 3,
	})
	local column = make("Frame", content, {
		Name = "Column", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0),
		Size = UDim2.new(1, 0, 0, 850), BackgroundTransparency = 1,
	})
	make("UISizeConstraint", column, { MaxSize = Vector2.new(980, 850) })
	label(column, "FIELD / SUPPLY", UDim2.fromOffset(24, 24), UDim2.new(1, -48, 0, 22), 16, palette.green)
	local heading = label(column, "Ready for the trail.", UDim2.fromOffset(24, 60), UDim2.new(1, -48, 0, 48), 28)
	heading.Font = Enum.Font.GothamBold
	label(column, "Thoughtful gear. A lighter pack. Your next adventure starts here.", UDim2.fromOffset(24, 114), UDim2.new(1, -48, 0, 44), 14, palette.muted)
	shape(column, Color3.fromRGB(218, 221, 207), UDim2.fromOffset(24, 177), UDim2.new(1, -48, 0, 1), 0)
	label(column, "THE WEEKEND KIT", UDim2.fromOffset(24, 194), UDim2.new(1, -48, 0, 20), 12, palette.muted)
	local catalog = make("Frame", column, {
		Name = "Catalog", Position = UDim2.fromOffset(24, 232), Size = UDim2.new(1, -48, 0, 446), BackgroundTransparency = 1,
	})
	make("UIGridLayout", catalog, { CellSize = UDim2.new(0.48, 0, 0, 216), CellPadding = UDim2.new(0.04, 0, 0, 14), SortOrder = Enum.SortOrder.LayoutOrder })
	local items = {
		{ "Alpine field pack", "24 L / EVERYDAY", "$64", Color3.fromRGB(112, 129, 94), "pack" },
		{ "Trail lantern", "WARM LIGHT / 18 H", "$38", Color3.fromRGB(176, 139, 78), "lamp" },
		{ "Summit flask", "750 ML / STEEL", "$28", Color3.fromRGB(111, 131, 136), "flask" },
		{ "Wayfinder compass", "FIND YOUR NORTH", "$32", Color3.fromRGB(141, 111, 84), "compass" },
	}
	for index, item in items do
		local card = make("Frame", catalog, { Name = "Item" .. index, LayoutOrder = index, BorderSizePixel = 0, BackgroundColor3 = Color3.fromRGB(234, 232, 221) })
		make("UICorner", card, { CornerRadius = UDim.new(0, 8) })
		local art = make("Frame", card, { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 12), Size = UDim2.fromOffset(120, 118), BackgroundTransparency = 1 })
		if item[5] == "pack" then
			shape(art, palette.ink, UDim2.fromOffset(39, 9), UDim2.fromOffset(42, 31), 10)
			shape(art, item[4], UDim2.fromOffset(23, 19), UDim2.fromOffset(74, 88), 14)
			shape(art, Color3.fromRGB(141, 155, 117), UDim2.fromOffset(29, 24), UDim2.fromOffset(62, 29), 9)
			shape(art, palette.green, UDim2.fromOffset(37, 69), UDim2.fromOffset(46, 30), 6)
			shape(art, palette.paper, UDim2.fromOffset(54, 49), UDim2.fromOffset(12, 12), 2)
		elseif item[5] == "lamp" then
			shape(art, palette.ink, UDim2.fromOffset(39, 6), UDim2.fromOffset(42, 32), 16)
			shape(art, Color3.fromRGB(240, 213, 153), UDim2.fromOffset(33, 34), UDim2.fromOffset(54, 61), 8)
			shape(art, item[4], UDim2.fromOffset(27, 27), UDim2.fromOffset(66, 17), 6)
			shape(art, item[4], UDim2.fromOffset(27, 91), UDim2.fromOffset(66, 17), 6)
			shape(art, palette.paper, UDim2.fromOffset(53, 51), UDim2.fromOffset(14, 34), 6)
		elseif item[5] == "flask" then
			shape(art, palette.ink, UDim2.fromOffset(44, 8), UDim2.fromOffset(32, 19), 5)
			shape(art, item[4], UDim2.fromOffset(32, 24), UDim2.fromOffset(56, 84), 16)
			shape(art, Color3.fromRGB(160, 178, 174), UDim2.fromOffset(41, 34), UDim2.fromOffset(9, 56), 4)
			label(art, "F / S", UDim2.fromOffset(47, 61), UDim2.fromOffset(38, 22), 12, palette.paper)
		else
			shape(art, item[4], UDim2.fromOffset(17, 15), UDim2.fromOffset(86, 86), 43)
			local dial = shape(art, palette.paper, UDim2.fromOffset(26, 24), UDim2.fromOffset(68, 68), 34)
			label(dial, "N", UDim2.fromOffset(26, 3), UDim2.fromOffset(20, 18), 11, palette.green)
			local needle = shape(dial, palette.green, UDim2.fromOffset(29, 23), UDim2.fromOffset(9, 31), 2)
			needle.Rotation = 24
		end
		local title = label(card, item[1], UDim2.fromOffset(12, 137), UDim2.new(1, -24, 0, 34), 14)
		title.TextYAlignment = Enum.TextYAlignment.Top
		label(card, item[2], UDim2.fromOffset(12, 174), UDim2.new(1, -24, 0, 16), 9, palette.muted)
		label(card, item[3], UDim2.fromOffset(12, 191), UDim2.new(1, -24, 0, 16), 12, palette.green)
	end
	local footer = shape(column, palette.green, UDim2.fromOffset(24, 711), UDim2.new(1, -48, 0, 88), 8)
	label(footer, "Pack less. Explore more.", UDim2.fromOffset(16, 12), UDim2.new(1, -32, 0, 28), 17, palette.paper)
	label(footer, "Built for the paths worth taking.", UDim2.fromOffset(16, 45), UDim2.new(1, -32, 0, 28), 12, palette.paper)
	return gui
end
