local moduleName = ...
local M = {}
_G[moduleName] = M

-- DC Display Control
local DC_ON         = 0x88  -- Display on, light (0x88 & 0) to (0x88 & 7)
local DC_OFF        = 0x80  -- Display off

-- SAC Set Address Command
local SAC_DIGIT1    = 0xC0  -- Digit 1 = 0xC0 ( rightmost), Digit 2 = 0xC1 , ... , Digit 6=0xC5 (leftmost)

-- DCS Data Command Set
local DCS_WRITE     = 0x40  -- Write data to display's register / Automatic address adding / Normal mode
local DCS_FIX       = 0x44  -- Fix address
-- local DCS_READ   = 0x42  -- Read data from display's register
-- local DCS_TEST   = 0x48  -- Test mode

local dio = 1
local clk = 2
local DELAY=5
local LIGHT = 1
local TWODOTS = 0

local digits ={
	['0'] = 0x3f,
	['1'] = 0x06,
	['2'] = 0x5b,
	['3'] = 0x4f,
	['4'] = 0x66,
	['5'] = 0x6d,
	['6'] = 0x7d,
	['7'] = 0x07,
	['8'] = 0x7f,
	['9'] = 0x6f,
	['A'] = 0x77,
	['B'] = 0x7c,
	['C'] = 0x39,
	['D'] = 0x5e,
	['E'] = 0x79,
	['F'] = 0x71
}

local function start()
	gpio.mode(clk, gpio.INPUT)
	gpio.mode(dio, gpio.INPUT)
	tmr.delay(DELAY)
	gpio.mode(clk, gpio.OUTPUT)
	gpio.mode(dio, gpio.OUTPUT)
	gpio.write(dio, gpio.LOW)
	gpio.write(clk, gpio.LOW) --need it?
	tmr.delay(DELAY)
end

local function stop()
	gpio.mode(clk, gpio.OUTPUT)
	gpio.mode(dio, gpio.OUTPUT)
	gpio.write(dio, gpio.LOW)
	gpio.write(clk, gpio.LOW)
	tmr.delay(DELAY)
	gpio.mode(clk, gpio.INPUT)
	gpio.mode(dio, gpio.INPUT)
	tmr.delay(DELAY)
end

local function w(b)
	for i=1, 8 do
		-- clk LOW
		gpio.mode(clk, gpio.OUTPUT)
		gpio.write(clk, gpio.LOW)

		if bit.band(b, 1) == 1 then
			gpio.mode(dio, gpio.INPUT)
		else
			gpio.mode(dio, gpio.OUTPUT)
			gpio.write(dio, gpio.LOW)
		end
		tmr.delay(DELAY)
		gpio.mode(clk, gpio.INPUT)
		b = bit.rshift(b,1)
		tmr.delay(DELAY)
	end
	-- response
	gpio.mode(clk, gpio.OUTPUT)
	gpio.write(clk, gpio.LOW)
	gpio.mode(dio, gpio.INPUT)-- Need it?
	tmr.delay(DELAY)
	gpio.mode(clk, gpio.INPUT)
	gpio.mode(dio, gpio.INPUT)
	ack = gpio.read(dio)
--	if ack == 0 then
--		print("Envio correcto de"..b)
--	else
--		print("NO envio de"..b)
 --  end
	tmr.delay(DELAY)
end


function M.dots()
	if TWODOTS == 0 then
		TWODOTS = 1
	else
		TWODOTS = 0
	end
end

function M.clear()
	start()
	w(DCS_WRITE)
	stop()
	start()
	w(SAC_DIGIT1)
	w(0)
	w(0)
	w(0)
	w(0)
	stop()
	start()
	w(DC_ON + bit.band(LIGHT, 0x0F))
	stop()
end

function M.fix(digit, s)
	start()
	w(DCS_FIX)
	stop()
	start()
	w(SAC_DIGIT1 + bit.band(digit-1,0x03))
	w(digits [ string.sub(s,1,1) ])
	stop()
	start()
	w(DC_ON + bit.band(LIGHT, 0x0F))
	stop()
end

function M.write(s)
	start()
	w(DCS_WRITE)
	stop()
	start()
	w(SAC_DIGIT1)
	w(digits [ string.sub(s,1,1) ])
	if TWODOTS == 1 then
		w(bit.bor( digits [ string.sub(s,2,2) ], 0x80))
	else
		w(digits [ string.sub(s,2,2) ])
	end
	w(digits [ string.sub(s,3,3) ])
	w(digits [ string.sub(s,4,4) ])
	stop()
	start()
	w(DC_ON + bit.band(LIGHT, 0x0F))
	stop()
end

function M.setup(clks, dios)
	clk = clks or 2
	dio = dios or 1
end

function M.light(light)
	LIGHT = light or 3
end

function M.off()
	start()
	w(DCS_WRITE)
	stop()
	start()
	w(SAC_DIGIT1)
	w(digits [ '1' ])
	w(digits [ '1' ])
	w(digits [ '1' ])
	w(digits [ '1' ])
	stop()
	start()
	w(DC_OFF + bit.band(LIGHT, 0x0F))
	stop()
end

return M
