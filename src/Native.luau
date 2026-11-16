--!nonstrict

local Native = {}
Native.__index = Native

local function cancelled(token)
	if token.cancelled then
		error("Capture cancelled.", 0)
	end
end

function Native.new()
	local self = setmetatable({}, Native)
	local ok, reason = pcall(function()
		self.simulator = game:GetService("StudioDeviceSimulatorService")
		self.runService = game:GetService("RunService")
		assert(type(self.simulator.GetDeviceListAsync) == "function", "Device Simulator API is unavailable.")
		self.fitMode = Enum.DeviceSimulatorScalingMode.FitToWindow
	end)
	if not ok then
		return nil, "This Studio build does not expose device presets. Update Studio, then Refresh.\n" .. tostring(reason)
	end
	local captureOk, captureReason = pcall(function()
		self.captureService = game:GetService("StudioCaptureService")
		self.assets = game:GetService("AssetService")
		assert(type(self.captureService.CaptureScreenshot) == "function", "Studio screenshot API is unavailable.")
		assert(type(self.assets.CreateEditableImage) == "function", "EditableImage API is unavailable.")
		self.rgba = Enum.StudioCaptureScreenshotFormat.RGBA8
		self.ready = Enum.StudioCaptureBufferStatus.Ready
		self.failed = Enum.StudioCaptureBufferStatus.Error
	end)
	if not captureOk then self.captureUnavailable = tostring(captureReason) end
	return self
end

function Native:devices()
	if self.runService:IsRunning() and self.runService:IsServer() then
		error("Open ViewportBoard in Edit mode or the Play Client, not the server view.", 0)
	end
	local devices = {}
	self.mobileId = nil
	self.mobileIds = {}
	for _, id in self.simulator:GetDeviceListAsync() do
		if id ~= "default" then
			local info = self.simulator:GetDeviceInfoAsync(id)
			local form = if typeof(info.DeviceForm) == "EnumItem" then info.DeviceForm.Name else tostring(info.DeviceForm)
			local mobile = form == "Phone" or form == "Tablet"
			if mobile then
				self.mobileId = self.mobileId or id
				self.mobileIds[id] = true
			end
			table.insert(devices, {
				id = id,
				name = info.Name,
				width = info.Width,
				height = info.Height,
				form = form,
				mobile = mobile,
				portrait = mobile,
			})
		end
	end
	local preferred = { iphone_17_pro = 1, ipad_a16 = 2, hd_1080 = 3 }
	local forms = { Phone = 10, Tablet = 20, Desktop = 30 }
	table.sort(devices, function(a, b)
		local rankA, rankB = preferred[a.id] or forms[a.form] or 40, preferred[b.id] or forms[b.form] or 40
		return if rankA == rankB then a.name < b.name else rankA < rankB
	end)
	return devices
end

function Native:requestPermission()
	assert(not self.captureUnavailable, "Screenshots are unavailable in this Studio build. Use Layout mode.")
	local ok, granted = pcall(function() return self.captureService:RequestScreenshotPermissionAsync() end)
	assert(ok, "Studio could not request screenshot access. Use Layout mode; screenshot support may not be available in this Studio build.")
	assert(granted, "Screenshot access was not granted. Allow it in Studio's plugin permissions, or use Layout mode.")
	assert(self.captureService:CanCaptureScreenshot(), "The active Studio viewport cannot currently be captured.")
end

function Native:snapshot()
	local simulator = self.simulator
	local saved = {
		device = simulator:GetDeviceAsync(),
		orientation = simulator:GetOrientationAsync(),
	}
	saved.orientationDevice = if self.mobileIds and self.mobileIds[saved.device] then saved.device else self.mobileId
	if saved.device ~= "default" then
		saved.resolution = simulator:GetResolutionAsync()
		saved.density = simulator:GetPixelDensityAsync()
		saved.scaling = simulator:GetScalingModeAsync()
	end
	self.saved = saved
	return saved
end

