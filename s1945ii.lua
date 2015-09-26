cpu = manager:machine().devices[":maincpu"]
mem = cpu.spaces["program"]
screen = manager:machine().screens[":screen"]
p1_x = 0
p1_y = 0

o_num = 10
objects = {}

m_num = 10
missiles = {}

function cheat()
-- set P1 invincible
    mem:write_u8(0x60103FA, 1);
end

--update
function update_p1()
    p1_x = (mem:read_u32(0x60103a3) & 0xFFFF0) >> 8
    p1_y = (mem:read_u32(0x60103a7) & 0xFFFF0) >> 8
end

function read_object(address)
    a_1 = mem:read_u32(address);
    a_2 = mem:read_u32(address+4);
    a_3 = mem:read_u32(address+8);
    a_4 = mem:read_u32(address+12);

    x = a_2 >> 16
    y = a_2 & 0xffff

    width = a_3 >> 16
    height = a_3 & 0xffff

    return {["ref"]=a_1, ["x"] = x, ["y"] = y, ["height"] = height, ["width"] = width, ["child"] = a_4}
end

function update_objects()
end

-- draw
function draw_hitbox (x, y)
    screen:draw_box(y -10, x -10, y + 10, x + 10, 0, 0xff00ffff)   
end

function draw_boxes()
    draw_hitbox(p1_x, p1_y)

    adr = 0x6015f68
    while (1) do
        t = read_object(adr);
        if t["ref"] == 0 then
            break
        end
        screen:draw_box(t["y"], t["x"], t["y"] + t["height"], t["x"] + t["width"], 0x80ff0030, 0xffff00ff)
        adr = adr + 0x10 
    end
end

--tick
function update()
    cheat()
    update_p1()
    update_objects()
    draw_boxes()
end


emu.sethook(update, "frame");
