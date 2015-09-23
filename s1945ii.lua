cpu = manager:machine().devices[":maincpu"]
mem = cpu.spaces["program"]
screen = manager:machine().screens[":screen"]
p1_x = 0
p1_y = 0

o_num = 10
objects = {}

m_num = 10
missiles = {}
function update_p1()
    p1_x = (mem:read_u32(0x60103a3) & 0xFFFF0) >> 8
    p1_y = (mem:read_u32(0x60103a7) & 0xFFFF0) >> 8
end

function read_object(address)
    bits = {}

    int a = mem:read_u32(address);
    bits[0] 
end

function update_objects()
end

function draw_hitbox()
    screen:draw_box(p1_y -10, p1_x -10, p1_y + 10, p1_x + 10, 0, 0xff00ffff)   
end

function update()
    update_p1()
    update_objects()
    draw_hitbox()
end




emu.sethook(update, "frame");
