-- implement by jonghyuk65 (https://github.com/jonghyuk65).
-- edited by gyunt.

module_path = "../?.lua"
package_name = "s1945ii"
package.path = package.path .. ";" .. module_path
s1945ii = require (package_name)

-- frame count
local frame_count = 0
player1 = {
    ["move-x"] = "", 
    ["move-y"] = ""}

options = {
    ["auto-shoot"] = 1,
    ["auto-move"] = 1,
    ["frame-per-action"] = 5,
}


-- directivity (0:left, 1:right)
directivity = 0

function collision_check(x, y, w, h, objs)
    local mind = manager:machine().screens[":screen"]:width()+manager:machine().screens[":screen"]:height()
    for k,v in pairs(objs) do
        if(v["type"] == "enemy") then
            local ddx = math.abs(v["x"]-x) - w
            local ddy = math.abs(v["y"]-y) - h
            if ddx+ddy < mind then
                mind = ddx+ddy
            end
        end
    end
    return mind
end

function next_move()
    if s1945ii.get_p1_x() < 20 and directivity == 0 then
        directivity = 1
    elseif s1945ii.get_p1_x() > 200 and directivity == 1 then
        directivity = 0
    end

    dx = 2; dy = 2; bomb = false;
    if directivity == 0 then
        dx = 3
    else
        dx = 1
    end

    if s1945ii.get_p1_y() < 55 then
        dy = 1
    elseif s1945ii.get_p1_y() > 75 then
        dy = 3
    end

    local p1_collision = s1945ii.get_p1_collision()
    local mind = 99999

    for k,v in pairs(p1_collision) do
        local ret = collision_check(v["x"], v["y"], v["width"], v["height"], s1945ii.get_missiles())
        if ret < mind then mind = ret end
    end

    if mind < -10 then
        bomb = true
    elseif dy == 2 and mind < 10 then
        dy = math.random(0,1)*2+1
    end

    return dx, dy, bomb;
end

function p1()
    frame_count = frame_count + 1
    p1_autoshooting()
    if (frame_count > options["frame-per-action"]) then
        frame_count = 0;

        if options["auto-move"] == 1 then 
            port_x = ioport[player1["move-x"]]
            port_y = ioport[player1["move-y"]]
            if (port_x ~= nil) then
                port_x.write(port_x, 0)
            end
            if (port_y ~= nil) then
                port_y.write(port_y, 0)
            end

            dx, dy, bomb = next_move()

            d_y = {"P1 Up", "", "P1 Down"}
            d_x = {"P1 Right", "", "P1 Left"}
            player1["move-x"] = d_x[dx];
            player1["move-y"] = d_y[dy];
            if bomb then
                ioport["P1 Button 2"].write(ioport["P1 Button 2"], 1)
            end
        end
    end

    port_x = ioport[player1["move-x"]]
    port_y = ioport[player1["move-y"]]

    if (port_x ~= nil) then
        port_x.write(port_x, 1)
    end

    if (port_y ~= nil) then
        port_y.write(port_y, 1)
    end
end

function p1_autoshooting()
    if (options["auto-shoot"] == 1) then
        ioport["P1 Button 1"].write(ioport["P1 Button 1"], manager:machine().screens[":screen"].frame_number(manager:machine().screens[":screen"]) % 2)
    end
    ioport["P1 Button 2"].write(ioport["P1 Button 2"], 0)
end

--tick
function tick()
    s1945ii.cheat()
    s1945ii.draw_enemies()
    s1945ii.draw_p1_collision()
    s1945ii.draw_missiles()
    p1()
end

emu.sethook(tick, "frame");
