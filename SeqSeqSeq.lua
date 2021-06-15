--- SeqSeqSeq

ionian = {0,2,4,5,7,9,11}
dorian = {0,2,3,5,7,9,10}
phrygian = {0,1,3,5,7,8,10}
lydian = {0,2,4,6,7,9,11}
mixolydian = {0,2,4,5,7,9,10}
aeolian = {0,2,3,5,7,8,10}

divs = {
    x2 = {1,2,4,8,16,32,64}
  , odd = {1,3,5,7,9}
  , even = {1,2,4,6,8,10}
}

CV_SCALE = lydian
CV_OCTAVE = 0
CV_DEGREE = 1

global = {
    bpm = 120
  , division = 1
  , count = 256
  , reset = false

  , on = true
  , level = 1
  , octave = 0
  , degree = 1
  , transpose = 0

  , scale = mixolydian
  , negharm = false
}

txi = {param = {}, input = {}}

Voice = {}
function Voice:new(on, ext_octave, ext_degree, level, octave, degree, transpose, synth)
  local o = {}
  setmetatable(o, self)
  self.__index = self

  o.seq = {}
  o.new_seq = function(self, id, on, sequence, division, step, behaviour, action)
    action = (action and function (val) self:play_voice(val) end) or (type(action) == 'function' and action)
    self.seq[id] = Seq:new(on, sequence, division, step, behaviour, action)
  end

  o.play_seq = function(self, id)
    if id == nil then
      for k, v in pairs(self.seq) do
        local play = self.seq[k].action and self.seq[k]:play_seq()
      end
    else
      return self.seq[id]:play_seq()
    end
  end

  o.play_voice = function(self, val)
    self:action(val)

    local on = (global.on == nil or global.on) and self.on and self.mod.on
    local note = self:new_note()
    local level = self.level * self.mod.level * global.level

    return on and self.synth(note, level)
  end

  o.action = function(self, val)
  end

  o.new_note = function(self)
    local s = self

    local scale = global.scale == nil and s.scale or global.scale
    local negharm = global.negharm == nil and s.negharm or global.negharm

    local cv_degree = s.ext_degree and CV_DEGREE or 1
    local cv_octave = s.ext_octave and CV_OCTAVE or 0

    local transpose = s.transpose + s.mod.transpose + global.transpose
    local degree = (s.degree - 1) + (s.mod.degree - 1) + (cv_degree - 1) + (global.degree - 1)
    local octave = s.octave + s.mod.octave + cv_octave + math.floor(degree / #scale) + global.octave
    local index = degree % #scale + 1

    local note = scale[index] + transpose
    local negative = (7 - note) % 12
  	note = negharm and negative or note

    return note / 12 + octave
  end

  o.synth = synth or function(note, level)
    ii.jf.play_note(note, level)
  end

  o.ext_octave = ext_octave and true or false
  o.ext_degree = ext_degree and true or false

  o.scale = global.scale == nil and CV_SCALE or global.scale
  o.negharm = global.negharm or false

  o.on = on and true or false
  o.level = level or 1
  o.octave = octave or 0
  o.degree = degree or 1
  o.transpose = transpose or 0

  o.mod = {on = true, level = 1, octave = 0, degree = 1, transpose = 0}

  return o
end

Seq = {}
function Seq:new(on, sequence, division, step, behaviour, action)
  local o = {}
  setmetatable(o, self)
  self.__index = self

  o.reset = false

  o.divcount = 0
  o.stepcount = 0
  o.play_seq = function(self)
    local s = self

    local on = s.on and s.mod.on
    local reset = s.reset or global.reset
    local division = s.division * s.mod.division
    local step = s.step * s.mod.step

    s.divcount = reset and 1 or (s.divcount % division + 1)
    s.stepcount = reset and 0 or s.stepcount

    local next = on and (s.divcount == 1)

    if next then
      if s.behaviour == 'next' then
        s.stepcount = ((s.stepcount + step) - 1) % #s.sequence + 1
      elseif s.behaviour == 'prev' then
        s.stepcount = ((s.stepcount - step) - 1) % #s.sequence + 1
      elseif s.behaviour == 'drunk' then
        s.stepcount = ((s.stepcount + step * math.random(-1, 1)) - 1) % #s.sequence + 1
        s.stepcount = clamper(s.stepcount, 1, #s.sequence)
      elseif s.behaviour == 'random' then
        s.stepcount = math.random(1, #s.sequence)
      end
    end

    s.reset = false

    local val = s.sequence[s.stepcount]
    return (next and s.action ~= nil) and s.action(val) or val
  end

  o.action = action or nil

  o.sequence = sequence or {1,2,3,4}
  o.behaviour = behaviour or 'next'

  o.on = on or true
  o.division = division or 1
  o.step = step or 1

  o.mod = {on = true, division = 1, step = 1}

  return o
end

function new_divider(f)
  local divcount = 0
  return
    function(division)
      divcount = (global.reset and 1) or (division == 0 and 0) or (divcount % division + 1)
      return divcount == 1 and f()
    end
end

function linlin(input, range_min, range_max, output_min, output_max)
  return (input - range_min) * (output_max - output_min) / (range_max - range_min) + output_min
end

function round(n)
  return n % 1 >= 0.5 and math.ceil(n) or math.floor(n)
end

function clamper(input, min, max)
  return math.min(math.max(min, input), max)
end

function selector(input, table, range_min, range_max, min, max)
  min = min or 1
  max = max or #table
  return table[ clamper( round( linlin( input, range_min, range_max, min, max ) ), min, max ) ]
end

function init()
  input[1].mode('scale', CV_SCALE)
  input[2].mode('change', 4, 0.1, 'rising')

  metro[1].event = on_clock
  metro[1].time = 60/global.bpm
  metro[1]:start()

  ii.wsyn.ar_mode(1)
  ii.jf.mode(1)

  txi_getter()

  clock_divider = new_divider(function() output[1](pulse(0.01)) on_division() end)
  clock_reset = new_divider(function() global.reset = true end)
  trigger_reset = new_divider(function() global.reset = true end)

  -- declare voices/sequencers/actions, e.g.
  -- v = {}
  -- v.trig1 = Voice:new(true, true, true, 1, 0, 1, 0)
  --
  -- v.trig2 = Voice:new(true, true, true, 1, 0, 5, 0)
  --
  -- v.trig3 = Voice:new(true, true, true, 2, 1, 1, 0)
  -- v.trig3:new_seq(1, true, {1,3,5}, 1, 1, 'next', true)
  -- v.trig3:new_seq(2, true, {2,3,3}, 1, 1, 'next')
  -- function v.trig3:action(val)
  --   self.mod.degree = val
  --   self.seq[1].mod.division = self:play_seq(2)
  -- end
  --
  -- v.div1 = Voice:new(true, false, false, 0.5, 1, 1, 0, function(note, level) ii.wsyn.play_note(note, level) end)
  -- v.div1:new_seq(1, true, {1,2,3,4,5,6,7}, 1, 2, 'next', true)
  -- v.div1:new_seq(2, true, {1,3,5}, 4, 1, 'next')
  -- v.div1:new_seq(3, true, {2,3,1}, 1, 1, 'next')
  -- function v.div1:action(val)
  --   self.mod.degree = val + self:play_seq(2)
  --   self.seq[1].mod.division = self:play_seq(3)
  -- end
  --
  -- v.div2 = Voice:new(true, false, true, 1.5, -2, 1, 0, function(note, level) ii.jf.play_voice(1, note, level) end)
  -- v.div2:new_seq(1, true, {4,3,1}, 1, 1, 'next', true)
  -- v.div2:new_seq(2, true, {1,1,1}, 1, 1, 'next')
  -- function v.div2:action(val)
  --   self.seq[1].mod.division = val * selector(txi.param[3], divs.x2, 0, 10)
  --   self.seq[1].sequence = selector(txi.param[4], {{4,3,1}, {2,1/2,1/2,1}}, 0, 10)
  --   self.seq[2].sequence[3] = math.random(3,4)
  --   self.mod.degree = self:play_seq(2)
  -- end

end

function txi_getter()
  if txi then
    for i = 1, 4 do
      ii.txi.get('param', i)
      ii.txi.get('in', i)
    end
  end
end

ii.txi.event = function(e, val)
  e.name = e.name == 'in' and 'input' or e.name
  txi[e.name][e.arg] = val
end

input[1].scale = function(s)
  CV_OCTAVE = s.octave
  CV_DEGREE = s.index
end

input[2].change = function()
  trigger_reset(global.count)

  -- voices/seqeuncers to play on trigger to crow input[2]
  -- v.trig1:play_voice()
  -- v.trig2:play_voice()
  -- v.trig3:play_seq()

  global.reset = false
end

function on_clock()
  txi_getter()
  clock_reset(global.count)

  -- variables to be set every clock pulse, e.g.
  -- global.bpm = linlin(txi.input[1], 0, 5, 10, 3000)
  -- global.division = selector(txi.input[2], divs.x2, 0, 4)
  -- global.negharm = selector(txi.input[3], {false,true}, 0, 4)

  metro[1].time = 60/global.bpm
  clock_divider(global.division)
  global.reset = false
end

function on_division()
  -- voices/sequencers to play on every clock division
  -- v.div1:play_seq()
  -- v.div2:play_seq()
end
