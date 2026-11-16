--!nonstrict

local Theme = require(script.Parent.Theme)
local Layout = require(script.Parent.Layout)
local View = {}
View.__index = View

local function make(class, parent, properties, role)
	local object = Instance.new(class)
	for key, value in properties do object[key] = value end
	if role then object:SetAttribute("VBRole", role) end
	object.Parent = parent
	Theme.paint(object)
	return object
end

local function text(parent, value, size, role)
	return make("TextLabel", parent, {
		BackgroundTransparency = 1, Text = value, TextSize = size or 14,
		Font = Enum.Font.SourceSans, TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, 0, 0, 20), TextTruncate = Enum.TextTruncate.AtEnd,
	}, role or "text")
end

local function round(object)
	make("UICorner", object, { CornerRadius = UDim.new(0, 4) })
end

local function button(parent, caption, callback, primary)
	local object = make("TextButton", parent, {
		Text = caption, TextSize = 14, Font = Enum.Font.SourceSansSemibold,
		AutoButtonColor = false, Size = UDim2.new(0, 100, 0, 28), BorderSizePixel = 0,
		TextTruncate = Enum.TextTruncate.AtEnd,
	}, "button")
	object:SetAttribute("Primary", primary or false)
	round(object)
	object.MouseEnter:Connect(function() object:SetAttribute("Hover", true) Theme.paint(object) end)
	object.MouseLeave:Connect(function()
		object:SetAttribute("Hover", false)
		object:SetAttribute("Pressed", false)
		Theme.paint(object)
	end)
	object.MouseButton1Down:Connect(function() object:SetAttribute("Pressed", true) Theme.paint(object) end)
	object.MouseButton1Up:Connect(function() object:SetAttribute("Pressed", false) Theme.paint(object) end)
	object.Activated:Connect(function() if object.Active then callback() end end)
	Theme.paint(object)
	return object
end

local function enabled(object, value)
	object.Active = value
	object.Selectable = value
	Theme.paint(object)
end

local function clear(parent)
	for _, child in parent:GetChildren() do
		if child:IsA("GuiObject") then child:Destroy() end
	end
end

local function scroll(parent, position, size)
	local object = make("ScrollingFrame", parent, {
		Position = position, Size = size, BackgroundTransparency = 1, BorderSizePixel = 0,
		CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 4, ScrollingDirection = Enum.ScrollingDirection.Y,
	})
	make("UIListLayout", object, { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6) })
	make("UIPadding", object, { PaddingRight = UDim.new(0, 8) })
	return object
end

