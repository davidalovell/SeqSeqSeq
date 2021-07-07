--- SeqSeqSeq

lydian = {0,2,4,6,7,9,11}
dorian = {0,2,3,5,7,9,10}
phrygian = {0,1,3,5,7,8,10}
lydian = {0,2,4,6,7,9,11}
mixolydian = {0,2,4,5,7,9,10}
aeolian = {0,2,3,5,7,8,10}

div = {
  x2 = {1,2,4,8,16,32,64},
  odd = {1,3,5,7,9},
  even = {1,2,4,6,8,10}
}

CV_scale = lydian
CV_degree = 1
CV_octave = 0

bpm = 60

txi = {param = {}, input = {}}

Voice = {}
function Voice:new(args)
  local o = setmetatable( {}, {__index = Voice} )
  local t = args or {}

  o.on = t.on == nil and true or t.on
  o.level = t.level == nil and 1 or t.level
  o.octave = t.octave == nil and 0 or t.octave
  o.degree = t.degree == nil and 1 or t.degree
  o.transpose = t.transpose == nil and 0 or t.transpose
  o.scale = t.scale == nil and CV_scale or t.scale
  o.neg_harm = t.neg_harm == nil and false or t.neg_harm
  o.synth = t.synth == nil and function(note, level) ii.jf.play_note(note, level) end or t.synth
  o.action = t.action == nil and function(self, val) end or t.action

  o.mod = {on = true, level = 1, octave = 0, degree = 1, transpose = 0}

  o.seq = {}

  return o
end

