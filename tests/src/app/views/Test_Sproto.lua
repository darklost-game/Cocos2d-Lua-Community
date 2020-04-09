local BaseLayer = require("app.scenes.BaseLayer")

local TestCase = class("Test_Sproto", BaseLayer)





function TestCase:ctor()
	self.super.ctor(self)

	self:setNodeEventEnabled(true)
	-- tips
	local label = display.newTTFLabel({
		text = "sproto test see console",
		size = 25,
		color = cc.c3b(255, 255, 255),
	})
	label:align(display.CENTER, display.cx, display.cy + 200)
	self:addChild(label)
	

	self:test()
	self:testall()
	self:testrpc()

	
end

function TestCase:test( )
local sproto = require "sproto"
local core = require "sproto.core"	
local sp = sproto.parse [[
	.Person {
		name 0 : string
		id 1 : integer
		email 2 : string
		.PhoneNumber {
			number 0 : string
			type 1 : integer
		}
		phone 3 : *PhoneNumber
	}
	.AddressBook {
		person 0 : *Person(id)
		others 1 : *Person(id)
	}
	]]
	
	-- core.dumpproto only for debug use
	core.dumpproto(sp.__cobj)
	
	local def = sp:default "Person"
	print("default table for Person")
	dump(def)
	print("--------------")
	
	local person = {
		[10000] = {
			name = "Alice",
			id = 10000,
			phone = {
				{ number = "123456789" , type = 1 },
				{ number = "87654321" , type = 2 },
			}
		},
		[20000] = {
			name = "Bob",
			id = 20000,
			phone = {
				{ number = "01234567890" , type = 3 },
			}
		}
	}
	
	local ab = {
		person = setmetatable({}, { __index = person, __pairs = function() return next, person, nil end }),
		others = {
			{
				name = "Carol",
				id = 30000,
				phone = {
					{ number = "9876543210" },
				}
			},
		}
	}
	
	collectgarbage "stop"
	
	local code = sp:encode("AddressBook", ab)
	local addr = sp:decode("AddressBook", code)
	dump(addr)
end

function TestCase:testrpc( )
	local sproto = require "sproto"
	local core = require "sproto.core"
	local server_proto = sproto.parse [[
		.package {
			type 0 : integer
			session 1 : integer
		}
		foobar 1 {
			request {
				what 0 : string
			}
			response {
				ok 0 : boolean
			}
		}
		foo 2 {
			response {
				ok 0 : boolean
			}
		}
		bar 3 {
			response nil
		}
		blackhole 4 {
		}
		]]
	
	local client_proto = sproto.parse [[
		.package {
			type 0 : integer
			session 1 : integer
		}
		]]
	
	
	assert(server_proto:exist_type "package")
	assert(server_proto:exist_proto "foobar")
	
	print("=== default table")
	
	dump(server_proto:default("package"))
	dump(server_proto:default("foobar", "REQUEST"))
	assert(server_proto:default("foo", "REQUEST")==nil)
	assert(server_proto:request_encode("foo")=="")
	server_proto:response_encode("foo", { ok = true })
	assert(server_proto:request_decode("blackhole")==nil)
	assert(server_proto:response_decode("blackhole")==nil)
	
	print("=== test 1")
	
	-- The type package must has two field : type and session
	local server = server_proto:host "package"
	local client = client_proto:host "package"
	local client_request = client:attach(server_proto)
	
	print("client request foobar")
	local req = client_request("foobar", { what = "foo" }, 1)
	print("request foobar size =", #req)
	local type, name, request, response = server:dispatch(req)
	assert(type == "REQUEST" and name == "foobar")
	dump(request)
	print("server response")
	local resp = response { ok = true }
	print("response package size =", #resp)
	print("client dispatch")
	local type, session, response = client:dispatch(resp)
	assert(type == "RESPONSE" and session == 1)
	dump(response)
	
	local req = client_request("foo", nil, 2)
	print("request foo size =", #req)
	local type, name, request, response = server:dispatch(req)
	assert(type == "REQUEST" and name == "foo" and request == nil)
	local resp = response { ok = false }
	print("response package size =", #resp)
	print("client dispatch")
	local type, session, response = client:dispatch(resp)
	assert(type == "RESPONSE" and session == 2)
	dump(response)
	
	local req = client_request("bar", nil, 3)
	print("request bar size =", #req)
	local type, name, request, response = server:dispatch(req)
	assert(type == "REQUEST" and name == "bar" and request == nil)
	assert(select(2,client:dispatch(response())) == 3)
	
	local req = client_request "blackhole"	-- no response
	print("request blackhole size = ", #req)
	
	print("=== test 2")
	local v, tag = server_proto:request_encode("foobar", { what = "hello"})
	assert(tag == 1)	-- foobar : 1
	print("tag =", tag)
	dump(server_proto:request_decode("foobar", v))
	local v = server_proto:response_encode("foobar", { ok = true })
	dump(server_proto:response_decode("foobar", v))
end

function TestCase:testall( )
local sproto = require "sproto"
local core = require "sproto.core"
local sp = sproto.parse [[
	.foobar {
		.nest {
			a 1 : string
			b 3 : boolean
			c 5 : integer
			d 6 : integer(3)
		}
		a 0 : string
		b 1 : integer
		c 2 : boolean
		d 3 : *nest(a)
		e 4 : *string
		f 5 : *integer
		g 6 : *boolean
		h 7 : *foobar
		i 8 : *integer(2)
		j 9 : binary
	}
	]]
	
	local obj = {
		a = "hello",
		b = 1000000,
		c = true,
		d = {
			{
				a = "one",
				-- skip b
				c = -1,
			},
			{
				a = "two",
				b = true,
			},
			{
				a = "",
				b = false,
				c = 1,
			},
			{
				a = "decimal",
				d = 1.235,
			}
		},
		e = { "ABC", "", "def" },
		f = { -3, -2, -1, 0 , 1, 2},
		g = { true, false, true },
		h = {
			{ b = 100 },
			{},
			{ b = -100, c= false },
			{ b = 0, e = { "test" } },
		},
		i = { 1,2.1,3.21,4.321 },
		j = "\0\1\2\3",
	}
	
	local code = sp:encode("foobar", obj)
	obj = sp:decode("foobar", code)
	dump(obj)
	
	-- core.dumpproto only for debug use
	local core = require "sproto.core"
	core.dumpproto(sp.__cobj)
end
return TestCase
