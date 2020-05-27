local BaseLayer = require("app.scenes.BaseLayer")

local TestCase = class("Test_FairyGUI", BaseLayer)

function TestCase:ctor()
	self.super.ctor(self)

	-- tips
	self.fairyRoot = fairygui.GRoot:create(display.getRunningScene())
    self.fairyRoot:retain()

	fairygui.UIPackage:addPackage("fairygui/login/login");
    local view = fairygui.UIPackage:createObject("login", "layer_login")
	view:setOpaque(false) -- ignore touch
	view:setPosition(display.cx,display.cy)
    self.fairyRoot:addChild(view)
	local pb = view:getChild("n11")
	local i=0
	pb:setValue(i)
	-- btn event, fairy has it's own EventDispatcher, cover the cocos's node
	view:getChild("n6"):addEventListener(fairygui.UIEventType.TouchEnd, function(context)
		i=i+1
		if i>100 then
			i=0
		end
		pb:setValue(i)
	end)
	local scheduler = require(cc.PACKAGE_NAME .. ".scheduler")

	
	scheduler.scheduleUpdateGlobal(function (dt  )
		i=i+dt
		if i>100 then
			i=0
		end
		pb:setValue(i)
	end)
end

return TestCase
