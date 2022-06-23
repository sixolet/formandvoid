-- Form and Void
--
-- MPE formant polysynth
-- sounds a little like wind
-- instruments or voice.
-- 
-- @sixolet
--
-- Impulses trigger grains of 2
-- formants. Formant 1 grains =
-- FM grains; set its index to 0
-- = sine grains. Formant 2
-- = sine grains, but they may
-- phase modulate the carrier.
--
--               F1 mod
--                 |
-- F0 Impulse -> F1 ------\
--           \-> F2 -------+-> out
--                 \-> F0-/
--
-- Instructions
-- 
-- E1 selects screen.
-- 
-- Waveform Screen
-- 
-- E2 controls formant 1
-- E3 controls formant 2
-- No key: freq
-- K2: amp
-- K3: waves per formant
--
-- Modulator Screen
-- 
-- Use K2, K3 to cycle through
-- attributes, 2 at a time.
-- Use E2, E3 to modify them
--
-- Mod Matrix Screen
--
-- E1 to select modulation
-- E2 to modify it
-- K1 zeros the modulation
-- Hold K2 for fine control


music = require 'musicutil'

include 'lib/formlib'

engine.name="FormAndVoid"

PRESSURE_OPTIONS = {"none", "pressure", "amp", "pressure+amp"}

MOD_TARGETS = { 
    "fundamental", "fundamental amp", 
    "formant 1", "formant 1 amp", "formant 1 index", 
    "formant 2", "formant 2 amp", "formant 2 index",
}
MOD_SOURCES = {"env 1", "env 2", "lfo", "pressure"}

view = 1
env_edit = 0
matrix_edit = 0

active_notes = {}
for i=1,16,1 do
    active_notes[i] = {}
end


function midi_target(x)
  midi_device[target].event = nil
  target = x
  midi_device[target].event = process_midi
end

-- To do MPE:
-- * Keep track of which channels are MPE
-- * When we recieve a CC on an MPE channel, we look in the bindings for the main channel
-- * We see if that parameter has a set_mpe method, and call it for the appropriate voice.

count = 0
function process_midi(data)
  local d = midi.to_msg(data)
  local timbre = d.ch - params:get("first channel")
  if d.ch == params:get("main channel") then
      timbre = 0
  end
  if timbre < 0 or timbre > (params:get("mpe channels") - 1) then
      return
  end
  if d.type == "note_on" then
    -- This is a guard against stuck notes. If we see more than one note on the same
    -- channel and it isn't the main channel, and other channels are empty, it must be stuck.
    
    -- This is because MPE says to use an empty channel for new notes if such exists.
    
    if next(active_notes[d.ch]) ~= nil and d.ch ~= params:get("main channel") then
        local first = params:get("first channel")
        for i=first,first+params:get("mpe channels")-1,1 do
            if i ~= d.ch and next(active_notes[i]) == nil then
                for note, freq in pairs(active_notes[d.ch]) do
                    engine.noteOff(timbre, note)
                    count = count - 1
                    print("stuck off", timbre, note)
                end
                break
            end
        end
    end
    
    active_notes[d.ch][d.note] = music.note_num_to_freq(d.note)
    engine.noteOn(timbre, d.note, music.note_num_to_freq(d.note), d.vel/127)
    count = count + 1
    -- print("on", timbre, d.note, count)
  elseif d.type == "note_off" then
    active_notes[d.ch][d.note] = nil
    engine.noteOff(timbre, d.note)
    count = count - 1
    -- print("off", timbre, d.note, count)
  elseif d.type == "pitchbend" then
    local bend_st = (util.round(d.val / 2)) / 8192 * 2 -1 -- Convert to -1 to 1
    for note, freq in pairs(active_notes[d.ch]) do
        local new_freq = music.note_num_to_freq(note + bend_st*params:get("bend range"))
        engine.setNote(timbre, note, "freq", new_freq)
    end
  elseif d.type == "key_pressure" then
      if params:get("pressure") == 2 or params:get("pressure") == 4 then
        for note, freq in pairs(active_notes[d.ch]) do
            engine.setNote(timbre, note, "amp", d.val/127)
        end
      end
  elseif d.type == "channel_pressure" then
      if params:get("pressure") == 3 or params:get("pressure") == 4 then
          engine.set(timbre, "amp", d.val/127)
      end
      if params:get("pressure") == 2 or params:get("pressure") == 4 then
          engine.set(timbre, "pres", d.val/127)
      end
  elseif d.type == "cc" then
      local r = norns.pmap.rev[target][params:get("main channel")][d.cc]
      local v = d.val
      if r ~= nil and d.ch ~= params:get("main channel") then
        -- This code is borrowed and adapted from the parameter mapping code itself.
        local dd = norns.pmap.data[r]
        local t = params:t(r)
        local s = util.clamp(v, dd.in_lo, dd.in_hi)
        s = util.linlin(dd.in_lo, dd.in_hi, dd.out_lo, dd.out_hi, s)     
        local p = params:lookup_param(r)
        -- print("it is mapped for channel", params:get("main channel"))
        -- tab.print(p)
        if p ~= nil and p.set_mpe ~= nil then
            if t == params.tCONTROL or t == params.tTAPER then
                s = p:map_value(s)
                p:set_mpe(timbre, s)
            elseif t == params.tNUMBER or t == params.tOPTION then
                s = util.round(s)
                p:set_mpe(timbre, s)
            end
        end
      end      
  else
      print(d.type)      
  end