function Native:select(device)
	local simulator = self.simulator
	simulator:SetDeviceAsync(device.id)
	if self.saved and self.saved.scaling == nil then
		self.saved.scaling = simulator:GetScalingModeAsync()
	end
	if device.mobile then
		simulator:SetOrientationAsync(if device.portrait then Enum.ScreenOrientation.Portrait else Enum.ScreenOrientation.LandscapeLeft)
	end
	simulator:SetScalingModeAsync(self.fitMode)
end

function Native:settle(token)
	local deadline = os.clock() + 3
	local previous, stable = nil, 0
	repeat
		cancelled(token)
		task.wait(0.1)
		local camera = workspace.CurrentCamera
		local size = if camera then camera.ViewportSize else Vector2.zero
		stable = if size == previous and size.X > 0 and size.Y > 0 then stable + 1 else 0
		previous = size
	until stable >= 4 or os.clock() >= deadline
	assert(stable >= 4, "The viewport did not settle. Stop resizing Studio and capture again.")
end

function Native:restore(saved)
	local simulator = self.simulator
	local errors = {}
	local function attempt(label, fn)
		local ok, reason = pcall(fn)
		if not ok then
			table.insert(errors, label .. ": " .. tostring(reason))
		end
	end
	if saved.orientationDevice then
		attempt("orientation", function()
			simulator:SetDeviceAsync(saved.orientationDevice)
			simulator:SetOrientationAsync(saved.orientation)
		end)
	end
	if saved.device == "default" then
		if saved.scaling then
			attempt("scaling", function() simulator:SetScalingModeAsync(saved.scaling) end)
		end
		attempt("device", function() simulator:StopSimulationAsync() end)
	else
		attempt("device", function() simulator:SetDeviceAsync(saved.device) end)
		attempt("resolution", function() simulator:SetResolutionAsync(saved.resolution.X, saved.resolution.Y) end)
		attempt("pixel density", function() simulator:SetPixelDensityAsync(saved.density) end)
		attempt("scaling", function() simulator:SetScalingModeAsync(saved.scaling) end)
	end
	self.saved = nil
	return errors
end

function Native:capture(device, token)
	local shot, scaled, editable
	local ok, result = pcall(function()
		shot = self.captureService:CaptureScreenshot({ Format = self.rgba, UICaptureMode = Enum.UICaptureMode.All })
		local deadline = os.clock() + 12
		repeat
			cancelled(token)
			if shot.BufferStatus == self.failed then
				error(table.concat(shot:GetErrors(), "; "), 0)
			end
			if shot.BufferStatus == self.ready then
				break
			end
			task.wait(0.05)
		until os.clock() >= deadline
		assert(shot.BufferStatus == self.ready, "Screenshot timed out.")
		local source = shot.Resolution
		local factor = math.min(1, 512 / math.max(source.X, source.Y))
		local size = Vector2.new(math.max(1, math.floor(source.X * factor)), math.max(1, math.floor(source.Y * factor)))
		scaled = if factor < 1 then shot:ScaleAsync(Enum.ResamplerMode.Default, size) else shot
		cancelled(token)
		editable = self.assets:CreateEditableImage({ Size = size })
		assert(editable, "Studio could not allocate the preview image. Clear older states and try again.")
		editable:WritePixelsBuffer(Vector2.zero, size, scaled:GetBuffer())
		local capture = {
			kind = "screenshot",
			key = "screenshot/" .. device.id .. "/" .. (if device.portrait then "portrait" else "landscape"),
			name = device.name,
			orientation = if device.portrait then "Portrait" else "Landscape",
			size = size,
			source = source,
			image = editable,
			content = Content.fromObject(editable),
			time = os.date("%H:%M:%S"),
		}
		function capture:Destroy()
			if self.image then
				self.image:Destroy()
				self.image = nil
				self.content = nil
			end
		end
		return capture
	end)
	if scaled and scaled ~= shot then scaled:Destroy() end
	if shot then shot:Destroy() end
	if not ok then
		if editable then editable:Destroy() end
		error(result, 0)
	end
	return result
end

return Native
