
module_path = "../?.lua"
package_name = "s1945ii"
package.path = package.path .. ";" .. module_path
s1945ii = require (package_name)

-- frame count
mem = "mem_test"
local frame_count = 0
player1 = {
    ["move-x"] = "", 
    ["move-y"] = ""}

options = {
    ["auto-shoot"] = 1,
    ["auto-move"] = 1,
    ["frame-per-action"] = 5,
}

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

            d_y = {"P1 Up", "", "P1 Down"}
            d_x = {"P1 Right", "", "P1 Left"}

            player1["move-x"] = d_x[math.random(1,3)];
            player1["move-y"] = d_y[math.random(1,3)];
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
        ioport["P1 Button 1"].write(ioport["P1 Button 1"], manager:machine().screens[":screen"].frame_number(manager:machine().screens[":screen"]
) % 2)
    end 
end


--tick
function tick()
    s1945ii.cheat()
    s1945ii.draw_enemies()
    s1945ii.draw_p1_collision()
    s1945ii.draw_missiles()
    s1945ii.draw_messages("n(enemies):" .. s1945ii.get_number_of_enemies())
    p1()
end

emu.sethook(tick, "frame");
