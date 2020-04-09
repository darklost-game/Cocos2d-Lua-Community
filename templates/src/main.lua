
function __G__TRACKBACK__(errorMessage)
    print("----------------------------------------")
    print("LUA ERROR: " .. tostring(errorMessage) .. "\n")
    print(debug.traceback("", 2))
    print("----------------------------------------")
end

package.path = "src/?.lua;src/framework/protobuf/?.lua;src/framework/sproto/?.lua"
require("app.MyApp").new():run()
