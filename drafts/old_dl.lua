-- scriptname: DL first script
-- v1.0.0 @davidlovell

-- TO DO
-- level doesn't do anything
-- on doesn't do anything

engine.name = 'PolyPerc'
MusicUtil = require "musicutil"
Util = require "lib.util"

global = {}
global.midiroot = 60
global.scales = {
    lydian = MusicUtil.generate_scale_of_length(global.midiroot, "Lydian", 7)
  , mixolydian = MusicUtil.generate_scale_of_length(global.midiroot, "Mixolydian", 7)
  , pentamaj = MusicUtil.generate_scale_of_length(global.midiroot, "Major Pentatonic", 5)

}
global.scale = global.scales.mixolydian
global.negharm = false
global.reset = false

function init()
  -- initialization
  clock.run(clock_event)
  on_init()
end

function key(n,z)
  -- key actions: n = number, z = state
end

function enc(n,d)
  -- encoder actions: n = number, d = delta
  if n == 2 then
    print(d)
  end
end

function redraw()
  -- screen redraw
end

function cleanup()
  -- deinitialization
end

Voice = {}
function Voice:new(on, level, octave, transpose, degree, fn)
  local o = {}
  setmetatable(o, self)
  self.__index = self

  o.s = {} -- container for sequencers

  o.synth = function(freq)
    if o.on then return engine.hz(freq) end
  end

  o.fn = fn or function()
    return o.synth(new_note(o))
  end

  o.scale = global.scale
  o.negharm = global.negharm

  o.on = on or false
  o.level = level or 1 --  to do

  o.degree = degree or 1
  o.transpose = transpose or 0
  o.octave = octave or 0

  o.input_on = true
  o.input_level = 3 -- to do
  o.input_octave = 0
  o.input_transpose = 0
  o.input_degree = 1

  o.wrap_octave = false -- to do

  return o
end

Sequencer = {}
function Sequencer:new(sequence, division, step, behaviour, fn)
  local o = {}
  setmetatable(o, self)
  self.__index = self

  o.reset = false

  o.fn = fn or nil
  o.sequencer = new_sequencer(o.fn)

  o.sequence = sequence or {1,2,3,4,5,6,7}
  o.division = division or 1
  o.step = step or 1
  o.behaviour = behaviour or "next"

  o.input_division = 1
  o.input_step = 1

  return o
end

function new_sequencer(fn)
  local divcount = 0
  local stepcount = 0
  return
    function(s)
      local reset = s.reset or global.reset
      local division = s.division * s.input_division
 			local step = s.step * s.input_step

 			divcount = reset and 1 or (divcount % division + 1)
 			stepcount = reset and 0 or stepcount

      if divcount == 1 then

  			if s.behaviour == "next" then
  				stepcount = ((stepcount + step) - 1) % #s.sequence + 1
  			elseif s.behaviour == "prev" then
  				stepcount = ((stepcount - step) - 1) % #s.sequence + 1
  			elseif s.behaviour == "drunk" then
  				stepcount = ((stepcount + step * math.random(-1, 1)) - 1) % #s.sequence + 1
  				stepcount = Util.clamp(stepcount, 1, #s.sequence)
  			elseif s.behaviour == "random" then
  				stepcount = math.random(1, #s.sequence)
  			end

        return fn ~= nil and fn(s.sequence[stepcount]) or s.sequence[stepcount], false

      end

    end
end

function new_note(voice)
  local degree = (voice.degree - 1) + (voice.input_degree - 1)
  local transpose = voice.transpose + voice.input_transpose
  local octave = (voice.octave + voice.input_octave + math.floor(degree/#voice.scale)) * 12
  local note_index = degree % #voice.scale + 1

  local note = voice.scale[note_index] + transpose
  local negative = (7 - note) % 12 + global.midiroot
        note = (global.negharm or voice.negharm) and negative or note

  return MusicUtil.note_num_to_freq(note + octave)
end

--edit below here
function clock_event()
  while true do
    clock.sync(1/8)
    on_clock()
  end
end

function on_init()
  v = {}
  v[1] = Voice:new(true, 1, 0, 0, 1)
  v[1].s[1] = Sequencer:new({1,1,3,2,1,1,8}, 1, 1, "next")
  v[1].s[2] = Sequencer:new({1,3,5,8}, 2, 1, "next"
    , function(note_index)
        v[1].s[2].input_division = v[1].s[1].sequencer(v[1].s[1])
        engine.release(v[1].s[2].input_division/4)
        v[1].input_degree = note_index
        v[1].degree = 1
        v[1].fn()
        clock.sleep(math.random()/10)
        v[1].degree = math.random(3,5)
        v[1].fn()
      end
    )

  v[2] = Voice:new(true, 1, -1, 0, 1)
  v[2].s[1] = Sequencer:new({7,1}, 1, 1, "next")
  v[2].s[2] = Sequencer:new({1,3}, 4, 3, "prev"
    , function(note_index)
        v[2].s[2].input_division = v[2].s[1].sequencer(v[2].s[1])
        engine.release(v[2].s[2].input_division)
        v[2].s[2].sequence[2] = math.random(4,5)
        v[2].input_degree = note_index
        v[2].fn()
      end
    )

  v[3] = Voice:new(true, 1, 1, 0, 1)
  v[3].s[1] = Sequencer:new({1,1,2,2,8}, 1, 1, "next")
  v[3].s[2] = Sequencer:new({1,4,6,5}, 3, 1, "next"
    , function(note_index)
        v[3].s[2].input_division = v[3].s[1].sequencer(v[3].s[1])
        engine.release(v[3].s[2].input_division)
        v[3].input_degree = note_index
        v[3].fn()
      end
    )
end

function on_clock()
  v[1].note = v[1].s[2].sequencer(v[1].s[2])
  v[2].note = v[2].s[2].sequencer(v[2].s[2])
  v[3].note = v[3].s[2].sequencer(v[3].s[2])
end
