---@diagnostic disable: undefined-global, lowercase-global

-- Hyper (caps) + left click => cmd + click
--
-- Karabiner no puede manipular los botones del trackpad interno de Apple:
-- el pointing device está oculto como "unsafe device" y habilitarlo degrada
-- multitouch, gestos y force click. Aquí el remapeo se hace a nivel de
-- CGEvent, donde funciona con cualquier trackpad o mouse.
--
-- Shift izquierdo + click / arrastre => cmd + click / arrastre
--
-- Workaround para el touchpad del Clevetura CLVX, que se apaga mientras se
-- mantiene una tecla no-modificadora: a nivel HID caps y tab son teclas
-- normales, así que con hyper abajo no se puede mover el cursor. Los
-- modificadores reales sí lo dejan vivo (medido: 97 ev/s con shift abajo
-- contra 0 con caps), y de ahí sale este atajo.
--
-- Clevetura confirmó en sep 2026 que es intencional y que no hay forma de
-- desactivarlo; queda como posible ajuste de firmware futuro, sin ETA. O sea
-- que esto no es un parche a la espera de un arreglo: es la solución, y es
-- estable, porque la exención de los modificadores es parte de su diseño.
--
-- Se ata al shift izquierdo a propósito: el derecho conserva shift + click
-- para extender selección. Para usar cualquiera de los dos, cambiar la
-- condición de leftShiftDown por flags.shift en el segundo eventtap.

local types = hs.eventtap.event.types
local LEFT_SHIFT = 56 -- keycode, el derecho es 60

local leftShiftDown = false

-- globales a propósito: si fueran locales, el garbage collector mata el eventtap
shiftWatcher = hs.eventtap.new({ types.flagsChanged }, function(event)
	if event:getKeyCode() == LEFT_SHIFT then
		leftShiftDown = event:getFlags().shift == true
	end
	return false
end)

hyperClick = hs.eventtap.new({
	types.leftMouseDown,
	types.leftMouseUp,
	types.leftMouseDragged,
}, function(event)
	local flags = event:getFlags()
	if flags.cmd and flags.ctrl and flags.alt and flags.shift then
		event:setFlags({ cmd = true })
	elseif leftShiftDown and flags.shift then
		-- el flags.shift extra evita que un estado pegado convierta clics sueltos
		event:setFlags({ cmd = true })
	end
	return false
end)

shiftWatcher:start()
hyperClick:start()
