local Board = require("../src/Board")
local Batch = require("../src/Batch")
local Native = require("../src/Native")

local passed = 0
local function test(name, fn)
	local ok, reason = pcall(fn)
	if not ok then error(name .. ": " .. tostring(reason), 0) end
	passed += 1
	print("PASS " .. name)
end

local function capture()
	local image = { disposed = 0 }
	function image:Destroy() self.disposed += 1 end
	return image
end

local function adapter(fault)
	local fake = { selected = {}, images = {}, restored = 0, mutations = 0 }
	function fake:requestPermission()
		if fault == "permission" then error("denied") end
	end
	function fake:snapshot()
		if fault == "snapshot" then error("unsupported getter") end
		return { device = "original", resolution = "custom", orientation = "portrait", density = 200, scaling = "physical" }
	end
	function fake:select(device)
		self.mutations += 1
		table.insert(self.selected, device.id)
		if fault == "select" then error("device unavailable") end
	end
	function fake:settle(token)
		if fault == "cancel" then token.cancelled = true end
		if fault == "settle" then error("viewport unstable") end
	end
	function fake:capture()
		if fault == "capture" and #self.images == 1 then error("capture failed") end
		local image = capture()
		table.insert(self.images, image)
		return image
	end
	function fake:restore(saved)
		self.restored += 1
		self.saved = saved
		if fault == "restore" then return { "density failed" } end
		if fault == "restore-throw" then error("restore crashed") end
		return {}
	end
	return fake
end

local devices = { { id = "a", name = "Phone" }, { id = "b", name = "Desktop" } }
local function run(fake, token, progress)
	return Batch.run(fake, devices, token or { cancelled = false }, progress or function() end)
end

