--- SeqSeqSeq

ionian = {0,2,4,5,7,9,11}
dorian = {0,2,3,5,7,9,10}
phrygian = {0,1,3,5,7,8,10}
lydian = {0,2,4,6,7,9,11}
mixolydian = {0,2,4,5,7,9,10}
aeolian = {0,2,3,5,7,8,10}

pow2 = {1,2,4,8,16,32,64}
odd = {1,3,5,7,9}
even = {1,2,4,6,8,10}

cv_scale = lydian
cv_degree = 1
cv_octave = 0

txi = {param = {}, input = {}}

bpm = 60

Voice = {}
function Voice:new(args)
  local o = setmetatable( {}, {__index = Voice} )
  local t = args or {}

	o.group, o.id = t.group, t.id
	if o.group ~= nil and o.id ~= nil then
		_G[o.group] = _G[o.group] == nil and {} or _G[o.group]
		_G[o.group][o.id] = o.id
	end

  o.on = t.on == nil and true or t.on
  o.level = t.level == nil and 1 or t.level
  o.octave = t.octave == nil and 0 or t.octave
  o.degree = t.degree == nil and 1 or t.degree
  o.transpose = t.transpose == nil and 0 or t.transpose
  o.scale = t.scale == nil and cv_scale or t.scale
  o.neg_harm = t.neg_harm == nil and false or t.neg_harm
  o.synth = t.synth == nil and function(note, level) print(note, level) end or t.synth
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

function Voice:play_note()
  local s = self
  s.pos = s.scale[s:_degree() % #s.scale + 1] + s:_transpose()
  s.neg = (7 - s.pos) % 12
  s.note = (s.neg_harm and s.neg or s.pos) / 12 + s:_octave()
  return s:_on() and s.synth( s.note, s:_level() )
end

function Voice:play_voice(val)
  self:action(val)
  self:play_note()
end

function Voice:new_seq(args)
  local t = args or {}
	-- t.group = t.group == nil and self.id .. '_seqs' or t.group -- double check
  t.action = type(t.action) == 'function' and t.action or t.action and function(val) self:play_voice(val) end
  self.seq[#self.seq + 1] = Seq:new(t)
end

function Voice:play_seq(index)
  if index == nil then
    for k, v in pairs(self.seq) do
      local play = self.seq[k].action and self.seq[k]:play_seq()
    end
  else
    return self.seq[index]:play_seq()
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

	o.group, o.id = t.group, t.id
	if o.group ~= nil and o.id ~= nil then
		_G[o.group] = _G[o.group] == nil and {} or _G[o.group]
		_G[o.group][o.id] = o.id
  end

  o.sequence = t.sequence == nil and {1} or t.sequence
  o.division = t.division == nil and 1 or t.division
  o.step = t.step == nil and 1 or t.step
  o.every = t.every == nil and 1 or t.every
  o.prob = t.prob == nil and 1 or t.prob
  o.offset = t.offset == nil and 0 or t.offset
  o.action = t.action

  o.mod = {division = 1, step = 1}

  o.count = - o.offset
  o.div_count = 0
  o.step_count = 0
  o.index = 1

  return o
end

function Seq:_division() return self.division * self.mod.division end
function Seq:_step() return self.step * self.mod.step end

function Seq:play_seq()
  local s = self
  s.count = s.count + 1

  s.div_count = s.count >= 1
    and s.div_count % s:_division() + 1
    or s.div_count

  s.step_count = s.count >= 1 and s.div_count == 1
    and ((s.step_count + s:_step()) - 1) % #s.sequence + 1
    or s.step_count

  s.next = (s.count - 1) % s.every == 0 and s.prob >= math.random()
  s.index = s.next and s.step_count or s.index

  return s.next and s.count >= 1 and s.div_count == 1 and s.action ~= nil
    and s.action(s.sequence[s.index])
    or s.sequence[s.index] or 0
end

function Seq:reset()
  self.count = - self.offset
  self.div_count = 0
  self.step_count = 0
  self.index = 1
end

function clmp(x, min, max)
  return math.min( math.max( min, x ), max )
end

function round(x)
  return x % 1 >= 0.5 and math.ceil(x) or math.floor(x)
end

function linlin(x, in_min, in_max, out_min, out_max)
  return (x - in_min) * (out_max - out_min) / (in_max - in_min) + out_min
end

function selector(x, data, in_min, in_max, out_min, out_max)
  out_min = out_min or 1
  out_max = out_max or #data
  return data[ clmp( round( linlin( x, in_min, in_max, out_min, out_max ) ), out_min, out_max ) ]
end

function set(names, property, val)
  for k, v in pairs(_G[names]) do
    _G[v][property] = val
  end
end

function action(method, names)
  for k, v in pairs(_G[names]) do
    _G[v][method](_G[v])
  end
end

one = Voice:new{group = 'voices', id = 'one',
  action = function(self, val)
    self.degree = val
  end
}
one:new_seq{sequence = {1,2,3,4}, action = true} -- not working
-- action('play_voice', 'voices')
