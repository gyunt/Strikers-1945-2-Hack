cpu = manager:machine().devices[":maincpu"]
mem = cpu.spaces["program"]
screen = manager:machine().screens[":screen"]


options = {
    ["auto-shoot"] = 0,
    ["auto-move"] = 0,
    ["frame-per-action"] = 5,
    ["object-hitbox"] = 1,
    ["state-msg"] = 1, 
    ["missile-hitbox"] = 0}
player1 = {
    ["x"] = 0, 
    ["y"] = 0, 
    ["move-x"] = "", 
    ["move-y"] = ""}

-- frame per action
frame_count = 0

function cheat()
-- set P1 invincible
    mem:write_u8(0x60103FA, 1)
end

--update
function update_p1()
    player1["x"] = (mem:read_u32(0x60103a3) & 0xFFFF0) >> 8
    player1["y"] = (mem:read_u32(0x60103a7) & 0xFFFF0) >> 8
end

-- play-time in playing-stage, unit = 1/100 sec
function get_stage_time()
    return mem:read_u32(0x600c4e0)
end

-- whole play-time, unit = 1/100 sec
function get_play_time()
    return mem:read_u32(0x60103bc)
end

function get_p1_score()
    return mem:read_u32(0x060103c4)
end

function get_p1_extra_weapon_gauge()
    -- 0 ~ 48980000
    return mem:read_u32(0x6010414)
end

function get_p1_number_of_bombs()
    return mem:read_u8(0x60103C3)
end

function get_p1_number_of_lives()
    return mem:read_u8(0x60103C1)
end

function get_p1_fire_power()
    return mem:read_u8(0x60103e7)
end

function read_object(address)
    a_1 = mem:read_u32(address)
    a_2 = mem:read_u32(address+4)
    a_3 = mem:read_u32(address+8)
    a_4 = mem:read_u32(address+12)

    x = a_2 >> 16
    if (x > 0x8000) then
        x = x - 0xffff
    end

    y = (a_2 & 0x7fff)
    if (y > 0x8000) then
        y = y - 0xffff
    end
    width = a_3 >> 16
    height = a_3 & 0xffff

    return {    ["ref"]=a_1, 
                ["x"] = x, 
                ["y"] = y, 
                ["height"] = height,
                ["width"] = width,
                ["child"] = a_4 & 0xffff,
                ["check"] = a_4 >> 16}
end

function get_objects()
    objects = {}
    adr = 0x6015f68
    while (1) do
        t = read_object(adr)
        if t["ref"] == 0 then
            break
        end

        objects[adr] = t

        adr = adr + 0x10 
        if (mem:read_u32(t["ref"]) == 0x6091e48 and t["child"] == 1) then
            break
        end
    end

    return objects
end

function get_missiles()
    missiles = {}
    adr = 0x6016f68

    n = mem:read_u16(0x6018ecc) + mem:read_u16(0x60190d0)
    for i = 1, n do
        t = read_object(adr)
        missiles[adr] = t
        adr = adr + 0x10
    end
    return missiles
end

-- draw
function draw_boxes()
    draw_hitbox({[0] = {["x"]=player1["x"]-10, ["y"]=player1["y"]-10, ["width"] = 20, ["height"] = 20}}, 0, 0xff00ffff)
    if options["object-hitbox"] == 1 then draw_hitbox(get_objects(), 0x80ff0030, 0xffff00ff) end
    if options["missile-hitbox"] == 1 then draw_hitbox(get_missiles(),0, 0xff00ffff) end 
end

function draw_hitbox(objs, color_inside, color_border)
    for k,v in pairs(objs) do
        min_x = math.max(v["x"], 0)
        min_y = math.max(v["y"], 0)
        max_x = math.min(v["x"]+v["width"], v["x"]+screen:width())
        max_y = math.min(v["y"]+v["height"], v["y"]+screen:height())

        screen:draw_box(min_y, min_x, max_y, max_x, color_inside, color_border)
    end
end

function draw_messages()
    screen:draw_text(40, 40, "frame: " .. screen.frame_number(screen));
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
        ioport["P1 Button 1"].write(ioport["P1 Button 1"], screen.frame_number(screen) % 2)
    end 
end

--tick
function update()
    cheat()
    update_p1()
    draw_boxes()
    p1()
    if (options["state-msg"] == 1) then
        draw_messages()
    end
end


emu.sethook(update, "frame");
