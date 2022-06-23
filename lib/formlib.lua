function set_up_timbre_attr(sect, timbre_n, name, key, cspec)
    params:add_control(sect .. " " .. name, name, cspec)
    if timbre_n < 0 then
        params:set_action(sect .. " " .. name, function(val)
            engine.setAll(key, val)
            screen_dirty = true
        end)
        local p = params:lookup_param(sect .. " " .. name)
        function p:set_mpe(timbre, val)
            engine.set(timbre, key, val)
        end
    else
        params:set_action(sect .. " " .. name, function(val)
            engine.set(timbre_n, key, val)
            screen_dirty = true
        end)        
    end

end

function set_up_timbre(n, sect)
    local num_params = 47
    if n == nil then
        n = 0
    end
    if n < 0 then
        num_params = num_params + 2
    end
    if sect == nil then
        sect = "chord"
    end
    params:add_group(sect .. " timbre", num_params)
    set_up_timbre_attr(sect, n, "fundamental amp", "f0Amp", controlspec.new(0, 1, 'lin', 0, 0.4))
    params:add_separator("formants")
    local f1 = controlspec.MIDFREQ:copy()
    f1.default = 700
    set_up_timbre_attr(sect, n, "formant 1", "f1", f1)
    set_up_timbre_attr(sect, n, "formant 1 modulator", "f1Modulator", f1)
    set_up_timbre_attr(sect, n, "formant 1 index", "f1Index", controlspec.new(0, 2, 'lin', 0, 0))
    set_up_timbre_attr(sect, n, "formant 1 amp", "f1Amp", controlspec.new(0, 1, 'lin', 0, 0.5))
    set_up_timbre_attr(sect, n, "formant 1 waves", "f1Res", controlspec.new(1, 8, 'lin', 0, 3))
    
    local f2 = controlspec.MIDFREQ:copy()
    f2.default = 1100
    set_up_timbre_attr(sect, n, "formant 2", "f2", f2)
    set_up_timbre_attr(sect, n, "formant 2 index", "f2Index", controlspec.new(0, 2, 'lin', 0, 0))
    set_up_timbre_attr(sect, n, "formant 2 amp", "f2Amp", controlspec.new(0, 1, 'lin', 0, 0.2))
    set_up_timbre_attr(sect, n, "formant 2 gain", "f2Gain", controlspec.new(0, 1, 'lin', 0, 1))
    set_up_timbre_attr(sect, n, "formant 2 waves", "f2Res", controlspec.new(1, 8, 'lin', 0, 4))
    params:add_separator("modulations")
    set_up_timbre_attr(sect, n, "attack 1", "a1", controlspec.new(0.001, 4, 'exp', 0, 0.5))
    set_up_timbre_attr(sect, n, "decay 1", "d1", controlspec.new(0.001, 4, 'exp', 0, 0.4))
    set_up_timbre_attr(sect, n, "sustain 1", "s1", controlspec.new(0, 1, 'lin', 0, 0.9))
    set_up_timbre_attr(sect, n, "release 1", "r1", controlspec.new(0.001, 4, 'exp', 0, 2))
    set_up_timbre_attr(sect, n, "attack 2", "a2", controlspec.new(0.001, 4, 'exp', 0, 2))
    set_up_timbre_attr(sect, n, "decay 2", "d2", controlspec.new(0.001, 4, 'exp', 0, 1))
    set_up_timbre_attr(sect, n, "sustain 2", "s2", controlspec.new(0, 1, 'lin', 0, 0.5))
    set_up_timbre_attr(sect, n, "release 2", "r2", controlspec.new(0.001, 4, 'exp', 0, 0.5))
    local lowfreq = controlspec.LOFREQ:copy()
    lowfreq.default = 5
    lowfreq.minval = 0.05
    set_up_timbre_attr(sect, n, "lfo freq", "lfoFreq", lowfreq)
    params:add_separator("matrix")
    set_up_timbre_attr(sect, n, "env 1 to fundamental", "e1F0", controlspec.new(-0.8, 2, 'lin', 0, 0.0))
    set_up_timbre_attr(sect, n, "env 1 to fundamental amp", "e1F0Amp", controlspec.UNIPOLAR)
    set_up_timbre_attr(sect, n, "env 1 to formant 1", "e1F1", controlspec.new(-0.8, 2, 'lin', 0, 0.0))
    set_up_timbre_attr(sect, n, "env 1 to formant 1 amp", "e1F1Amp", controlspec.UNIPOLAR)
    set_up_timbre_attr(sect, n, "env 1 to formant 1 index", "e1F1Index", controlspec.UNIPOLAR)
    set_up_timbre_attr(sect, n, "env 1 to formant 2", "e1F2", controlspec.new(-0.8, 2, 'lin', 0, 0.0))
    set_up_timbre_attr(sect, n, "env 1 to formant 2 amp", "e1F2Amp", controlspec.new(0, 1, 'lin', 0, 0.0))
    set_up_timbre_attr(sect, n, "env 1 to formant 2 index", "e1F2Index", controlspec.new(0, 1, 'lin', 0, 0.0))
    
    set_up_timbre_attr(sect, n, "env 2 to fundamental", "e2F0", controlspec.new(-0.8, 2, 'lin', 0, 0.0))
    set_up_timbre_attr(sect, n, "env 2 to fundamental amp", "e2F0Amp", controlspec.UNIPOLAR)
    set_up_timbre_attr(sect, n, "env 2 to formant 1", "e2F1", controlspec.new(-0.8, 2, 'lin', 0, 0.0))
    set_up_timbre_attr(sect, n, "env 2 to formant 1 amp", "e2F1Amp", controlspec.UNIPOLAR)
    set_up_timbre_attr(sect, n, "env 2 to formant 1 index", "e2F1Index", controlspec.UNIPOLAR)
    set_up_timbre_attr(sect, n, "env 2 to formant 2", "e2F2", controlspec.new(-0.8, 2, 'lin', 0, 0.0))
    set_up_timbre_attr(sect, n, "env 2 to formant 2 amp", "e2F2Amp", controlspec.new(0, 1, 'lin', 0, 0.3))  
    set_up_timbre_attr(sect, n, "env 2 to formant 2 index", "e2F2Index", controlspec.new(0, 1, 'lin', 0, 0.0))   
    
    set_up_timbre_attr(sect, n, "lfo to fundamental", "lfoF0", controlspec.new(-0.8, 2, 'lin', 0, 0.0))
    set_up_timbre_attr(sect, n, "lfo to fundamental amp", "lfoF0Amp", controlspec.new(-0.8, 1, 'lin', 0, 0.0))
    set_up_timbre_attr(sect, n, "lfo to formant 1", "lfoF1", controlspec.new(-0.8, 2, 'lin', 0, 0.0))
    set_up_timbre_attr(sect, n, "lfo to formant 1 amp", "lfoF1Amp", controlspec.new(-0.8, 1, 'lin', 0, 0.0))
    set_up_timbre_attr(sect, n, "lfo to formant 1 index", "lfoF1index", controlspec.new(-0.8, 1, 'lin', 0, 0.0))
    set_up_timbre_attr(sect, n, "lfo to formant 2", "lfoF2", controlspec.new(-0.8, 2, 'lin', 0, 0))
    set_up_timbre_attr(sect, n, "lfo to formant 2 amp", "lfoF2Amp", controlspec.new(-0.8, 1, 'lin', 0, 0.1))
    set_up_timbre_attr(sect, n, "lfo to formant 2 index", "lfoF2Index", controlspec.new(-0.8, 1, 'lin', 0, 0.0))
    if n < 0 then
        params:add_separator("quality")
        params:add_option(sect .. " antialias", "antialias", {"off", "on"}, 1)
        params:set_action(sect .. " antialias", function (aa) 
            engine.setAll("model", aa)
        end)
    end

end