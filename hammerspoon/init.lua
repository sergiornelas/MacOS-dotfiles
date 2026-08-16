---@diagnostic disable: undefined-global, lowercase-global

-- Hyper (caps) + left click => cmd + click
--
-- Karabiner no puede manipular los botones del trackpad interno de Apple:
-- el pointing device está oculto como "unsafe device" y habilitarlo degrada
-- multitouch, gestos y force click. Aquí el remapeo se hace a nivel de
-- CGEvent, donde funciona con cualquier trackpad o mouse.

local mouseEvents = {
	hs.eventtap.event.types.leftMouseDown,
	hs.eventtap.event.types.leftMouseUp,
	hs.eventtap.event.types.leftMouseDragged,
}

-- global a propósito: si fuera local, el garbage collector mata el eventtap
hyperClick = hs.eventtap.new(mouseEvents, function(event)
	local flags = event:getFlags()
	if flags.cmd and flags.ctrl and flags.alt and flags.shift then
		event:setFlags({ cmd = true })
	end
	return false
end)

hyperClick:start()
