--!strict

local Board = {}
Board.__index = Board

export type Capture = { Destroy: (any) -> () }
type State = { name: string, current: { Capture }?, baseline: { Capture }? }
type Data = { states: { [string]: State }, order: { string }, limit: number }
export type Board = typeof(setmetatable({} :: Data, Board))

function Board.dispose(captures: { Capture }?)
	for _, capture in captures or {} do
		capture:Destroy()
	end
end

function Board.name(value: string): (string?, string?)
	local name = string.match(value, "^%s*(.-)%s*$") or ""
	if name == "" then
		return nil, "Give this UI state a name."
	end
	local length = utf8.len(name)
	if not length or length > 40 or string.find(name, "[%c]") then
		return nil, "Use a state name of 40 characters or fewer."
	end
	return name, nil
end

function Board.new(limit: number?): Board
	return setmetatable({ states = {}, order = {}, limit = limit or 3 } :: Data, Board)
end

function Board.canAdd(self: Board, name: string): boolean
	return self.states[name] ~= nil or #self.order < self.limit
end

function Board.commit(self: Board, name: string, captures: { Capture }): State
	assert(self:canAdd(name), "Delete a state before adding another.")
	local state = self.states[name]
	if not state then
		state = { name = name } :: State
		self.states[name] = state
		table.insert(self.order, name)
	end
	Board.dispose(state.current)
	state.current = captures
	return state
end

function Board.pin(self: Board, name: string): boolean
	local state = self.states[name]
	if not state or not state.current then
		return false
	end
	Board.dispose(state.baseline)
	state.baseline = state.current
	state.current = nil
	return true
end

function Board.remove(self: Board, name: string)
	local state = self.states[name]
	if not state then
		return
	end
	Board.dispose(state.current)
	Board.dispose(state.baseline)
	self.states[name] = nil
	table.remove(self.order, table.find(self.order, name))
end

function Board.Destroy(self: Board)
	while #self.order > 0 do
		self:remove(self.order[#self.order])
	end
end

return Board