end

function draw_env(x, y, l, h, a, d, s, r, total)
    screen.move(x, y) -- bottom left
    local a_px = (l*a)/total
    local d_px = (l*d)/total
    local r_px = (l*r)/total
    local s_px = l - (a_px + d_px + r_px)
    local s_py = h*s
    screen.line_rel(a_px, -1*h)
    screen.line_rel(d_px, (h - s_py))
    screen.line_rel(s_px, 0)
    screen.line_rel(r_px, s_py)
    screen.stroke()
end

function draw_lfo(x, y, l, h, hz, width, total)
    screen.move(x, y)
    local wavelen = 1/hz
    local wave_px = (wavelen*l)/total
    local rise_px = width*wave_px
    local fall_px = (1-width)*wave_px
    local pos = x
    while pos < l + h do
        screen.line(pos + rise_px, y-h)
        pos = pos + rise_px
        screen.line(pos + fall_px, y)
        pos = pos + fall_px
    end
    screen.stroke()
end

function shape()
    local f1 = params:get("the formant 1")
    local f1_mod = params:get("the formant 1 modulator")
    local f1_index = params:get("the formant 1 index")
    local f2 = params:get("the formant 2")
    local len1 = params:get("the formant 1 waves")/f1
    local len2 = params:get("the formant 2 waves")/f2
    local window_len = math.max(len1, len2)
    local amp1 = (
        params:get("the formant 1 amp") + 
        params:get("the sustain 1")*params:get("the env 1 to formant 1 amp") + 
        params:get("the sustain 2")*params:get("the env 2 to formant 1 amp"))
    local amp2 = params:get("the formant 2 gain")*(
        params:get("the formant 2 amp") + 
        params:get("the sustain 1")*params:get("the env 1 to formant 2 amp") + 
        params:get("the sustain 2")*params:get("the env 2 to formant 2 amp"))
    local one = function(t)
        if t >= 0 and t <= len1 then
            local modulator = math.sin(2*math.pi*f1_mod*t)
            local window = (math.sin(math.pi*t/len1))^2
            return window*math.sin(2*math.pi*f1*t + 2*math.pi*f1_index*modulator)
        else
            return 0
        end
    end
    local two = function(t)
        if t >= 0 and t <= len2 then
            local window = (math.sin(math.pi*t/len2))^2
            return window*math.sin(2*math.pi*f2*t)
        else
            return 0
        end
    end
    local ret = {}
    local highest = -1000
    local lowest = 1000
    for i=0,128,1 do
        local t = window_len*(i-1)/128
        ret[i] = amp1*one(t) + amp2*two(t)
        if ret[i] > highest then highest = ret[i] end
        if ret[i] < lowest then lowest = ret[i] end
    end
    for i=0,128,1 do
        ret[i] = util.linlin(lowest, highest, 1, 63, ret[i])
    end
    ret.window_len = window_len
    return ret
