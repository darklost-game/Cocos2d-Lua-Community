local BaseLayer = require("app.scenes.BaseLayer")

local TestCase = class("Test_Shader", BaseLayer)
local Default_vert = [[
	attribute vec4 a_position;
	attribute vec2 a_texCoord;
	attribute vec4 a_color;

	uniform mat4 u_MVPMatrix;

	#ifdef GL_ES
	varying lowp vec4 v_fragmentColor;
	varying mediump vec2 v_texCoord;
	#else
	varying vec4 v_fragmentColor;
	varying vec2 v_texCoord;
	#endif

	void main()
	{
		gl_Position = u_MVPMatrix * a_position;
		v_fragmentColor = a_color;
		v_texCoord = a_texCoord;
	}
]]
local GaussBlur_fsh = [[
	#ifdef GL_ES
	precision lowp float;
	#endif
	
	varying vec4 v_fragmentColor;
	varying vec2 v_texCoord;
	
	uniform sampler2D u_texture;
	uniform vec2 u_resolution;
	uniform float u_level;
	
	vec4 blur(vec2);
	
	void main(void)
	{
		vec4 col = blur(v_texCoord);
		gl_FragColor = vec4(col) * v_fragmentColor;
	}
	
	vec4 blur(vec2 p)
	{
		vec4 col = vec4(0);
		vec2 unit = 1.0 / u_resolution.xy;
		
		float r = 10.0 * u_level;
		float sampleStep = 1.0;
		
		float count = 0.0;
		
		for(float x = -r; x < r; x += sampleStep)
		{
			for(float y = -r; y < r; y += sampleStep)
			{
				float weight = (r - abs(x)) * (r - abs(y));
				col += texture2D(u_texture, p + vec2(x * unit.x, y * unit.y)) * weight;
				count += weight;
			}
		}
		
		return col / count;
	}	
]]
local CircleSquare_fsh = [[
	#ifdef GL_ES
	precision lowp float;
	#endif
	varying vec4 v_fragmentColor;
	varying vec2 v_texCoord;

	uniform float u_edge;
	uniform sampler2D u_texture;

	void main()
	{
		float edge = u_edge;
		float dis = 0.0;
		vec2 texCoord = v_texCoord;
		if (texCoord.x < edge)
		{
			if (texCoord.y < edge)
			{
				dis = distance(texCoord, vec2(edge, edge));
			}
			if (texCoord.y > (1.0 - edge))
			{
				dis = distance(texCoord, vec2(edge, (1.0 - edge)));
			}
		}
		else if (texCoord.x > (1.0 - edge))
		{
			if (texCoord.y < edge)
			{
				dis = distance(texCoord, vec2((1.0 - edge), edge));
			}
			if (texCoord.y > (1.0 - edge))
			{
				dis = distance(texCoord, vec2((1.0 - edge), (1.0 - edge)));
			}
		}

		if(dis > 0.001)
		{
			// 外圈沟
			float gap = edge * 0.02;
			if(dis <= edge - gap)
			{
				gl_FragColor = texture2D(u_texture, texCoord);
			}
			else if(dis <= edge)
			{
				// 平滑过渡
				float t = smoothstep(0., gap, edge - dis);
				vec4 color = texture2D(u_texture, texCoord);
				gl_FragColor = vec4(color.rgb, t);
			}else{
				gl_FragColor = vec4(0., 0., 0., 0.);
			}
		}
		else
		{
			gl_FragColor = texture2D(u_texture, texCoord);
		}
	}
]]


local Circle_fsh = [[
	#ifdef GL_ES
	precision lowp float;
	#endif
	varying vec4 v_fragmentColor;
	varying vec2 v_texCoord;
	
	uniform sampler2D u_texture;

	uniform float radius;//0.5 //半径
    uniform float blur; //0.01
    uniform vec2  center; //0.5 0.5 //中心点
    uniform float wh_ratio; //1 长宽比


	void main()
	{
		vec4 color = texture2D(u_texture, v_texCoord);
		float cicle = radius;
		float rx = center.x*wh_ratio;
		float ry = center.y;

		//计算点与中心店距离 wh_ratio
		float distance_x =  v_texCoord.x * wh_ratio - rx;
		float distance_y =  v_texCoord.y  - ry;

		float dis = sqrt(pow(distance_x, 2) + pow(distance_y, 2));

		//float dis = length(v_texCoord - vec2(rx,ry)); 

		//圈外
		if( dis > cicle){
			//discard;
			gl_FragColor = vec4(0., 0., 0., 0.);
		//渐变带
		}else if( dis > (cicle - blur) ){

			float alpha = smoothstep(cicle, cicle - blur, dis);
			gl_FragColor = vec4(color.rgb, alpha); 

		//圈内
		}else{
			gl_FragColor = color; 
		}
		


	}
]]

