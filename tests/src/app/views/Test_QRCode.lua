local BaseLayer = require("app.scenes.BaseLayer")

local TestCase = class("Test_ClientCrypt", BaseLayer)

local qrcode = require "qrcode"



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

	dump(qrcode)
	local version,width,data =qrcode.encode("test",1)
	print(version,width,#data)
end


return TestCase
