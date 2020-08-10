local BaseLayer = require("app.scenes.BaseLayer")

local TestCase = class("Test_ClientCrypt", BaseLayer)





function TestCase:ctor()
	self.super.ctor(self)

	self:setNodeEventEnabled(true)
	-- tips
	local label = display.newTTFLabel({
		text = "QRCode test see console",
		size = 25,
		color = cc.c3b(255, 255, 255),
	})
	label:align(display.CENTER, display.cx, display.cy + 200)
	self:addChild(label)
	

	self:test()

	
end

function TestCase:test( )

	dump(cc.qrcode)
	require "lfs"

	local qrcodeCache=device.writablePath.."qrcode/"
	if not io.exists(qrcodeCache) then
		lfs.mkdir(qrcodeCache)
	end
	cc.qrcode:encode_write_to_png("test",qrcodeCache.."1.png")
	print(qrcodeCache)
end


return TestCase
