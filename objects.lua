lydian = {0,2,4,6,7,9,11}

CV_SCALE = lydian

global = {
    cv_degree = 1
  , cv_octave = 0
}

Voice = {}
function Voice:new(args)
  local o = setmetatable( {}, {__index = Voice} )
  local t = args or {}

  o.on = t.on == nil and true or t.on
  o.level = t.level == nil and 1 or t.level
  o.octave = t.octave == nil and 0 or t.octave
  o.degree = t.degree == nil and 1 or t.degree
  o.transpose = t.transpose == nil and 0 or t.transpose
  o.scale = t.scale == nil and CV_SCALE or t.scale
  o.neg_harm = t.neg_harm == nil and false or t.neg_harm
  o.synth = t.synth == nil and function(note, level) ii.jf.play_note(note, level) end or t.synth

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

function Voice:action(val) end
function Voice:play_note() return self:_on() and self.synth( self:_note(), self:_level() ) end

function Voice:play_voice(val)
  self:action(val)
  self:play_note()
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
  o.reset = false

  return o
end

function Seq:_on() return self.on and self.mod.on end
function Seq:_division() return self.division * self.mod.division end
function Seq:_step() return self.step * self.mod.step end
function Seq:_action(val) end

function Seq:_div_adv() return self:_on() and self.div_count % self:_division() + 1 end
function Seq:_step_adv() return self:_on() and self.div_count == 1 end

function Seq:_behaviour()
  return self.behaviour == 'next' and ( (self.step_count + self.step) - 1 ) % #self.sequence + 1
    or self.behaviour == 'prev' and ( (self.step_count - self.step) - 1 ) % #self.sequence + 1
    or self.behaviour == 'drunk' and clamper( ( (self.step_count + self.step * math.random(-1, 1) ) - 1 ) % #self.sequence + 1, 1, #self.sequence )
    or self.behaviour == 'random' and math.random(1, #self.sequence)
    or self.stepcount
end

function Seq:play_seq()
  self.div_count = self.reset and 1 or self:_div_adv() or self.div_count
  self.step_count = self.reset and 1 or self:_step_adv() and self:_behaviour() or self.step_count
  self.reset = false
  return self:_step_adv() and self.action == nil and self.sequence[self.step_count] or self.action( self.sequence[self.step_count] )
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

function round(input)
  return input % 1 >= 0.5 and math.ceil(input) or math.floor(input)
end
