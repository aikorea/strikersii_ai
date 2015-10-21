local s1945ii = {}

local cpu = manager:machine().devices[":maincpu"]
local mem = cpu.spaces["program"]
local screen = manager:machine().screens[":screen"]

function s1945ii.cheat()
-- set infinite credit
    mem:write_u8(0x600c3be, 09)
-- set P1 invincible
    mem:write_u8(0x60103FA, 1)
-- set P1 infinite life
    mem:write_u8(0x60103c1, 3)
end

function s1945ii.get_p1_x()
    return  (mem:read_u32(0x60103a3) & 0xFFFF0) >> 8
end

function s1945ii.get_p1_y()
    return  (mem:read_u32(0x60103a7) & 0xFFFF0) >> 8
end

-- play-time in playing-stage, unit = 1/100 sec
function s1945ii.get_stage_time()
    return mem:read_u32(0x600c4e0)
end

function s1945ii.get_state_number()
    return mem:read_u8(0x600c674) + 1
    --mem:read_u8(0x600c553)
end

-- whole play-time, unit = 1/100 sec
function s1945ii.get_play_time()
    return mem:read_u32(0x60103bc)
end

function s1945ii.get_p1_score()
    return mem:read_u32(0x060103c4)
end

function s1945ii.get_p1_extra_weapon_gauge()
    -- 0 ~ 48980000
    return mem:read_u32(0x6010414)
end

function s1945ii.get_p1_number_of_bombs()
    return mem:read_u8(0x60103C3)
end

function s1945ii.get_p1_number_of_lives()
    return mem:read_u8(0x60103C1)
end

function s1945ii.get_p1_fire_power()
    return mem:read_u8(0x60103e7)
end

function s1945ii.get_number_of_object()
    return mem:read_u16(0x6018b46)
end
-- n(items) = n(gold) + n(power) + n(bomb)
function s1945ii.get_number_of_items()
    return mem:read_u16(0x601c428)
end

function read_object(address)
    local a_1 = mem:read_u32(address)
    local a_2 = mem:read_u32(address+4)
    local a_3 = mem:read_u32(address+8)
    local a_4 = mem:read_u32(address+12)

    local x = a_2 >> 16
    if (x > 0x8000) then
        x = x - 0xffff
    end

    local y = (a_2 & 0x7fff)
    if (y > 0x8000) then
        y = y - 0xffff
    end
    local width = a_3 >> 16
    local height = a_3 & 0xffff
    local _type = ""
    local ref_adr = mem:read_u32(a_1)

    if ref_adr == 0x6092a24 then
        if width == 0x18 then
            _type = "power"
        elseif width == 0x1b then
            _type = "bomb"
        else
            _type ="gold"
        end
    elseif ref_adr == 0x6091e48 then
        _type = "p1"
    else
        _type = "enemy"
    end

    return {    ["ref"]=a_1, 
                ["x"] = x, 
                ["y"] = y, 
                ["height"] = height,
                ["width"] = width,
                ["child"] = a_4 & 0xffff,
                ["check"] = a_4 >> 16,
                ["type"] = _type}
end

function s1945ii.get_flights()
    local objects = {}
    local adr = 0x6015f68
    
    while (1) do
        local t = read_object(adr)
        if t["ref"] == 0 then
            break
        end
        objects[adr] = t
        adr = adr + 0x10 
        if (mem:read_u32(t["ref"]) == 0x6091e48 and t["child"] == 1) then
            break
        end
    end


    local cnt = 0
    adr = 0x6018148
    while (1) do
        local t = read_object(adr)
        if t["ref"] == 0 then
            break
        end

        if (t["type"] == "bomb" or t["type"] == "gold" or t["type"] == "power") then
            cnt = cnt + 1
            objects[adr] = t

            if (cnt >= s1945ii.get_number_of_items()) then break end
        end
        adr = adr + 0x10 
    end

    return objects
end

function s1945ii.get_missiles()
    local missiles = {}
    local adr = 0x6016f68

    n = mem:read_u16(0x6018ecc) + mem:read_u16(0x60190d0)
    for i = 1, n do
        t = read_object(adr)
        missiles[adr] = t
        adr = adr + 0x10
    end
    return missiles
end

-- draw
function s1945ii.draw_flights()
    s1945ii.draw_hitbox(s1945ii.get_flights(), 0x80ff0030, 0xffff00ff) 
end

function s1945ii.draw_missiles()
    s1945ii.draw_hitbox(s1945ii.get_missiles(),0, 0xff00ffff) 
end

function s1945ii.draw_hitbox(objs, color_inside, color_border)
    for k,v in pairs(objs) do
        min_x = math.max(v["x"], 0)
        min_y = math.max(v["y"], 0)
        max_x = math.min(v["x"]+v["width"], v["x"]+screen:width())
        max_y = math.min(v["y"]+v["height"], v["y"]+screen:height())


        if (v["type"] == "power" or v["type"] == "bomb" or v["type"] == "gold") then
            if (v["type"] == "power") then
                screen:draw_box(min_y, min_x, max_y, max_x, 0, 0xff00ffff)
            elseif (v["type"] == "bomb") then
                screen:draw_box(min_y, min_x, max_y, max_x, 0, 0xffff00ff)
            elseif (v["type"] == "gold") then
                screen:draw_box(min_y, min_x, max_y, max_x, 0, 0xffffff00)
            end
        else
            screen:draw_box(min_y, min_x, max_y, max_x, color_inside, color_border)
        end
    end
end

function s1945ii.draw_messages(str)
    screen:draw_text(40, 40, str);
end

return s1945ii


