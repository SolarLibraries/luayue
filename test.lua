print("PATH: "..package.path)
print("CPATH: "..package.cpath)

local gui = require("yue.gui")

-- Create window and show it.
local win = gui.Window.create {}
function win:onclose() gui.MessageLoop.quit() end

local container = gui.Container.create()
local i = 0
container:addchildview(gui.Label.create "Counter")
container:addchildview(gui.Label.create "0")
local inc = gui.Button.create "Increment"
function inc:onclick()
    i = i + 1
    local child = container:childat(2) --[[@as nu.Label]]
    child:settext(tostring(i))
end
container:addchildview(inc)

win:setcontentview(container)
win:setcontentsize { width = 400, height = 400 }
win:center()
win:activate()

-- Enter message loop.
gui.MessageLoop.run()
