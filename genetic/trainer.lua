-- AI for Strikers 1945 II : Simple genetic programmng approach.
-- by Chang-young Koh (kcy1019, http://lucent.me)
-- *This script requires a saved game state.
module_path = "../?.lua"
package_name = "s1945ii"
package.path = package.path .. ";" .. module_path
s1945ii = require (package_name)
local screen = manager:machine().screens[":screen"]

--Tick
local cor_main = nil
local current_frame = 0
local frames_per_action = 2

function Tick()
    -- Draw the white box(AI's sight).
    local radius = 60
    local min_x = math.min(s1945ii.get_p1_x() + radius, screen:width())
    local max_x = math.max(s1945ii.get_p1_x() - radius, 0)
    local min_y = math.min(s1945ii.get_p1_y() + radius, screen:height())
    local max_y = math.max(s1945ii.get_p1_y() - radius, 0)
    screen:draw_box(min_y, min_x, max_y, max_x, 0x3f3f3f3F, 0xffffffff)

    current_frame = current_frame + 1
    ShootMissiles(current_frame % 2)
    if (current_frame > frames_per_action) then
        current_frame = 0
    end
    if coroutine.status(cor_main) ~= "dead" then
        no, msg = coroutine.resume(cor_main)
        if not no then print('error @ main:' .. msg); end
    end
end

-- Create a random genome.
function NewGenome(_size)
    local g = {}
    g.score = 0
    g.size = _size
    g.weights = {}

    local base = 0
    local c_init = {
                [1] =0.3,  -- Empty
                [2] =-1.,  -- Outside
                [3] =0.0,  -- Enemy
                [4] =-2.2  -- Missile
             }

    local i = 0
    local layer = 0
    for layer = 1, 4, 1 do
        for i = 1, _size*_size, 1 do
            local rr = math.floor(_size / 2)
            local xx = math.abs(math.floor(i / _size) - rr)
            local yy = math.abs(i % _size - rr)
            g.weights[base+i] = math.random() * c_init[layer] *
                                0.01 * ((rr - xx) + (rr - yy))
        end
        base = base + _size*_size
    end

    return g
end

-- Literally, duplicate a genome.
function CopyGenome(genome)
    local g = NewGenome(genome.size)

    local i = 0
    for i = 1, #g.weights, 1 do
        g.weights[i] = genome.weights[i]
    end

    g.score = genome.score
    return g
end

-- Mean / 2-point crossover.
function Crossover(g1, g2)
    local success = false
    local try = 0

    local i = 0
    local c1 = CopyGenome(g2)
    local c2 = CopyGenome(g1)


    for try = 1, 10, 1 do
        local p1 = math.random(1, math.floor(#g1.weights/2))
        local p2 = math.random(p1 + 5, #g1.weights)

        local t_weight = 0.0

        for i = p1, p2, 1 do
            if c1.weights[i] ~= c2.weights[i] then
                t_weight = c1.weights[i]
                c1.weights[i] = c2.weights[i]
                c2.weights[i] = t_weight
                success = true
            end
        end
        if success then break end
    end

    if not success then
        for i = 1, #c1.weights, 2 do
            t_weight = c1.weights[i]
            c1.weights[i] = c2.weights[i]
            c2.weights[i] = t_weight
        end
    end

    return c1, c2
end

-- Swap some elements in the kernel.
function Mutate(g, c_perturb)
    local i = 0
    if math.random(1, 2) == 1 then
        local cnt = math.random(1, g.size)

        while cnt > 0 do
            local p1 = math.random(1, #g.weights)
            local p2 = math.random(1, #g.weights)

            local t_weight = g.weights[p1]
            g.weights[p1] = g.weights[p2]
            g.weights[p2] = t_weight

            cnt = cnt - 1
        end
    else
        local p1 = math.random(1, #g.weights)
        local p2 = math.random(p1, #g.weights)

        for i = p1, p2, 1 do
            if math.random() <= 0.45 then
                g.weights[i] = g.weights[i] +
                               math.random() * c_perturb * 2 - c_perturb
            end
        end
    end

    return g
end

-- Evaluate score of kernel wrt to current context.
function EvalKernel(g, x, y)
    local seen = {}
    local i = 0
    local j = 0
    local k = nil
    local v = nil
    local xi = 0
    local yi = 0

    local radius = (g.size - g.size % 2) / 2

    local t_tile = {
                Empty  = 0,               -- Empty
                Outside= g.size*g.size,   -- Outside
                Enemy  = g.size*g.size*2, -- Enemy
                Missile= g.size*g.size*3  -- Missile
            }

    for i = 1, g.size, 1 do
        seen[i] = {}
        for j = 1, g.size, 1 do
            seen[i][j] = t_tile.Empty
        end
    end

    -- Ranges : {from x - radius to x + radius} x
    --          {from y - radius to y + radius}

    for k,v in pairs(s1945ii.get_enemies()) do
        min_x = math.max(math.max(v["x"], 16), x - radius)
        min_y = math.max(math.max(v["y"], 24), y - radius)
        max_x = math.min(math.min(v["x"]+v["width"], 200),
                         x + radius)
        max_y = math.min(math.min(v["y"]+v["height"], 200),
                         y + radius)

        for yi = min_y, max_y, 1 do
            for xi = min_x, max_x, 1 do
                seen[yi-y+radius+1][xi-x+radius+1] = t_tile.Enemy
            end
        end
    end

    for k,v in pairs(s1945ii.get_missiles()) do
        if v['check'] == 0 then
            min_x = math.max(math.max(v["x"], 16), x - radius)
            min_y = math.max(math.max(v["y"], 24), y - radius)
            max_x = math.min(math.min(v["x"]+v["width"], 200),
                             x + radius)
            max_y = math.min(math.min(v["y"]+v["height"], 200),
                             y + radius)

            for yi = min_y, max_y, 1 do
                for xi = min_x, max_x, 1 do
                    seen[yi-y+radius+1][xi-x+radius+1] = t_tile.Missile
                end
            end
        end
    end

    local ret = 0

    for i = 1, g.size, 1 do
        for j = 1, g.size, 1 do
            if (i + y - radius - 1 <= 16 or
                j + x - radius - 1 <= 24 or
                i + y - radius - 1 >= 200 or
                j + x - radius - 1 >= 200) then
                seen[i][j] = t_tile.Outside
            end
            ret = ret + g.weights[seen[i][j] + (i-1)*g.size + j]
        end
    end

    return ret
end

-- Hit missile button every 2 frames.
function ShootMissiles(key)
    ioport["P1 Button 1"].write(ioport["P1 Button 1"], key)
end

-- Evaluate score of the genome; scores collected until gameover.
local level = 2
local dx = {[0] = -level, [1] = level, [2] = 0, [3] = 0, [4] = 0}
local dy = {[0] = 0, [1] = 0, [2] = level, [3] = -level, [4] = 0}
local btn = {[0] = ioport["P1 Left"],
             [1] = ioport["P1 Right"],
             [2] = ioport["P1 Up"],
             [3] = ioport["P1 Down"],
             [4] = ioport[""]}
function EvalGenome(g)
    local cur_btn = nil
    local dir = 0
    s1945ii.load_state("s1945ii.saved")
    for i = 0, 4, 1 do
        if btn[i] ~= nil then
            btn[i].write(btn[i], 0)
        end
    end
    while s1945ii.is_p1_dead() == 1 do
        coroutine.yield()
    end

    local p_min_x = 200
    local p_max_x = 0
    local p_min_y = 200
    local p_max_y = 0

    while s1945ii.is_p1_dead() ~= 1 do
        if current_frame == frames_per_action then

            local cx = s1945ii.get_p1_x()
            local cy = s1945ii.get_p1_y()

            if cur_btn ~= nil then cur_btn.write(cur_btn, 0) end

            if cy < 500 then

                p_min_x = math.min(p_min_x, cx)
                p_max_x = math.max(p_max_x, cx)

                p_min_y = math.min(p_min_y, cy)
                p_max_y = math.max(p_max_y, cy)

                local max_score = -10000000
                local next_choice = 4
                for dir = 0, 4, 1 do
                    local nx = cx + dx[dir]
                    local ny = cy + dy[dir]
                    local expected = EvalKernel(g, nx, ny)
                    if expected > max_score then
                        max_score = expected
                        next_choice = dir
                    end
                end

                --s1945ii.draw_messages(next_choice .. ": " .. max_score)
                cur_btn = btn[next_choice]
                if cur_btn ~= nil then cur_btn.write(cur_btn, 1) end

            end

        end
        coroutine.yield()
    end

    return s1945ii.get_stage_time() + s1945ii.get_stage_number() * 1000000,
           (p_max_x - p_min_x) * (p_max_y - p_min_y)
end

-- Save/Load data of current generation to/from the file.
function SaveGeneration(filename, generation)
    local fp = io.open(filename, "w")
    fp:write(#generation.. "\n")
    local x = 0
    local g = nil
    for x = 1, #generation, 1 do
        fp:write(generation[x].size .. " " .. generation[x].score .. "\n")
        fp:write(table.concat(generation[x].weights, " ") .. "\n")
    end
    io.close(fp)
end

function LoadGeneration(filename)
    local fp = io.open(filename, "r")
    if fp == nil then return nil; end
    local generation = {}
    local n = fp:read("*number")
    local i = 0
    for i = 1, n, 1 do
        local size = fp:read("*number")
        local score = fp:read("*number")
        generation[i] = NewGenome(size)
        generation[i].score = score
        for j = 1, size*size*4, 1 do
            generation[i].weights[j] = fp:read("*number")
        end
    end
    io.close(fp)
    return generation
end

function SameGenome(g1, g2)
    if g1.score ~= g2.score then return false end
    if g1.size ~= g2.size then return false end
    if #g1.weights ~= #g2.weights then return false end
    for i = 1, #g1.weights, 1 do
        if g1.weights[i] ~= g2.weights[i] then return false end
    end
    return true
end

function Train(train_options)
    s1945ii.load_state()

    local i = 0
    local j = 0
    -- Load or create a generation.
    local current_generation = LoadGeneration("genetic/genetic.dat")
    if current_generation ~= nil then
    else
        current_generation = {}
        for i = 1, train_options.population_size, 1 do
            current_generation[i] = NewGenome(train_options.kernel_size)
        end
    end

    local gen = 0
    local next_generation = {}
    -- Until the maximum generation, repeat training.
    for gen = 1, train_options.max_generation, 1 do

        next_generation = {}

        -- Preserve Elite(s)
        table.sort(current_generation, function(a, b)
                        return a.score > b.score
                   end)

        for i = 1, train_options.n_elite, 1 do
            next_generation[i] = CopyGenome(current_generation[i])
        end

        -- Crossover
        while #next_generation < train_options.population_size do
            local break_flag = false
            local c1 = nil
            local c2 = nil
            for i = 1, #current_generation, 1 do
                for j = i+1, #current_generation, 1 do
                    if not SameGenome(current_generation[i], current_generation[j])
                       and math.random() <= train_options.p_crossover then
                        c1, c2 = Crossover(current_generation[i],
                                           current_generation[j])
                        next_generation[#next_generation+1] = c1
                        if #next_generation < train_options.population_size then
                            next_generation[#next_generation+1] = c2
                        end
                        if #next_generation == train_options.population_size then
                            break_flag = true
                        end
                    end
                    if break_flag then break; end
                end
                if break_flag then break; end
            end
        end

        -- Mutation
        for i = 1, #next_generation, 1 do
            if math.random() <= train_options.p_mutation then
                next_generation[i] = Mutate(next_generation[i],
                                            train_options.c_perturb)
            end
        end

        -- Evaluation
        current_generation = {}
        print('--------Generation #' .. gen ..
              '(' .. #next_generation .. ')--------------')
        local k = 0
        for k = 1, #next_generation, 1 do
            local cor = coroutine.create(EvalGenome)
            local st = false
            local range = 0
            st, next_generation[k].score = coroutine.resume(cor, next_generation[k])
            while coroutine.status(cor) ~= "dead" do
                if not st then print('error @ eval:' .. next_generation[k].score); end
                st, next_generation[k].score, range = coroutine.resume(cor)
                coroutine.yield()
            end
            if not st then print(next_generation[k].score); end
            print(k .. ":" .. next_generation[k].score .. "," .. range)
            -- next_generation[k].score = next_generation[k].score + range * 0.1
            if range <= 384 then
                next_generation[k].score = -1000000
            end
            current_generation[k] = CopyGenome(next_generation[k])
        end
        print('--------------------------------------------')

        -- Save
        SaveGeneration("genetic/genetic.dat", next_generation)
        next_generation = {}
    end

    emu.exit()
end

math.randomseed(os.time())
cor_main = coroutine.create(Train)
coroutine.resume(cor_main, {
    population_size = 33,
    max_generation = 10000,
    kernel_size = 121,
    p_crossover = 0.60,
    p_mutation = 0.10,
    c_perturb = 0.5,
    n_elite = 3
})
emu.sethook(Tick, "frame");