function View.new(widget, callbacks)
	local self = setmetatable({ callbacks = callbacks, busy = false, deviceButtons = {} }, View)
	self.root = make("Frame", widget, { Size = UDim2.fromScale(1, 1), BorderSizePixel = 0 }, "surface")
	local header = text(self.root, "Review your UI across devices", 18)
	header.Font = Enum.Font.SourceSansSemibold
	header.Position, header.Size = UDim2.fromOffset(12, 10), UDim2.new(1, -24, 0, 24)
	local hint = text(self.root, "Select a ScreenGui or root GUI object in Explorer.", 14, "muted")
	self.hint = hint
	hint.Position, hint.Size = UDim2.fromOffset(12, 35), UDim2.new(1, -24, 0, 20)
	self.layoutMode = button(self.root, "Layout snapshots", function() callbacks.mode("layout") end)
	self.layoutMode.Position, self.layoutMode.Size = UDim2.fromOffset(12, 64), UDim2.new(0.5, -16, 0, 26)
	self.screenshotMode = button(self.root, "Screenshots · experimental", function() callbacks.mode("screenshot") end)
	self.screenshotMode.Position, self.screenshotMode.Size = UDim2.new(0.5, 4, 0, 64), UDim2.new(0.5, -16, 0, 26)
	local stateLabel = text(self.root, "State", 14)
	stateLabel.Position, stateLabel.Size = UDim2.fromOffset(12, 102), UDim2.fromOffset(45, 28)
	self.name = make("TextBox", self.root, {
		Position = UDim2.fromOffset(60, 102), Size = UDim2.new(1, -72, 0, 28),
		Text = "", PlaceholderText = "Shop, inventory, dialogue…", ClearTextOnFocus = false,
		TextSize = 14, Font = Enum.Font.SourceSans, TextXAlignment = Enum.TextXAlignment.Left,
		BorderSizePixel = 0, TextTruncate = Enum.TextTruncate.AtEnd,
	}, "input")
	round(self.name)
	make("UIPadding", self.name, { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) })
	self.deviceLabel = text(self.root, "Devices · choose up to 6", 14, "muted")
	self.deviceLabel.Position, self.deviceLabel.Size = UDim2.fromOffset(12, 139), UDim2.new(1, -112, 0, 24)
	self.refresh = button(self.root, "Refresh", callbacks.refresh)
	self.refresh.Position, self.refresh.Size = UDim2.new(1, -92, 0, 138), UDim2.fromOffset(80, 24)
	self.devices = scroll(self.root, UDim2.fromOffset(12, 170), UDim2.new(1, -24, 0, 104))
	self.capture = button(self.root, "Capture selected", function() callbacks.capture(self.name.Text) end, true)
	self.capture.Position, self.capture.Size = UDim2.fromOffset(12, 284), UDim2.new(0.5, -16, 0, 30)
	self.cancel = button(self.root, "Cancel", callbacks.cancel)
	self.cancel.Position, self.cancel.Size = UDim2.new(0.5, 4, 0, 284), UDim2.new(0.5, -16, 0, 30)
	self.status = text(self.root, "Loading device presets…", 13, "muted")
	self.status.Position, self.status.Size = UDim2.fromOffset(12, 322), UDim2.new(1, -24, 0, 42)
	self.status.TextWrapped, self.status.TextTruncate = true, Enum.TextTruncate.None
	self.status.TextYAlignment = Enum.TextYAlignment.Top
	make("Frame", self.root, { Position = UDim2.fromOffset(12, 369), Size = UDim2.new(1, -24, 0, 1), BorderSizePixel = 0 }, "line")
	self.tabs = make("Frame", self.root, { Position = UDim2.fromOffset(12, 380), Size = UDim2.new(1, -24, 0, 28), BackgroundTransparency = 1 })
	self.pin = button(self.root, "Use current as baseline", callbacks.pin)
	self.pin.Position, self.pin.Size = UDim2.fromOffset(12, 415), UDim2.new(1, -130, 0, 26)
	self.remove = button(self.root, "Delete state", callbacks.remove)
	self.remove.Position, self.remove.Size = UDim2.new(1, -110, 0, 415), UDim2.fromOffset(98, 26)
	self.board = scroll(self.root, UDim2.fromOffset(12, 451), UDim2.new(1, -24, 1, -479))
	local footer = text(self.root, "Static layouts · no scripts or safe-area simulation · session only", 12, "muted")
	self.footer = footer
	footer.Position, footer.Size = UDim2.new(0, 12, 1, -23), UDim2.new(1, -24, 0, 18)
	self:setBusy(false, false)
	return self
end

function View:setMode(mode, selectionName)
	self.layoutMode:SetAttribute("Selected", mode == "layout")
	self.screenshotMode:SetAttribute("Selected", mode == "screenshot")
	Theme.paint(self.layoutMode)
	Theme.paint(self.screenshotMode)
	self.hint.Text = if mode == "layout" then (if selectionName then "Selected: " .. selectionName else "Select a ScreenGui or root GUI object in Explorer.")
		else "Capture the visible game UI after opening its state."
	self.capture.Text = if mode == "layout" then "Snapshot selected UI" else "Capture screenshots"
	self.footer.Text = if mode == "layout" then "Static layouts · no scripts or safe-area simulation · session only"
		else "Experimental screenshots · requires Studio support and permission"
