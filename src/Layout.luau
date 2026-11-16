--!nonstrict

local Layout = {}
Layout.__index = Layout
Layout.MAX_INSTANCES = 800

local function cloneTree(source)
	local clone = source:Clone()
	assert(clone, "The selected UI could not be cloned.")
	local cameras = {}
	local function pair(original, copy)
		if original:IsA("ViewportFrame") and original.CurrentCamera then
			table.insert(cameras, { viewport = copy, camera = original.CurrentCamera })
		end
		local children, index = copy:GetChildren(), 0
		for _, child in original:GetChildren() do
			if child.Archivable then
				index += 1
				pair(child, children[index])
			end
		end
	end
	local ok, reason = pcall(function()
		pair(source, clone)
		for _, object in clone:GetDescendants() do
			if object:IsA("Camera") and object:GetAttribute("ViewportBoardOwned") then object:Destroy() end
		end
		for _, item in cameras do
			local original, camera = item.camera, Instance.new("Camera")
			camera.Name = "ViewportBoardCamera"
			camera:SetAttribute("ViewportBoardOwned", true)
			camera.CFrame, camera.Focus = original.CFrame, original.Focus
			camera.FieldOfViewMode = original.FieldOfViewMode
			if original.FieldOfViewMode == Enum.FieldOfViewMode.Diagonal then
				camera.DiagonalFieldOfView = original.DiagonalFieldOfView
			elseif original.FieldOfViewMode == Enum.FieldOfViewMode.MaxAxis then
				camera.MaxAxisFieldOfView = original.MaxAxisFieldOfView
			else
				camera.FieldOfView = original.FieldOfView
			end
			camera.Parent = item.viewport
			item.viewport.CurrentCamera = camera
		end
	end)
	if not ok then clone:Destroy() error(reason, 0) end
	return clone
end

function Layout.new()
	return setmetatable({}, Layout)
end

function Layout:requestPermission() end

function Layout:snapshot()
	local selected = game:GetService("Selection"):Get()
	assert(#selected == 1, "Select one ScreenGui or root GUI object in Explorer.")
	local source = selected[1]
	assert(source:IsA("ScreenGui") or source:IsA("GuiObject"), "Select a ScreenGui or root GUI object in Explorer.")
	local screen = if source:IsA("ScreenGui") then source else source:FindFirstAncestorWhichIsA("LayerCollector")
	assert(source.Archivable, "The selected UI must have Archivable enabled.")
	local descendants = source:GetDescendants()
	assert(#descendants + 1 <= Layout.MAX_INSTANCES, "Select a smaller UI section: layout snapshots support up to 800 instances.")
	for _, object in descendants do
		assert(object.Archivable or object:IsA("LuaSourceContainer"), "A UI descendant has Archivable disabled. Enable it or select a different section.")
	end
	local clone = cloneTree(source)
	local ok, reason = pcall(function()
		local objects = clone:GetDescendants()
		table.insert(objects, clone)
		for _, object in objects do
			if object:IsA("LuaSourceContainer") or object:IsA("ObjectValue") or object:IsA("Sound") or object:IsA("Wire") or string.sub(object.ClassName, 1, 5) == "Audio" then
				object:Destroy()
			elseif object:IsA("UIDragDetector") then
				object.Enabled = false
			elseif object:IsA("GuiObject") then
				object.Active = false
				object.Selectable = false
				if object:IsA("GuiButton") then object.AutoButtonColor = false end
				if object:IsA("TextBox") then object.TextEditable = false end
				if object:IsA("ScrollingFrame") then object.ScrollingEnabled = false end
				if object:IsA("VideoFrame") then object.Playing = false object.Volume = 0 end
			end
		end
	end)
	if not ok then clone:Destroy() error(reason, 0) end
	self.template = clone
	self.layering = if screen then screen.ZIndexBehavior else Enum.ZIndexBehavior.Sibling
	return clone
end

function Layout:select(_device) end
function Layout:settle(_token) task.wait() end

function Layout:restore(template)
	template:Destroy()
	self.template = nil
	self.layering = nil
	return {}
end

function Layout:capture(device, token)
	assert(not token.cancelled, "Capture cancelled.")
	local width, height = math.max(device.width, device.height), math.min(device.width, device.height)
	if device.portrait then width, height = height, width end
	local tree = cloneTree(self.template)
	local capture = {
		kind = "layout", key = "layout/" .. device.id .. "/" .. (if device.portrait then "portrait" else "landscape"),
		name = device.name, orientation = if device.portrait then "Portrait" else "Landscape",
		source = Vector2.new(width, height), size = Vector2.new(width, height),
		tree = tree, time = os.date("%H:%M:%S"),
		enabled = not tree:IsA("ScreenGui") or tree.Enabled,
		layering = self.layering,
	}
	function capture:Destroy()
		if self.tree then self.tree:Destroy() self.tree = nil end
	end
	return capture
end

function Layout.render(capture, host)
	local viewport = Instance.new("Frame")
	viewport.Name = "LayoutViewport"
	viewport.AnchorPoint = Vector2.new(0.5, 0.5)
	viewport.Position = UDim2.fromScale(0.5, 0.5)
	viewport.Size = UDim2.fromOffset(capture.source.X, capture.source.Y)
	viewport.BorderSizePixel = 0
	viewport.BackgroundTransparency = 1
	viewport.ClipsDescendants = true
	viewport.Visible = capture.enabled
	local scale = Instance.new("UIScale")
	scale.Parent = viewport
	local tree = cloneTree(capture.tree)
	local objects = {}
	if capture.layering == Enum.ZIndexBehavior.Global then
		for _, object in tree:GetDescendants() do
			if object:IsA("GuiObject") then table.insert(objects, object) end
		end
		if tree:IsA("GuiObject") then table.insert(objects, 1, tree) end
		local order = {}
		for index, object in objects do order[object] = index end
		table.sort(objects, function(a, b)
			return if a.ZIndex == b.ZIndex then order[a] < order[b] else a.ZIndex < b.ZIndex
		end)
	else
		local function visit(object)
			if object:IsA("GuiObject") then table.insert(objects, object) end
			local children, order = object:GetChildren(), {}
			for index, child in children do order[child] = index end
			table.sort(children, function(a, b)
				local za, zb = if a:IsA("GuiObject") then a.ZIndex else 0, if b:IsA("GuiObject") then b.ZIndex else 0
				return if za == zb then order[a] < order[b] else za < zb
			end)
			for _, child in children do visit(child) end
		end
		visit(tree)
	end
	for index, object in objects do object.ZIndex = host.ZIndex + 1 + index end
	if tree:IsA("ScreenGui") then
		for _, child in tree:GetChildren() do child.Parent = viewport end
		tree:Destroy()
	else
		tree.Parent = viewport
	end
	local function resize()
		local size = host.AbsoluteSize
		scale.Scale = math.max(0.001, math.min(size.X / capture.source.X, size.Y / capture.source.Y))
	end
	local connection = host:GetPropertyChangedSignal("AbsoluteSize"):Connect(resize)
	viewport.Destroying:Once(function() connection:Disconnect() end)
	viewport.Parent = host
	resize()
	return viewport
end

return Layout
