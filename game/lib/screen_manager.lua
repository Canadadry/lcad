local Manager = {}
Manager.__index = Manager

function Manager:emit(event, ...)
	local scene = self._scenes[#self._scenes]
	if scene[event] then scene[event](scene, ...) end
end

function Manager:enter(next, ...)
	local previous = self._scenes[#self._scenes]
	self:emit('leave', next, ...)
	self._scenes[#self._scenes] = next
	self:emit('enter', previous, ...)
end

function Manager:push(next, ...)
	local previous = self._scenes[#self._scenes]
	self:emit('pause', next, ...)
	self._scenes[#self._scenes + 1] = next
	self:emit('enter', previous, ...)
end

function Manager:pop(...)
	local previous = self._scenes[#self._scenes]
	local next = self._scenes[#self._scenes - 1]
	self:emit('leave', next, ...)
	self._scenes[#self._scenes] = nil
	self:emit('resume', previous, ...)
end

local M={}
function M.new()
	return setmetatable({
		_scenes = {{}},
	}, Manager)
end

return M