end

function View:setStatus(message, isError)
	self.status.Text = message
	self.status:SetAttribute("VBRole", if isError then "error" else "muted")
	Theme.paint(self.status)
end

function View:setBusy(busy, available)
	self.busy = busy
	self.available = available
	enabled(self.capture, available and not busy)
	enabled(self.cancel, busy and available)
	enabled(self.refresh, not busy)
	enabled(self.layoutMode, not busy)
	enabled(self.screenshotMode, not busy)
	self.name.TextEditable = not busy
	for _, object in self.deviceButtons do enabled(object, not busy and not object:GetAttribute("Locked")) end
	enabled(self.pin, not busy and self.hasCurrent == true)
	enabled(self.remove, not busy and self.hasState == true)
	for _, object in self.tabs:GetChildren() do
		if object:IsA("TextButton") then enabled(object, not busy) end
	end
end

function View:setDevices(devices, selected)
	clear(self.devices)
	table.clear(self.deviceButtons)
	local count = 0
	for _, device in devices do if selected[device.id] then count += 1 end end
	self.deviceLabel.Text = string.format("Devices · %d of 6 selected", count)
	for index, device in devices do
		local row = make("Frame", self.devices, { Size = UDim2.new(1, 0, 0, 28), BackgroundTransparency = 1, LayoutOrder = index })
		local choose = button(row, (if selected[device.id] then "✓  " else "+  ") .. device.name, function() self.callbacks.toggle(device.id) end)
		choose.TextXAlignment = Enum.TextXAlignment.Left
		make("UIPadding", choose, { PaddingLeft = UDim.new(0, 8) })
		choose.Size = UDim2.new(1, -98, 1, 0)
		choose:SetAttribute("Selected", selected[device.id] == true)
		Theme.paint(choose)
		local orientation = button(row, if device.portrait then "Portrait" else "Landscape", function() self.callbacks.rotate(device.id) end)
		orientation.Position, orientation.Size = UDim2.new(1, -92, 0, 0), UDim2.fromOffset(92, 28)
		orientation:SetAttribute("Locked", not device.mobile)
		enabled(orientation, device.mobile)
		table.insert(self.deviceButtons, choose)
		table.insert(self.deviceButtons, orientation)
	end
	if #devices == 0 then
		local label = text(self.devices, "No device presets are available. Use Refresh to retry.", 14, "muted")
		label.Size, label.TextWrapped = UDim2.new(1, 0, 0, 48), true
	end
end

function View:closeZoom()
	if self.zoom then self.zoom:Destroy() self.zoom = nil end
	if self.hidden then
		for _, object in self.hidden do object.Visible = true end
		self.hidden = nil
	end
end

function View:showZoom(capture, label)
	self:closeZoom()
	self.hidden = {}
	for _, object in self.root:GetChildren() do
		if object:IsA("GuiObject") and object.Visible then
			table.insert(self.hidden, object)
			object.Visible = false
		end
	end
	local overlay = make("Frame", self.root, { Size = UDim2.fromScale(1, 1), BorderSizePixel = 0, ZIndex = 20, Active = true }, "surface")
	self.zoom = overlay
	local title = text(overlay, capture.name .. " · " .. label, 17)
	title.Position, title.Size, title.ZIndex = UDim2.fromOffset(12, 12), UDim2.new(1, -102, 0, 26), 21
	local close = button(overlay, "Close", function() self:closeZoom() end)
	close.Position, close.Size, close.ZIndex = UDim2.new(1, -82, 0, 12), UDim2.fromOffset(70, 28), 21
	self:preview(overlay, capture, UDim2.fromOffset(12, 51), UDim2.new(1, -24, 1, -91), 21)
	local description = if capture.kind == "layout" then string.format("Static layout · %s · %d × %d · scripts are not run", capture.orientation, capture.source.X, capture.source.Y)
		else string.format("%s · rendered %d × %d · preview %d × %d", capture.orientation, capture.source.X, capture.source.Y, capture.size.X, capture.size.Y)
	local note = text(overlay, description, 13, "muted")
	note.Position, note.Size, note.ZIndex = UDim2.new(0, 12, 1, -31), UDim2.new(1, -24, 0, 22), 21
