--------------------------------------------------------
-- Lowers the bit count of a pixels color channels to a specified bit count.
--
-- Developed by Mpdacey 2025
--------------------------------------------------------

local BYTE_DECIMAL <const> = 255.0

function Clamp(x, minVal, maxVal)
	return math.max(math.min(x, maxVal), minVal)
end

-- Crushes a color channel to the nearest specified bit
-- Parameters:
-- - colorValue:       The value of a pixel's color channel
-- - bitValue:         How many bits should be used when determining the crushed color
-- - applyIntensity:   Apply the average intensity of a color using vacant bits.
-- Returns the crushed color value.
function CrushChannel(colorValue, bitValue, applyIntensity)
	if bitValue == 0 then
		return 0
	end

	local purgeBits = 8 - bitValue
	
	-- Purge bits out of bitValue's range
	local purgedColor = colorValue >> purgeBits << purgeBits
	
	-- If intensity is being preserved, re-add purged bits on a linear gradient
	if applyIntensity then
		local intensity = (purgedColor >> purgeBits) / (BYTE_DECIMAL >> purgeBits)
		local gradient = BYTE_DECIMAL % (2^purgeBits) * intensity
		gradient = math.floor(gradient + 0.5)
		purgedColor = purgedColor + gradient
	end
	
	return purgedColor
end

-- Crushes and clamps a given pixel to the nearest specified bit.
-- Parameters:
-- - pc:             The pixel color in app.
-- - pixel:          Selected pixel value.
-- - bits:           Number of bits to constrain the colors to.
-- - applyIntensity: Apply the average intensity of a color using vacant bits.
-- Returns crushed color
function CrushColor(pc, pixel, bits, applyIntensity)
	if pc.rgbaA(pixel) == 0 then
		return pixel
	end

	-- Get channels
	local red = pc.rgbaR(pixel)
	local green = pc.rgbaG(pixel)
	local blue = pc.rgbaB(pixel)
	local alpha = pc.rgbaA(pixel)
	
	red = CrushChannel(red, bits.r, applyIntensity)
	green = CrushChannel(green, bits.g, applyIntensity)
	blue = CrushChannel(blue, bits.b, applyIntensity)
	
	if bits.a >= 0 then
		alpha = CrushChannel(alpha, bits.a, applyIntensity)
	end
	
	local newPixel = pc.rgba(red, green, blue, alpha)
	return newPixel
end

-- Crushes and clamps each pixel to the nearest specified bit.
-- Parameters:
-- - base:           Base image used as reference.
-- - pc:             The pixel color in app.
-- - bits:           Specified bits that an image should be crushed to.
-- - applyIntensity: Apply the average intensity of a color using vacant bits.
function CrushImage(base, pc, bits, applyIntensity)
    local crunched = base:clone()
	
    -- Iterates through each pixel in base
    for y = 0, base.height, 1 do
        for x = 0, base.width, 1 do
			crunched:drawPixel(x, y, CrushColor(pc, base:getPixel(x,y), bits, applyIntensity))
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
    dlg:number{ id="universalBits", label="All channels bits:", text="0", decimals=integer }
    dlg:newrow()
    dlg:number{ id="bitsR", label="Red channel bits:", text="0", decimals=integer, visible = false }
    dlg:newrow()
    dlg:number{ id="bitsG", label="Green channel bits:", text="0", decimals=integer, visible = false }
    dlg:newrow()
    dlg:number{ id="bitsB", label="Blue channel bits:", text="0", decimals=integer, visible = false }
    dlg:newrow()
    dlg:number{ id="bitsA", label="Alpha channel bits:", text="0", decimals=integer, visible = false }
    dlg:newrow()
	dlg:separator{}
	dlg:check{ id="seperateChannels", label="Seperate channels:", selected=false, onclick= 
		function()
			local universalBits = dlg.data.universalBits
		
			dlg:modify{ id="universalBits", visible = not dlg.data.seperateChannels }
			dlg:modify{ id="bitsR", text=universalBits, visible = dlg.data.seperateChannels }
			dlg:modify{ id="bitsG", text=universalBits, visible = dlg.data.seperateChannels }
			dlg:modify{ id="bitsB", text=universalBits, visible = dlg.data.seperateChannels }
			dlg:modify{ id="bitsA", text=universalBits, visible = dlg.data.seperateChannels and dlg.data.includeAlpha }
		end
	}
    dlg:newrow()
	dlg:check{ id="includeAlpha", label="Include alpha channel:", selected=false, onclick=
		function()
			dlg:modify{ id="bitsA", visible = dlg.data.seperateChannels and dlg.data.includeAlpha }
		end
	}
    dlg:newrow()
	dlg:check{ id="apply", label="Apply intensity:", selected=true }
	dlg:newrow()
    dlg:button{ id="confirm", text="Confirm" }
    dlg:button{ id="cancel", text="Cancel" }
    dlg:show()

local data = dlg.data
if data.confirm then
	local bits = {};
	bits.a = -1
	
	-- Set bits for each channel based on checks
	if data.seperateChannels then
		bits.r = Clamp(data.bitsR, 0, 8)
		bits.g = Clamp(data.bitsG, 0, 8)
		bits.b = Clamp(data.bitsB, 0, 8)
		if data.includeAlpha then
			bits.a = Clamp(data.bitsA, 0, 8)
		end
	else
		local universalBits = Clamp(data.universalBits, 0, 8)
		bits.r = universalBits
		bits.g = universalBits
		bits.b = universalBits
		
		if data.includeAlpha then
			bits.a = universalBits
		end
	end
	
	-- Allows undo functionality
    cel.image = CrushImage(base, pc, bits, data.apply)

    -- Redraw pixels in app
    app.refresh()
end