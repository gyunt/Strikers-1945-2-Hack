cpu = manager:machine().devices[":maincpu"]
mem = cpu.spaces["program"]
screen = manager:machine().screens[":screen"]


options = {["auto-shoot"] = 1, ["frame-per-action"] = 5}
player1 = {["x"] = 0, ["y"] = 0, ["move-x"] = "", ["move-y"] = ""}

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

function read_object(address)
    a_1 = mem:read_u32(address)
    a_2 = mem:read_u32(address+4)
    a_3 = mem:read_u32(address+8)
    a_4 = mem:read_u32(address+12)

    x = a_2 >> 16
    y = a_2 & 0xffff

    width = a_3 >> 16
    height = a_3 & 0xffff

    return {    ["ref"]=a_1, 
                ["x"] = x, 
                ["y"] = y, 
                ["height"] = height,
                ["width"] = width,
                ["child"] = a_4 }
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
    while (1) do
        t = read_object(adr)
        if t["ref"] == 0 then
            break
        end

        missiles[adr] = t
        
        adr = adr + 0x10
    end
    return missiles
end

-- draw
function draw_hitbox (x, y)
    screen:draw_box(y -10, x -10, y + 10, x + 10, 0, 0xff00ffff)   
end

function draw_boxes()
    draw_hitbox(player1["x"], player1["y"])

    objs = get_objects()
    for k,v in pairs(objs) do
        min_x = math.max(v["x"], 1)
        min_y = math.max(v["y"], 1)
        max_x = math.min(v["x"]+v["width"], v["x"]+screen:width())
        max_y = math.min(v["y"]+v["height"], v["y"]+screen:height())

        screen:draw_box(min_y, min_x, max_y, max_x, 0x80ff0030, 0xffff00ff)
    end

    mis = get_missiles()
    for k,v in pairs(mis) do
        min_x = math.max(v["x"], 1)
        min_y = math.max(v["y"], 1)
        max_x = math.min(v["x"]+v["width"], v["x"]+screen:width())
        max_y = math.min(v["y"]+v["height"], v["y"]+screen:height())

        screen:draw_box(min_y, min_x, max_y, max_x, 0, 0xff00ffff)
    end
end

function draw_messages()
    screen:draw_text(40, 40, "frame: " .. screen.frame_number(screen));
end

function p1()
    p1_autoshooting()

    frame_count = frame_count + 1
    if (frame_count > options["frame-per-action"]) then
        frame_count = 0;
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
    draw_messages()
end


emu.sethook(update, "frame");
