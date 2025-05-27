--------------------------------------------------------
-- Lowers the bit count of a pixels color channels to a specified bit count.
--
-- Developed by Mpdacey 2025
--------------------------------------------------------

local BYTE_DECIMAL <const> = 255.0

function Clamp(x, minVal, maxVal)
	return math.max(math.min(x, maxVal), minVal)
end

function CrushChannel(colorValue, bitValue)
	local purgeBits = 8 - bitValue
	
	-- Shift bits to the right
	colorValue = colorValue >> purgeBits
	
	-- Shift the bits back if they don't match white
	if colorValue == BYTE_DECIMAL >> purgeBits then
		colorValue = BYTE_DECIMAL
	else
		colorValue = colorValue << purgeBits
	end
	
	return colorValue
end

-- Crushes and clamps a given pixel to the nearest specified bit.
-- Parameters:
-- - pc:      The pixel color in app
-- - pixel:   Selected pixel value.
-- - bits:    Number of bits to constrain the colors to.
-- Returns crushed color
function CrushColor(pc, pixel, bits)
	if pc.rgbaA(pixel) == 0 then
		return pixel
	end

	-- Get channels
	local red = pc.rgbaR(pixel)
	local green = pc.rgbaG(pixel)
	local blue = pc.rgbaB(pixel)
	
	red = CrushChannel(red, bits)
	green = CrushChannel(green, bits)
	blue = CrushChannel(blue, bits)
	
	local newPixel = pc.rgba(red, green, blue, pc.rgbaA(pixel))
	return newPixel
end

-- Crushes and clamps each pixel to the nearest specified bit.
-- Parameters:
-- - base:    Base image used as reference
-- - pc:      The pixel color in app
-- - bits:    Specified bits that an image should be crushed to.
function CrushImage(base, pc, bits)
    local crunched = base:clone()
	-- Clamp bits to 
	bits = Clamp(bits, 1, 8)
		
    -- Iterates through each pixel in base
    for y = 0, base.height, 1 do
        for x = 0, base.width, 1 do
			crunched:drawPixel(x, y, CrushColor(pc, base:getPixel(x,y), bits))
        end
    end

    return crunched;
end

local cel = app.activeCel
if not cel then
    return app.alert("There is no active image.")
end

local base = cel.image:clone()
local pc = app.pixelColor

-- Dialog window for inputting variables
local dlg = Dialog("Color Bit Crusher")
    dlg:number{ id="bits", label="How many bits per byte are crushed:", text="", decimals=integer}
    dlg:newrow()
    dlg:button{ id="confirm", text="Confirm" }
    dlg:button{ id="cancel", text="Cancel" }
    dlg:show()

local data = dlg.data
local bits = data.bits
if data.confirm then
	-- Allows undo functionality
    cel.image = CrushImage(base, pc, bits)

    -- Redraw pixels in app
    app.refresh()
end