--!nonstrict

local Native = require(script.Parent.Native)
local Batch = require(script.Parent.Batch)
local Board = require(script.Parent.Board)
local View = require(script.Parent.View)
local Theme = require(script.Parent.Theme)
local Layout = require(script.Parent.Layout)

local App = {}
App.__index = App

function App.start(pluginObject)
	local self = setmetatable({
		plugin = pluginObject, board = Board.new(3), selected = {}, devices = {},
		connections = {}, closed = false, busy = false, mode = "layout",
	}, App)
	local ok, reason = pcall(function() self:initialize() end)
	if not ok then self:Destroy() error(reason, 0) end
	return self
end

function App:initialize()
	local pluginObject = self.plugin
	local info = DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Float, false, false, 560, 800, 400, 640)
	self.widget = pluginObject:CreateDockWidgetPluginGuiAsync("ViewportBoard.v1", info)
	self.widget.Title = "ViewportBoard"
	self.widget.ZIndexBehavior = Enum.ZIndexBehavior.Global
	self.toolbar = pluginObject:CreateToolbar("ViewportBoard")
	self.toggle = self.toolbar:CreateButton("ViewportBoard", "Review UI captures across device presets", "", "ViewportBoard")
	self.toggle.ClickableWhenViewportHidden = true
	self.view = View.new(self.widget, {
		refresh = function() self:refresh() end,
		capture = function(name) self:capture(name) end,
		cancel = function() self:cancel() end,
		toggle = function(id) self:toggleDevice(id) end,
		rotate = function(id) self:rotate(id) end,
		select = function(name) self:select(name) end,
		pin = function() self:pin() end,
		remove = function() self:remove() end,
		mode = function(mode) self:setMode(mode) end,
	})
	table.insert(self.connections, self.toggle.Click:Connect(function() self.widget.Enabled = not self.widget.Enabled end))
	table.insert(self.connections, self.widget:GetPropertyChangedSignal("Enabled"):Connect(function()
		self.toggle:SetActive(self.widget.Enabled)
		if not self.widget.Enabled then self:cancel() end
	end))
	table.insert(self.connections, settings().Studio.ThemeChanged:Connect(function() Theme.apply(self.view.root) end))
	table.insert(self.connections, pluginObject.Unloading:Connect(function() self:Destroy() end))
	table.insert(self.connections, game:GetService("Selection").SelectionChanged:Connect(function() self:updateSelection() end))
	self.toggle:SetActive(self.widget.Enabled)
	self:updateSelection()
	self.view:renderBoard(self.board, nil)
	self:refresh()
end

