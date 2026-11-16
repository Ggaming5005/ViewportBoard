--!strict

local Batch = {}

type Capture = { Destroy: (any) -> () }
type Token = { cancelled: boolean }
type Device = { id: string, name: string }
type Adapter = {
	requestPermission: (any) -> (), snapshot: (any) -> any,
	select: (any, Device) -> (), settle: (any, Token) -> (),
	capture: (any, Device, Token) -> Capture, restore: (any, any) -> { string },
}

function Batch.run(adapter: Adapter, devices: { Device }, token: Token, progress: (number, number, string) -> ()): ({ Capture }?, string?)
	local captures: { Capture } = {}
	local snapshot: any = nil
	local function check()
		if token.cancelled then
			error("Capture cancelled.", 0)
		end
	end
	local ok, failure = pcall(function()
		check()
		adapter:requestPermission()
		check()
		snapshot = adapter:snapshot()
		for index, device in devices do
			check()
			progress(index, #devices, device.name)
			adapter:select(device)
			check()
			adapter:settle(token)
			check()
			table.insert(captures, adapter:capture(device, token))
		end
		check()
	end)
	local restoration: { string } = {}
	if snapshot then
		local restored, result = pcall(function()
			return adapter:restore(snapshot)
		end)
		if restored then
			restoration = result
		else
			table.insert(restoration, tostring(result))
		end
	end
	if token.cancelled then
		ok, failure = false, "Capture cancelled."
	end
	if #restoration > 0 then
		ok = false
		failure = "Could not fully restore the simulator: " .. table.concat(restoration, "; ")
	end
	if not ok then
		for _, capture in captures do
			capture:Destroy()
		end
		return nil, tostring(failure)
	end
	return captures, nil
end

return Batch
