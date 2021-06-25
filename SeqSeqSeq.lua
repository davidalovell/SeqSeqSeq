--- SeqSeqSeq
CV_SCALE = lydian

ionian = {0,2,4,5,7,9,11}
dorian = {0,2,3,5,7,9,10}
phrygian = {0,1,3,5,7,8,10}
lydian = {0,2,4,6,7,9,11}
mixolydian = {0,2,4,5,7,9,10}
aeolian = {0,2,3,5,7,8,10}

div = {
    x2 = {1,2,4,8,16,32,64}
  , odd = {1,3,5,7,9}
  , even = {1,2,4,6,8,10}
}

global = {
    bpm = 120
  , division = 1
  , reset_count = 0
  , reset = false

  , on = true
  , level = 1
  , octave = 0
  , degree = 1
  , transpose = 0

  , scale = mixolydian -- nil
  , neg_harm = false -- nil
}

txi = {param = {}, input = {}} -- requires TXi

Voice = {}
function Voice:new(on, ext_octave, ext_degree, level, octave, degree, transpose, synth)
  local o = {}
  setmetatable(o, self)
  self.__index = self

  o.on = on and true or false
  o.ext_octave = ext_octave and true or false
  o.ext_degree = ext_degree and true or false
  o.level = level or 1
  o.octave = octave or 0
  o.degree = degree or 1
  o.transpose = transpose or 0
  o.synth = synth or function(note, level) ii.jf.play_note(note, level) end -- requires JF

  o.scale = global.scale == nil and CV_SCALE or global.scale
  o.neg_harm = global.neg_harm or false

  o.mod = {on = true, level = 1, octave = 0, degree = 1, transpose = 0}

  o.seq = {}
  o.new_seq = function(self, id, on, sequence, division, step, behaviour, action)
    action = (action and function(val) self:play_voice(val) end) or (type(action) == 'function' and action)
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
    self:play_note()
  end

  o.action = function(self, val) end

  o.play_note = function(self)
    local on = (global.on == nil or global.on) and self.on and self.mod.on
    local note = self:new_note()
    local level = self.level * self.mod.level * global.level
    return on and self.synth(note, level)
  end

  o.new_note = function(self)
    local s = self

    local scale = global.scale == nil and s.scale or global.scale
    local neg_harm = global.neg_harm == nil and s.neg_harm or global.neg_harm

    local cv_degree = s.ext_degree and global.cv_degree or 1
    local cv_octave = s.ext_octave and global.cv_octave or 0

    local transpose = s.transpose + s.mod.transpose + global.transpose
    local degree = (s.degree - 1) + (s.mod.degree - 1) + (cv_degree - 1) + (global.degree - 1)
    local octave = s.octave + s.mod.octave + cv_octave + math.floor(degree / #scale) + global.octave
    local index = degree % #scale + 1

    local note = scale[index] + transpose
    local neg = (7 - note) % 12
    note = neg_harm and neg or note

    return note / 12 + octave
  end

  return o
end

Seq = {}
function Seq:new(on, sequence, division, step, behaviour, action)
  local o = {}
  setmetatable(o, self)
  self.__index = self

  o.on = on or true
  o.sequence = sequence or {1,2,3,4}
  o.division = division or 1
  o.step = step or 1
  o.behaviour = behaviour or 'next'
  o.action = action or nil

  o.mod = {on = true, division = 1, step = 1}

  o.divcount = 0
  o.stepcount = 0
  o.reset = false

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
        s.stepcount = clamper( ( (s.stepcount + step * math.random(-1, 1) ) - 1 ) % #s.sequence + 1, 1, #s.sequence )
      elseif s.behaviour == 'random' then
        s.stepcount = math.random(1, #s.sequence)
      end
    end

    s.reset = false
    local val = s.sequence[s.stepcount]
    return (next and s.action ~= nil) and s.action(val) or val
  end

  return o
end

function divider(f)
  local divcount = 0
  return
    function(division)
      divcount = (global.reset and 1) or (division == 0 and 0) or (divcount % division + 1)
      return divcount == 1 and f()
    end
end

function selector(input, table, range_min, range_max, min, max)
  min = min or 1
  max = max or #table
  return table[ clamper( round( linlin( input, range_min, range_max, min, max ) ), min, max ) ]
end

function linlin(input, range_min, range_max, output_min, output_max)
  return (input - range_min) * (output_max - output_min) / (range_max - range_min) + output_min
end

function clamper(input, min, max)
  return math.min( math.max( min, input ), max )
end

function round(n)
  return n % 1 >= 0.5 and math.ceil(n) or math.floor(n)
end

function init()
  input[1].mode('scale', CV_SCALE)
  input[2].mode('change', 4, 0.1, 'rising')

  metro[1].event = on_clock
  metro[1].time = 60/global.bpm
  metro[1]:start()

  ii.jf.mode(1)
  ii.wsyn.ar_mode(1)

  txi_getter()

  clock_reset = divider(function() global.reset = true end)
  trigger_reset = divider(function() global.reset = true end)
  clock_divider = divider(function() output[1](pulse(0.01)) on_division() end)

  -- declare voices/sequencers/actions

  --
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
  global.cv_octave = s.octave
  global.cv_degree = s.index
end

input[2].change = function()
  trigger_reset(global.reset_count)

  -- voices/seqeuncers to play on trigger to crow input[2]

  --
  global.reset = false
end

function on_clock()
  txi_getter()

  -- variables to be set on clock, e.g.

  --
  metro[1].time = 60/global.bpm

  clock_reset(global.reset_count)
  clock_divider(global.division)
  global.reset = false
end

function on_division()
  -- voices/sequencers to play on every clock division

  --
end
