--!nonstrict

return function(modules, host)
	local Layout = require(modules.Layout)
	local selection = game:GetService("Selection")
	local before = selection:Get()
	local owned = Instance.new("Folder")
	owned.Name = "ViewportBoardSpec"
	owned.Parent = game:GetService("ServerStorage")
	local captures, previews, passed = {}, {}, {}
	local device = { id = "test", name = "Test phone", width = 874, height = 402, portrait = true }
	local function check(name, run)
		run()
		table.insert(passed, name)
	end
	local function snapshot(source)
		selection:Set({ source })
		local adapter = Layout.new()
		local saved = adapter:snapshot()
		local capture = adapter:capture(device, { cancelled = false })
		adapter:restore(saved)
		table.insert(captures, capture)
		return capture
	end
	local function preview(capture)
		local result = Layout.render(capture, host)
		table.insert(previews, result)
		return result
	end
	local ok, reason = pcall(function()
		local screen = Instance.new("ScreenGui")
		screen.Parent = owned
		local page = Instance.new("Frame")
		page.Name, page.Size, page.Parent = "Page", UDim2.fromScale(1, 1), screen
		local inner = Instance.new("Frame")
		inner.Name, inner.ZIndex, inner.Parent = "HighChild", 5, page
		local peer = Instance.new("Frame")
		peer.Name, peer.ZIndex, peer.Parent = "Peer", 2, screen
		local scriptObject = Instance.new("LocalScript")
		scriptObject.Parent = page
		local sound = Instance.new("Sound")
		sound.Parent = page
		local output = Instance.new("AudioDeviceOutput")
		output.Parent = page
		local wire = Instance.new("Wire")
		wire.Parent = page
		local video = Instance.new("VideoFrame")
		video.Name, video.Volume, video.Playing, video.Parent = "Video", 1, true, page
		local drag = Instance.new("UIDragDetector")
		drag.Parent = page
		local global = snapshot(screen)
		check("snapshot strips scripts and audio, pauses videos and drag input", function()
			assert(not global.tree:FindFirstChildWhichIsA("LuaSourceContainer", true))
			assert(not global.tree:FindFirstChildWhichIsA("Sound", true))
			assert(not global.tree:FindFirstChildWhichIsA("AudioDeviceOutput", true))
			assert(not global.tree:FindFirstChildWhichIsA("Wire", true))
			assert(not global.tree.Page.Video.Playing and global.tree.Page.Video.Volume == 0)
			assert(not global.tree.Page:FindFirstChildWhichIsA("UIDragDetector").Enabled)
		end)
		check("Global draw order preserves descendants above peer branches", function()
			local rendered = preview(global)
			assert(rendered.Page.HighChild.ZIndex > rendered.Peer.ZIndex)
		end)
		check("Sibling draw order preserves complete parent branches", function()
			screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
			local rendered = preview(snapshot(screen))
			assert(rendered.Page.HighChild.ZIndex < rendered.Peer.ZIndex)
		end)
		check("disabled ScreenGui remains disabled", function()
			screen.Enabled = false
			assert(not preview(snapshot(screen)).Visible)
			screen.Enabled = true
		end)
		check("snapshot remains independent from later source edits", function()
			local original = global.tree.Page.BackgroundColor3
			page.BackgroundColor3 = Color3.fromRGB(12, 34, 56)
			assert(global.tree.Page.BackgroundColor3 == original)
		end)
		check("viewport cameras and ObjectValues do not retain live source references", function()
			local original = Instance.new("Camera")
			original.CFrame = CFrame.new(1, 2, 3)
			original.Parent = owned
			local viewport = Instance.new("ViewportFrame")
			viewport.Name, viewport.CurrentCamera, viewport.Parent = "Viewport", original, page
			local reference = Instance.new("ObjectValue")
			reference.Value, reference.Parent = original, viewport
			local saved = snapshot(screen)
			local camera = saved.tree.Page.Viewport.CurrentCamera
			assert(camera ~= original and camera:IsDescendantOf(saved.tree))
			assert(not saved.tree:FindFirstChildWhichIsA("ObjectValue", true))
			original.CFrame = CFrame.new(90, 90, 90)
			assert(camera.CFrame == CFrame.new(1, 2, 3))
			local rendered = preview(saved)
			assert(rendered.Page.Viewport.CurrentCamera:IsDescendantOf(rendered))
		end)
		check("virtual canvas scales proportionally to its host", function()
			local rendered = preview(global)
			task.wait()
			local fit = math.min(host.AbsoluteSize.X / 402, host.AbsoluteSize.Y / 874)
			assert(math.abs(rendered.Page.AbsoluteSize.X - 402 * fit) <= 1)
			assert(math.abs(rendered.Page.AbsoluteSize.Y - 874 * fit) <= 1)
		end)
		check("a selected TextBox root is not editable", function()
			local textbox = Instance.new("TextBox")
			textbox.Parent = owned
			assert(not snapshot(textbox).tree.TextEditable)
		end)
		check("non-archivable descendants fail without changing the source", function()
			inner.Archivable = false
			local success = pcall(function() snapshot(screen) end)
			assert(not success and not inner.Archivable)
			inner.Archivable = true
		end)
		check("instance cap rejects an oversized source", function()
			local large = Instance.new("Frame")
			large.Parent = owned
			for _ = 1, Layout.MAX_INSTANCES do Instance.new("Frame").Parent = large end
			assert(not pcall(function() snapshot(large) end))
		end)
	end)
	for _, item in previews do item:Destroy() end
	for _, item in captures do item:Destroy() end
	owned:Destroy()
	selection:Set(before)
	assert(ok, reason)
	return passed
end