end

function View:preview(parent, capture, position, size, zIndex, callback)
	local host = make("Frame", parent, {
		Position = position, Size = size, BorderSizePixel = 0,
		ClipsDescendants = true, ZIndex = zIndex or 1,
	}, "image")
	if capture.kind == "layout" then
		Layout.render(capture, host)
	else
		make("ImageLabel", host, {
			Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
			ImageContent = capture.content, ScaleType = Enum.ScaleType.Fit,
		})
	end
	if callback then
		local hit = make("TextButton", host, {
			Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
			Text = "", ZIndex = 10000, AutoButtonColor = false,
		})
		hit.Activated:Connect(callback)
	end
	return host
end

function View:image(parent, capture, caption, column, count)
	local cell = make("Frame", parent, {
		Position = UDim2.new((column - 1) / count, if column == 1 then 0 else 4, 0, 29),
		Size = UDim2.new(1 / count, if count == 1 then 0 else -4, 1, -29), BackgroundTransparency = 1,
	})
	local title = text(cell, caption .. (if capture then " · " .. capture.time else ""), 13, "muted")
	title.Size = UDim2.new(1, 0, 0, 19)
	if capture then
		self:preview(cell, capture, UDim2.fromOffset(0, 23), UDim2.new(1, 0, 1, -23), 1, function() self:showZoom(capture, caption) end)
	else
		local empty = text(cell, if caption == "Current" then "Capture this state again to compare." else "No matching baseline.", 14, "muted")
		empty.Position, empty.Size = UDim2.fromOffset(0, 23), UDim2.new(1, 0, 1, -23)
		empty.TextWrapped = true
	end
end

function View:renderBoard(board, active)
	self:closeZoom()
	clear(self.tabs)
	clear(self.board)
	for index, name in board.order do
		local tab = button(self.tabs, name, function() self.callbacks.select(name) end)
		tab.Position = UDim2.new((index - 1) / #board.order, 0, 0, 0)
		tab.Size = UDim2.new(1 / #board.order, -4, 1, 0)
		tab:SetAttribute("Selected", active == name)
		Theme.paint(tab)
	end
	local state = board.states[active]
	self.hasState, self.hasCurrent = state ~= nil, state ~= nil and state.current ~= nil
	if state then
		local keys, records = {}, {}
		for _, list in { state.current or {}, state.baseline or {} } do
			for _, item in list do
				if not records[item.key] then table.insert(keys, item.key) records[item.key] = {} end
				records[item.key][if list == state.current then "current" else "baseline"] = item
			end
		end
		for index, key in keys do
			local pair = records[key]
			local item = pair.current or pair.baseline
			local row = make("Frame", self.board, { Size = UDim2.new(1, 0, 0, 310), BackgroundTransparency = 1, LayoutOrder = index })
			local heading = text(row, item.name .. " · " .. item.orientation .. (if item.kind == "layout" then " · layout" else " · screenshot"), 15)
			heading.Font = Enum.Font.SourceSansSemibold
			if state.baseline then
				self:image(row, pair.baseline, "Baseline", 1, 2)
				self:image(row, pair.current, "Current", 2, 2)
			else
				self:image(row, pair.current, "Current", 1, 1)
			end
		end
	else
		local empty = text(self.board, "Your captured states will appear here.\nPin a capture as a baseline, edit your UI, then capture the same state again.", 15, "muted")
		empty.Size, empty.TextWrapped, empty.TextTruncate = UDim2.new(1, 0, 0, 100), true, Enum.TextTruncate.None
	end
	self:setBusy(self.busy, self.available)
end

function View:Destroy()
	self.root:Destroy()
	table.clear(self.deviceButtons)
end

return View