test("a successful batch restores all snapshot fields before returning images", function()
	local fake = adapter()
	local images = run(fake)
	assert(#images == 2 and fake.restored == 1)
	assert(fake.saved.device == "original" and fake.saved.resolution == "custom")
	assert(fake.saved.orientation == "portrait" and fake.saved.density == 200 and fake.saved.scaling == "physical")
	assert(images[1].disposed == 0)
end)

for _, fault in { "permission", "snapshot" } do
	test(fault .. " errors never mutate the simulator", function()
		local fake = adapter(fault)
		local images, failure = run(fake)
		assert(images == nil and failure and fake.mutations == 0 and fake.restored == 0)
	end)
end

for _, fault in { "select", "settle", "capture", "cancel", "restore", "restore-throw" } do
	test(fault .. " cannot leak partial results or skip restoration", function()
		local fake = adapter(fault)
		local images, failure = run(fake)
		assert(images == nil and failure and fake.restored == 1)
		for _, image in fake.images do assert(image.disposed == 1) end
	end)
end

test("cancellation before start never requests a snapshot or mutation", function()
	local fake = adapter()
	local images = run(fake, { cancelled = true })
	assert(images == nil and fake.mutations == 0 and fake.restored == 0)
end)

test("progress callback failure still restores", function()
	local fake = adapter()
	local images = run(fake, nil, function() error("view gone") end)
	assert(images == nil and fake.restored == 1 and fake.mutations == 0)
end)

test("cancellation during restoration disposes completed results", function()
	local fake, token = adapter(), { cancelled = false }
	local restore = fake.restore
	function fake:restore(saved) token.cancelled = true return restore(self, saved) end
	assert(run(fake, token) == nil)
	for _, image in fake.images do assert(image.disposed == 1) end
end)

test("state replacement, baseline transfer and deletion dispose each image once", function()
	local board = Board.new()
	local a, b, c = capture(), capture(), capture()
	board:commit("Shop", { a })
	board:pin("Shop")
	assert(a.disposed == 0 and board.states.Shop.current == nil)
	board:commit("Shop", { b })
	board:commit("Shop", { c })
	assert(a.disposed == 0 and b.disposed == 1)
	board:pin("Shop")
	assert(a.disposed == 1 and c.disposed == 0)
	board:remove("Shop")
	board:Destroy()
	assert(a.disposed == 1 and b.disposed == 1 and c.disposed == 1)
end)

test("capacity blocks new states but permits replacing existing states", function()
	local board = Board.new(2)
	board:commit("A", {}) board:commit("B", {})
	assert(board:canAdd("A") and not board:canAdd("C"))
	board:remove("A")
	assert(board:canAdd("C") and #board.order == 1)
end)

test("invalid names are rejected and surrounding spaces are trimmed", function()
	assert(Board.name("   ") == nil and Board.name(string.rep("x", 41)) == nil)
	assert(Board.name("Shop\nMenu") == nil and Board.name("  Shop  ") == "Shop")
	assert(Board.name(string.rep("界", 40)) ~= nil)
end)

test("native restoration restores overrides cleared by switching devices", function()
	local values = { device = "phone", orientation = "portrait", resolution = { X = 2400, Y = 1080 }, density = 420, scaling = "physical" }
	local simulator = {}
	function simulator:GetDeviceAsync() return values.device end
	function simulator:GetOrientationAsync() return values.orientation end
	function simulator:GetResolutionAsync() return values.resolution end
	function simulator:GetPixelDensityAsync() return values.density end
	function simulator:GetScalingModeAsync() return values.scaling end
	function simulator:SetDeviceAsync(id) values.device = id values.resolution = nil values.density = nil end
	function simulator:SetOrientationAsync(value) values.orientation = value end
	function simulator:SetResolutionAsync(x, y) values.resolution = { X = x, Y = y } end
	function simulator:SetPixelDensityAsync(value) values.density = value end
	function simulator:SetScalingModeAsync(value) values.scaling = value end
	local native = setmetatable({ simulator = simulator, mobileId = "phone", mobileIds = { phone = true } }, Native)
	local saved = native:snapshot()
	simulator:SetDeviceAsync("desktop")
	values.orientation, values.scaling = "landscape", "fit"
	assert(#native:restore(saved) == 0)
	assert(values.device == "phone" and values.orientation == "portrait")
	assert(values.resolution.X == 2400 and values.resolution.Y == 1080)
	assert(values.density == 420 and values.scaling == "physical")
end)

test("native default-mode restoration does not call active-device-only getters", function()
	local stopped, orientation, device = false, "portrait", "default"
	local simulator = {}
	function simulator:GetDeviceAsync() return device end
	function simulator:GetOrientationAsync() return orientation end
	function simulator:SetDeviceAsync(value) device = value end
	function simulator:SetOrientationAsync(value) assert(device == "phone", "not a mobile device") orientation = value end
	function simulator:StopSimulationAsync() stopped = true device = "default" end
	local native = setmetatable({ simulator = simulator, mobileId = "phone" }, Native)
	local saved = native:snapshot()
	orientation = "landscape"
	device = "desktop"
	assert(#native:restore(saved) == 0 and stopped and orientation == "portrait" and device == "default")
end)

test("native restoration attempts remaining fields after one setter fails", function()
	local density, scaling = false, false
	local simulator = {}
	function simulator:SetDeviceAsync() end
	function simulator:SetOrientationAsync() error("orientation unavailable") end
	function simulator:SetResolutionAsync() end
	function simulator:SetPixelDensityAsync() density = true end
	function simulator:SetScalingModeAsync() scaling = true end
	local native = setmetatable({ simulator = simulator }, Native)
	local failures = native:restore({ device = "phone", orientationDevice = "phone", resolution = { X = 1, Y = 1 } })
	assert(#failures == 1 and density and scaling)
end)

test("default-mode scaling is saved after first activation and restored before stopping", function()
	local values = { device = "default", orientation = "landscape", scaling = "physical" }
	local simulator = {}
	function simulator:GetDeviceAsync() return values.device end
	function simulator:GetOrientationAsync() return values.orientation end
	function simulator:GetScalingModeAsync() assert(values.device ~= "default") return values.scaling end
	function simulator:SetScalingModeAsync(value) assert(values.device ~= "default") values.scaling = value end
	function simulator:SetDeviceAsync(value) values.device = value end
	function simulator:SetOrientationAsync(value) assert(values.device == "phone") values.orientation = value end
	function simulator:StopSimulationAsync() values.device = "default" end
	local native = setmetatable({ simulator = simulator, mobileId = "phone", fitMode = "fit" }, Native)
	local saved = native:snapshot()
	assert(saved.scaling == nil)
	native:select({ id = "desktop", mobile = false })
	assert(saved.scaling == "physical" and values.scaling == "fit")
	assert(#native:restore(saved) == 0)
	assert(values.device == "default" and values.scaling == "physical" and native.saved == nil)
end)

print(string.format("%d tests passed", passed))