function Voice:_on() return self.on and self.mod.on end
function Voice:_level() return self.level * self.mod.level end
function Voice:_octave() return self.octave + self.mod.octave + math.floor(self:_degree() / #self.scale) end
function Voice:_degree() return (self.degree - 1) + (self.mod.degree - 1) end
function Voice:_transpose() return self.transpose + self.mod.transpose end

function Voice:_pos() return self.scale[ self:_degree() % #self.scale + 1 ] + self:_transpose() end
function Voice:_neg() return ( 7 - self:_pos() ) % 12 end
function Voice:_note() return ( self.neg_harm and self:_neg() or self:_pos() ) / 12 + self:_octave() end

function Voice:play_note() return self:_on() and self.synth( self:_note(), self:_level() ) end

function Voice:play_voice(val)
  self:action(val)
  self:play_note()
end

function Voice:new_seq(args)
  local t = args or {}
  t.action = type(t.action) == 'function' and t.action or t.action and function(val) self:play_voice(val) end
  self.seq[ t.id == nil and #self.seq + 1 or t.id ] = Seq:new(t)
end

function Voice:play_seq(id)
  if id == nil then
    for k, v in pairs(self.seq) do
      local play = self.seq[k].action and self.seq[k]:play_seq()
    end
  else
    return self.seq[id]:play_seq()
  end
end

function Voice:reset()
  for k, v in pairs(self.seq) do
    self.seq[k]:reset()
  end
end

Seq = {}
function Seq:new(args)
  local o = setmetatable( {}, {__index = Seq} )
  local t = args or {}

  o.on = t.on == nil and true or t.on
  o.division = t.division == nil and 1 or t.division
  o.step = t.step == nil and 1 or t.step
  o.sequence = t.sequence == nil and {1} or t.sequence
  o.behaviour = t.behaviour == nil and 'next' or t.behaviour
  o.action = t.action == nil and nil or t.action

  o.mod = {on = true, division = 1, step = 1}

  o.div_count = 0
  o.step_count = 0

  return o
end

function Seq:_on() return self.on and self.mod.on end
function Seq:_division() return self.division * self.mod.division end
function Seq:_step() return self.step * self.mod.step end

function Seq:_div_adv() return self:_on() and self.div_count % self:_division() + 1 end
function Seq:_step_adv() return self:_on() and self.div_count == 1 and self:_behaviour() end

function Seq:_behaviour()
  return self.behaviour == 'next' and ( (self.step_count + self.step) - 1 ) % #self.sequence + 1
    or self.behaviour == 'prev' and ( (self.step_count - self.step) - 1 ) % #self.sequence + 1
    or self.behaviour == 'drunk' and clamper( ( (self.step_count + self.step * math.random(-1, 1) ) - 1 ) % #self.sequence + 1, 1, #self.sequence )
    or self.behaviour == 'random' and math.random(1, #self.sequence)
    or self.step_count
end

function Seq:_val() return self.sequence[self.step_count] end

function Seq:play_seq()
  self.div_count = self:_div_adv() or self.div_count
  self.step_count = self:_step_adv() or self.step_count
  return self:_step_adv() and self.action ~= nil and self.action( self:_val() ) or self:_val()
end

function Seq:reset()
  self.div_count = 0
  self.step_count = 0
end

function round(input)
  return input % 1 >= 0.5 and math.ceil(input) or math.floor(input)
end

function clamper(input, min, max)
  return math.min( math.max( min, input ), max )
end

function linlin(input, range_min, range_max, output_min, output_max)
  return (input - range_min) * (output_max - output_min) / (range_max - range_min) + output_min
end

function selector(input, table, range_min, range_max, min, max)
  min = min or 1
  max = max or #table
  return table[ clamper( round( linlin( input, range_min, range_max, min, max ) ), min, max ) ]
end

function set(names, property, val)
  for k, v in pairs(names) do
    _G[v][property] = val
  end
end

function act(method, names)
  for k, v in pairs(names) do
    _G[v][method](_G[v])
  end
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
  txi[ e.name == 'in' and 'input' or e.name ][ e.arg ] = val
end

function init()
  txi_getter()

  input[1]{mode = 'scale', notes = CV_scale,
    scale = function(s)
      CV_octave = s.octave
      CV_degree = s.index
    end
  }

  input[2]{mode = 'change', threshold = 4, direction = 'rising',
    change = function()
      act('play_voice', trg_voices)
    end
  }

  clk = metro.init{time = 60/bpm,
    event = function()
      txi_getter()

      bpm = linlin(txi.input[1], 0, 5, 10, 3000)
      clk_divider.division = selector(txi.input[2], div.x2, 0, 4)
      set( voices, 'neg_harm', selector(txi.input[3], {false,true}, 0, 4) )

      clk.time = 60/bpm
      clk_reset:play_seq()
      clk_divider:play_seq()
    end
  }

  clk_reset = Seq:new{division = 256,
    action = function()
      clk_divider:reset()
      act('reset', voices)
    end
  }

  clk_divider = Seq:new{
    action = function()
      output[1](pulse(0.01))
      act('play_seq', clk_voices)
    end
  }

  ii.jf.mode(1)
  ii.wsyn.ar_mode(1)

  voices = {'one', 'two', 'three', 'four', 'bass'}
  clk_voices = {voices[1], voices[2], voices[3], voices[4]}
  trg_voices = {voices[5]}

  one = Voice:new{
    action = function(self, val)
      self.mod.degree = (CV_degree - 1) + val
      self.seq[1].mod.division = self:play_seq(2)
    end
  }
  one:new_seq{id = 1, sequence = {1,3,5,7}, action = true, division = 2}
  one:new_seq{id = 2, sequence = {1,2,1,2}, division = 1}

  two = Voice:new{octave = 1, degree = 3, level = 0.5,
    action = function(self, val)
      self.mod.degree = (CV_degree - 1) + val
      self.seq[1].mod.division = self:play_seq(2)
    end
  }
  two:new_seq{id = 1, sequence = {1,2,5,7,0}, action = true, division = 3}
  two:new_seq{id = 2, sequence = {1,1,4}, division = 1}

  three = Voice:new{octave = 1,
    action = function(self, val)
      self.mod.degree = (CV_degree - 1) + val
      self.seq[1].mod.division = self:play_seq(2)
    end
  }
  three:new_seq{id = 1, sequence = {1,2,3,4,5}, action = true, division = 3, behaviour = 'drunk'}
  three:new_seq{id = 2, sequence = {1,2,3,4}, division = 1, behaviour = 'random'}

  four = Voice:new{octave = 1, degree = 5, level = 0.5,
    synth = function(note, level)
      ii.wsyn.play_note(note, level)
    end,
    action = function(self, val)
      self.mod.degree = (CV_degree - 1) + val
      self.seq[1].mod.division = self:play_seq(2)
    end
  }
  four:new_seq{id = 1, sequence = {1,2,5,7,0}, action = true, division = 2, behaviour = 'prev'}
  four:new_seq{id = 2, sequence = {1,1,4}, division = 1}

  bass = Voice:new{octave = -4, level = 2,
    synth = function(note, level)
      ii.jf.play_voice(1, note, level)
    end,
    action = function(self)
      self.mod.degree = CV_degree
      self.mod.octave = CV_octave
    end
  }

  clk:start()
end