local Gray_fsh = [[
	#ifdef GL_ES
	precision lowp float;
	#endif
	
	varying vec4 v_fragmentColor;
	varying vec2 v_texCoord;
	
	uniform sampler2D u_texture;
	
	void main(void)
	{
		vec4 c = texture2D(u_texture, v_texCoord);
		gl_FragColor.xyz = vec3(0.21*c.r + 0.72*c.g + 0.07*c.b);
		gl_FragColor.w = c.w;
	}
]]


local OutLine_fsh = [[
	#ifdef GL_ES
	precision lowp float;
	#endif
	
	varying vec4 v_fragmentColor;
	varying vec2 v_texCoord;
	
	uniform vec3 u_color;
	uniform sampler2D u_texture;
	
	void main()
	{
		float threshold = 1.0;
		float radius = 0.01;
		vec4 accum = vec4(0.0);
		vec4 normal = vec4(0.0);
		vec3 color = u_color;
		
		normal = texture2D(u_texture, vec2(v_texCoord.x, v_texCoord.y));
	
		accum += texture2D(u_texture, vec2(v_texCoord.x - radius, v_texCoord.y - radius));
		accum += texture2D(u_texture, vec2(v_texCoord.x + radius, v_texCoord.y - radius));
		accum += texture2D(u_texture, vec2(v_texCoord.x + radius, v_texCoord.y + radius));
		accum += texture2D(u_texture, vec2(v_texCoord.x - radius, v_texCoord.y + radius));
		accum *= threshold;
	
		accum.rgb =  color * accum.a;
		
		normal = ( accum * (1.0 - normal.a)) + (normal * normal.a);
		
		gl_FragColor = v_fragmentColor * normal;
	}
]]



---------------------------------------------------------------------Shader Start
--[[
    @desc: 获取渲染节点
    author:Bogey
    time:2019-06-26 11:12:16
    --@node:
    --@tb: 
    --@cascadeChildren: 是否级联子节点
    @return:
]]
local function getRealNodes(node, tb, cascadeChildren)
    if not cascadeChildren then
        local nodeType = tolua.type(node)
        if nodeType == "cc.Sprite" then
            table.insert(tb, node)
        elseif nodeType == "ccui.Scale9Sprite" then
            table.insert(tb, node)
        elseif nodeType == "ccui.Button" then
            getRealNodes(node:getVirtualRenderer(), tb)
        elseif nodeType == "ccui.ImageView" then
            getRealNodes(node:getVirtualRenderer(), tb)
        end
    else
        getRealNodes(node, tb)
        local children = node:getChildren()
        for k,v in pairs(children) do
            getRealNodes(v, tb, cascadeChildren)
        end
    end
end

--[[
    @desc: 高斯模糊[shader实现，掉帧严重]
    author:Bogey
    time:2019-05-15 14:26:45
    --@node: 要变模糊的节点
    --@cascadeChildren: 是否级联子节点
    --@level: 模糊级别，尽量不要超过3
    @return:
]]
function display.makeBlur(node, cascadeChildren, level)
    level = level or 1

    local nodes = {}
    getRealNodes(node, nodes, cascadeChildren)
    for _, node in pairs(nodes) do
        local size = node:getContentSize()
        local scale = node:getScale()
        if size.width > 0 and size.height > 0 then
            local resolution = cc.pMul(cc.p(size.width, size.height), 0.25 * scale)
            local program = ccb.Device:getInstance():newProgram(Default_vert, GaussBlur_fsh)
            local programState = ccb.ProgramState:new(program)
            programState:setUniformVec2("u_resolution", resolution)
            programState:setUniformFloat("u_level", level)
            node:setProgramState(programState)
        end
    end
end

--[[
    @desc: 节点置灰[按钮的置灰只置灰当前显示的状态]
    author:Bogey
    time:2019-05-15 16:19:26
    --@node: 
    --@cascadeChildren: 是否级联子节点
    @return:
]]
function display.makeGray(node, cascadeChildren)
    local nodes = {}
    getRealNodes(node, nodes, cascadeChildren)
    for _, node in pairs(nodes) do
        local program = ccb.Device:getInstance():newProgram(Default_vert, Gray_fsh)
        local programState = ccb.ProgramState:new(program)
        node:setProgramState(programState)
    end