function App:updateSelection()
	if self.closed then return end
	local selected = game:GetService("Selection"):Get()
	self.view:setMode(self.mode, if #selected == 1 then selected[1].Name else nil)
end

function App:setMode(mode)
	if self.busy then return end
	self.mode = mode
	self:updateSelection()
	self.view:setStatus(if mode == "layout" then "Static property snapshots. Scripts, safe areas and live game rendering are not reproduced."
		else "Experimental. Requires Studio screenshot support and permission; unavailable in some Studio builds.")
end

function App:savePreferences()
	local choices = {}
	for _, device in self.devices do
		if self.selected[device.id] then table.insert(choices, { id = device.id, portrait = device.portrait }) end
	end
	pcall(function() self.plugin:SetSetting("ViewportBoard.devices", choices) end)
end

function App:refresh()
	if self.busy or self.closed then return end
	self.busy = true
	self.view:setBusy(true, false)
	self.view:setStatus("Reading Studio device presets…")
	self.worker = task.defer(function()
		local adapter, unavailable = Native.new()
		local ok, result = pcall(function()
			assert(adapter, unavailable)
			return adapter:devices()
		end)
		self.busy = false
		self.worker = nil
		if self.closed then return end
		if ok then
			self.adapter, self.devices = adapter, result
			local savedOk, preferences = pcall(function() return self.plugin:GetSetting("ViewportBoard.devices") end)
			table.clear(self.selected)
			if savedOk and type(preferences) == "table" then
				for _, choice in preferences do
					if type(choice) == "table" then
						for _, device in self.devices do
							if choice.id == device.id then
								self.selected[device.id] = true
								if device.mobile and type(choice.portrait) == "boolean" then device.portrait = choice.portrait end
							end
						end
					end
				end
			else
				local forms = {}
				for _, device in self.devices do
					if not forms[device.form] and (device.form == "Phone" or device.form == "Tablet" or device.form == "Desktop") then
						self.selected[device.id], forms[device.form] = true, true
					end
				end
			end
			self.view:setDevices(self.devices, self.selected)
			self.view:setStatus("Ready. Select a ScreenGui or root GUI object in Explorer. Snapshots stay in this Studio session.")
		else
			self.adapter = nil
			self.view:setStatus(tostring(result), true)
		end
		self.view:setBusy(false, self.adapter ~= nil and #self.devices > 0)
	end)
end

function App:toggleDevice(id)
	if self.busy then return end
	local count = 0
	for _, value in self.selected do if value then count += 1 end end
	if not self.selected[id] and count >= 6 then
		self.view:setStatus("Choose up to 6 devices per capture.", true)
		return
	end
	self.selected[id] = not self.selected[id]
	self:savePreferences()
	self.view:setDevices(self.devices, self.selected)
end

function App:rotate(id)
	if self.busy then return end
	for _, device in self.devices do
		if device.id == id and device.mobile then device.portrait = not device.portrait end
	end
	self:savePreferences()
	self.view:setDevices(self.devices, self.selected)
end

function App:select(name)
	if self.busy then return end
	self.active = name
	self.view.name.Text = name
	self.view:renderBoard(self.board, name)
end

function App:pin()
	if self.busy or not self.active then return end
	self.view:closeZoom()
	if self.board:pin(self.active) then
		self.view:renderBoard(self.board, self.active)
		self.view:setStatus("Baseline saved. Capture the same named state after editing your UI.")
	end
end

function App:remove()
	if self.busy or not self.active then return end
	self.view:closeZoom()
	self.board:remove(self.active)
	self.active = self.board.order[#self.board.order]
	self.view.name.Text = self.active or ""
	self.view:renderBoard(self.board, self.active)
		self.view:setStatus("State removed and snapshot resources released.")
end

function App:cancel()
	if self.token then
		self.token.cancelled = true
		if not self.closed then self.view:setStatus("Cancelling… cleaning up the capture.") end
	end
end

function App:capture(value)
	if self.busy or self.closed or not self.adapter then return end
	local name, reason = Board.name(value)
	if not name then self.view:setStatus(reason, true) return end
	if not self.board:canAdd(name) then
		self.view:setStatus("This board has 3 states. Delete one or recapture an existing name.", true)
		return
	end
	local choices = {}
	for _, device in self.devices do
		if self.selected[device.id] then table.insert(choices, table.clone(device)) end
	end
	if #choices == 0 or #choices > 6 then
		self.view:setStatus("Select between 1 and 6 devices.", true)
		return
	end
	self.busy = true
	local mode = self.mode
	local adapter = if mode == "layout" then Layout.new() else self.adapter
	self.token = { cancelled = false }
	self.view:setBusy(true, true)
	self.view:setStatus(if mode == "layout" then "Reading selected UI…" else "Requesting screenshot access…")
	self.worker = task.defer(function()
		local captures, failure = Batch.run(adapter, choices, self.token, function(index, total, deviceName)
			if not self.closed then self.view:setStatus(string.format("Capturing %d of %d · %s", index, total, deviceName)) end
		end)
		self.token, self.worker, self.busy = nil, nil, false
		if self.closed then Board.dispose(captures) return end
		if captures then
			self.view:closeZoom()
			self.board:commit(name, captures)
			self.active, self.view.name.Text = name, name
			self.view:renderBoard(self.board, name)
			self.view:setStatus(if mode == "layout" then string.format("Saved %d static layouts. Click a preview to inspect. Source UI is unchanged.", #captures)
				else string.format("Captured %d devices. Original settings restored. Click an image to inspect.", #captures))
		else
			self.view:setStatus(failure, true)
		end
		self.view:setBusy(false, true)
	end)
end

function App:Destroy()
	if self.closed then return end
	self.closed = true
	self:cancel()
	for _, connection in self.connections do connection:Disconnect() end
	table.clear(self.connections)
	if self.view then self.view:Destroy() end
	self.board:Destroy()
	if self.widget then self.widget:Destroy() end
	if self.toolbar then self.toolbar:Destroy() end
	-- A running batch finishes its native call and restores the simulator before exiting.
end

return App