end

function redraw()
    screen.clear()
    if view == 1 then
        local s = shape()
        screen.aa(1)
        screen.level(16)
        screen.move(0,s[0])
        for j=1,128,1 do
            screen.line(j, s[j])
        end
        screen.stroke()
        screen.move(105, 10)
        screen.text(util.round(s.window_len*1000).. " ms")
    elseif view == 2 then
        local a1 = params:get("the attack 1")
        local d1 = params:get("the decay 1")
        local s1 = params:get("the sustain 1")
        local r1 = params:get("the release 1")
        local a2 = params:get("the attack 2")
        local d2 = params:get("the decay 2")
        local s2 = params:get("the sustain 2")
        local r2 = params:get("the release 2")
        local adr1 = a1 + d1 + r1
        local adr2 = a2 + d2 + r2
        local total = 1.4*math.max(adr1, adr2)

        if math.floor(env_edit/2) == 0 then
            screen.level(16)
            screen.move(0, 20)
            if env_edit % 2 == 0 then
                screen.text("a,d")
            else
                screen.text("s,r")
            end
        else
            screen.level(8)
        end
        screen.move(0, 10)
        screen.text("env 1")        
        draw_env(28, 22, 99, 17, a1, d1, s1, r1, total)

        if math.floor(env_edit/2) == 1 then
            screen.level(16)
            screen.move(0, 40)
            if env_edit % 2 == 0 then
                screen.text("a,d")
            else
                screen.text("s,r")
            end
        else
            screen.level(8)
        end
        screen.move(0, 30)
        screen.text("env 2")
        draw_env(28, 41, 99, 17, a2, d2, s2, r2, total)

        if math.floor(env_edit/2) == 2 then
            screen.level(16)
            screen.move(0, 60)
            screen.text("f,w")
        else
            screen.level(8)
        end    
        screen.move(0, 50)
        screen.text("lfo")        
        draw_lfo(28, 61, 99, 17, params:get("the lfo freq"), params:get("the lfo width"), total)
    elseif view == 3 then
        local left = 16
        local top = 11
        screen.level(8)
        screen.move(0, 22)
        screen.text("e1")
        screen.move(0, 33)
        screen.text("e2")
        screen.move(0, 44)
        screen.text("lfo")
        screen.move(0, 55)
        screen.text("prs")
        for i, v in ipairs({"f0", "a0", "f1", "a1", "i1", "f2", "a2", "i2"}) do
            screen.move(left + (i-1) * (128-left)/8, 8)
            screen.text(v)
            screen.stroke()
        end
        for i, target in ipairs(MOD_TARGETS) do
            for j, source in ipairs(MOD_SOURCES) do
                if math.floor(matrix_edit/#MOD_SOURCES) == i-1 and (matrix_edit % #MOD_SOURCES) == j-1 then
                    screen.level(16)
                else
                    screen.level(2)
                end
                local name = "the ".. source .. " to " .. target
                local p = params:lookup_param(name)
                local normalized = p:get()/p.controlspec.maxval
                screen.move(left + (i-1) * (128-left)/8, top + (j*11))
                screen.line_rel(3, -normalized*8)
                screen.line_rel(3, normalized*8)
                screen.stroke()
            end
        end
    end
    screen.update()
end

k1 = 0
k2 = 0
k3 = 0

function key(n,z)
    if view == 1 then
        if n == 1 then
            k1 = z
        elseif n == 2 then
            k2 = z
        elseif n == 3 then
            k3 = z
        end
    elseif view == 2 then
        if z == 0 then return end
        if n == 2 then
            env_edit = util.wrap(env_edit - 1, 0, 4)
        elseif n == 3 then
            env_edit = util.wrap(env_edit + 1, 0, 4)
        end
        screen_dirty = true
    elseif view == 3 then
        if n == 3 then
            k3 = z
        elseif n == 2 then
            local targ = MOD_TARGETS[math.floor(matrix_edit/#MOD_SOURCES) + 1]
            local src = MOD_SOURCES[(matrix_edit % #MOD_SOURCES) + 1]
            local name = "the " .. src .. " to " .. targ
            local p = params:lookup_param(name)
            p:set(0)
        end
    end
end

function enc(n,d)
    local f = n - 1
    if n == 1 then
        view = util.wrap(view + 1, 1, 3)
    else
        if view == 1 then
            if k2 == 0 and k3 == 0 then
                local name = "the formant "..f
                local formant = params:lookup_param(name)
                formant:delta(d)
            elseif k2 == 1 and k3 == 0 then
                local name = "the formant "..f.." amp"
                local amp = params:lookup_param(name)
                amp:delta(d)
            elseif k2 == 0 and k3 == 1 then
                local name = "the formant "..f.." waves"
                local waves = params:lookup_param(name)
                waves:delta(d)
            end
        elseif view == 2 then
            local name
            local env = math.floor(env_edit/2) + 1
            if env == 1 or env == 2 then
                local parameter
                if env_edit % 2 == 0 then
                    -- a,d
                    if n == 2 then parameter = "attack" elseif n == 3 then parameter = "decay" end
                else
                    -- s,r
                    if n == 2 then parameter = "sustain" elseif n == 3 then parameter = "release" end
                end
                if parameter ~= nil then
                    name = "the " .. parameter .. " " .. env
                end
            else
                if n == 2 then
                    name = "the lfo freq"
                elseif n == 3 then
                    name = "the lfo width"
                end
            end
            if name ~= nil then
                local p = params:lookup_param(name)
                p:delta(d)
            end
        elseif view == 3 then
            if n == 2 then
                matrix_edit = (matrix_edit + d) % (#MOD_SOURCES * #MOD_TARGETS)
            elseif n == 3 then
                local targ = MOD_TARGETS[math.floor(matrix_edit/#MOD_SOURCES) + 1]
                local src = MOD_SOURCES[(matrix_edit % #MOD_SOURCES) + 1]
                local name = "the " .. src .. " to " .. targ
                local p = params:lookup_param(name)
                if k3 == 1 then
                    p:set_raw(p.raw + 0.1 * d * p:get_delta())
                else
                    p:delta(d)
                end
            end
        end
    end
    screen_dirty = true  
end

function init()
    midi_device = {} -- container for connected midi devices
    midi_device_names = {}
    target = 1

    for i = 1,#midi.vports do -- query all ports
        midi_device[i] = midi.connect(i) -- connect each device
        local full_name = 
        table.insert(midi_device_names,"port "..i..": "..util.trim_string_to_width(midi_device[i].name,40)) -- register its name
    end
    params:add_group("midi", 6)
    params:add_option("midi target", "midi target",midi_device_names,1,false)
    params:set_action("midi target", midi_target)  
    params:add_number("main channel", "main channel", 1, 15, 1, nil, nil, false)
    params:add_number("first channel", "first channel", 1, 15, 2, nil, nil, false)
    params:add_number("mpe channels", "mpe channels", 1, 8, 7, nil, nil, false)
    params:add_number("bend range", "bend range", 1, 24, 12, nil, nil, false)
    params:add_option("pressure", "pressure", PRESSURE_OPTIONS, 4)
    set_up_timbre(-1, "the")
    params:read(1)
    params:bang()
    screen_redraw_clock = clock.run(
    function()
      while true do
        clock.sleep(1/10) 
        if screen_dirty == true then
          redraw()
          screen_dirty = false
        end
      end
    end
    )
    screen_dirty = true
end