end

--[[
    @desc: 渲染为圆角
    author:Bogey
    time:2019-08-28 11:32:04
    --@node:
	--@cascadeChildren:
	--@level: 取值0~0.5之间
    @return:
]]
function display.makeCircleSquare(node, cascadeChildren, level)
    level = level or 0.5

    local nodes = {}
    getRealNodes(node, nodes, cascadeChildren)
    for _, node in pairs(nodes) do
        local program = ccb.Device:getInstance():newProgram(Default_vert, CircleSquare_fsh)
        local programState = ccb.ProgramState:new(program)
        programState:setUniformFloat("u_edge", level)
        node:setProgramState(programState)
    end
end

--[[
    @desc: 渲染为圆角
    author:Bogey
    time:2019-08-28 11:32:04
    --@node:
	--@cascadeChildren:
	--@level: 取值0~0.5之间
    @return:
]]
function display.makeCircle(node, cascadeChildren, radius,wh_ratio,center,blur)
    radius = radius or 0.5
	wh_ratio =  wh_ratio or 1
	center = center or cc.p(0.5,0.5)
	blur = blur or 0.01
    local nodes = {}
    getRealNodes(node, nodes, cascadeChildren)
    for _, node in pairs(nodes) do
        local program = ccb.Device:getInstance():newProgram(Default_vert, Circle_fsh)
        local programState = ccb.ProgramState:new(program)
		programState:setUniformFloat("radius", radius)
		programState:setUniformFloat("wh_ratio",wh_ratio)
		programState:setUniformFloat("blur",blur)
		programState:setUniformVec2("center",center)
        node:setProgramState(programState)
    end
end

--[[
    @desc: 外发光
    author:Bogey
    time:2019-10-08 16:50:52
    --@node:
	--@cascadeChildren:
	--@color: cc.c3b()
    @return:
]]
function display.makeOutline(node, cascadeChildren, color)
    color = color or cc.c3b(245, 128, 15)

    local nodes = {}
    getRealNodes(node, nodes, cascadeChildren)
    for _, node in pairs(nodes) do
        local vec3 = {x = color.r / 255, y = color.g / 255, z = color.b / 255}
        local program = ccb.Device:getInstance():newProgram(Default_vert, OutLine_fsh)
        local programState = ccb.ProgramState:new(program)
        programState:setUniformVec3("u_color", vec3)
        node:setProgramState(programState)
    end
end

--[[
    @desc: 恢复默认glProgramState
    author:Bogey
    time:2019-05-15 15:32:53
    --@node: 
    --@cascadeChildren: 是否级联子节点
    @return:
]]
function display.makeNormal(node, cascadeChildren)
    local nodes = {}
    getRealNodes(node, nodes, cascadeChildren)
    for _, node in pairs(nodes) do
        local program = ccb.Program:getBuiltinProgram(6)
        local programState = ccb.ProgramState:new(program)
        node:setProgramState(programState)
    end
end

---------------------------------------------------------------------Shader Ended
function TestCase:ctor()
	self.super.ctor(self)

	local sp = display.newSprite("chip4.png")
	local sp_size = sp:getContentSize()
	sp:pos(sp_size.width/2,sp_size.height/2):addTo(self)
	

	display.makeCircleSquare(sp,false,0.25)

	local sp1 = display.newSprite("avatar01.jpg")
	sp1:pos( display.width -sp_size.width/2,sp_size.height/2):addTo(self)
	-- sp1:center()
	display.makeBlur(sp1)




	local sp2 = display.newSprite("avatar01.jpg")
	sp2:pos(sp_size.width/2,display.height-sp_size.height/2):addTo(self)

	display.makeGray(sp2)


	local sp3 = display.newSprite("avatar01.jpg")
	sp3:pos(display.width -sp_size.width/2,display.height-sp_size.height/2):addTo(self)

	display.makeOutline(sp3)


	local sp4 = display.newSprite("chip4.png")
	local size = sp:getContentSize()
	sp4:center():addTo(self)

	display.makeCircle(sp4,false,0.5,size.width/size.height,cc.p(0.5,0.5),0.1)




	


	
end

return TestCase
