--- txi

ionian = {0,2,4,5,7,9,11}
dorian = {0,2,3,5,7,9,10}
phrygian = {0,1,3,5,7,8,10}
lydian = {0,2,4,6,7,9,11}
mixolydian = {0,2,4,5,7,9,10}
aeolian = {0,2,3,5,7,8,10}

divs = {1/32, 1/16, 1/8, 1/4, 1/2, 1, 2, 4, 8, 16}

cv_scale = phrygian
cv_degree = 1
cv_octave = 0

txi = {param = {}, input = {}}

division = 1

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
  o.synth = t.synth == nil and function(note, level) ii.jf.play_note(note, level) end or t.synth
  o.action = t.action == nil and function(self, val) end or t.action

  o._on = true
  o._level = 1
  o._octave = 0
  o._degree = 1
  o._transpose = 0

  o.seq = {}

  return o
end

function Voice:__on() return self.on and self._on end
function Voice:__level() return self.level * self._level end
function Voice:__octave() return self.octave + self._octave + math.floor(self:__degree() / #self.scale) end
function Voice:__degree() return (self.degree - 1) + (self._degree - 1) end
function Voice:__transpose() return self.transpose + self._transpose end

function Voice:play_note()
  local s = self
  s.pos = s.scale[s:__degree() % #s.scale + 1] + s:__transpose()
  s.neg = (7 - s.pos) % 12
  s.note = (s.neg_harm and s.neg or s.pos) / 12 + s:__octave()
  return s:__on() and s.synth( s.note, s:__level() )
end

function Voice:play_voice(val)
  self:action(val)
  self:play_note()
end

function Voice:new_seq(args)
  local t = args or {}
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

  o._division = 1
  o._step = 1

  o.count = - o.offset
  o.div_count = 0
  o.step_count = 0
  o.index = 1

  return o
end

function Seq:__division() return self.division * self._division end
function Seq:__step() return self.step * self._step end

function Seq:play_seq()
  local s = self
  s.count = s.count + 1

  s.div_count = s.count >= 1
    and s.div_count % s:__division() + 1
    or s.div_count

  s.step_count = s.count >= 1 and s.div_count == 1
    and ((s.step_count + s:__step()) - 1) % #s.sequence + 1
    or s.step_count

  s.next = (s.count - 1) % s.every == 0 and s.prob >= math.random()
  s.index = s.next and s.step_count or s.index

  return s.next and s.count >= 1 and s.div_count == 1 and s.action ~= nil
    and s.action(s.sequence[s.index])
    or s.sequence[s.index] --or 0
end

function Seq:reset()
  self.count = - self.offset
  self.div_count = 0
  self.step_count = 0
  self.index = 1
end

function set(names, property, val)
  for k, v in pairs(names) do
    _G[v][property] = val
  end
end

function action(method, names)
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
  txi[e.name == 'in' and 'input' or e.name][e.arg] = val
end

function clamp(x, min, max)
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
  return data[ clamp( round( linlin( x, in_min, in_max, out_min, out_max ) ), out_min, out_max ) ]
end

function init()
  ii.jf.mode(1)
  ii.wsyn.ar_mode(1)

  ii.jf.run_mode(1)
  ii.jf.run(5)

  clk = clock.run(
    function()
      while true do
        txi_getter()

        clock.sync(division)

        clock.tempo = linlin(txi.input[1], 0, 5, 30, 300)
        division = selector(txi.input[2], divs, 0, 5)
        set(jf, 'level', linlin(txi.input[3], 0, 5, 0, 5))
        set(w, 'level', linlin(txi.input[4], 0, 5, 0, 3))

        action('play_seq', w)
        
        print(round(clock.tempo * 10) / 10, division)
      end
    end
  )

  input[1]{mode = 'scale', notes = cv_scale,
    scale = function(s)
      cv_octave = s.octave
      cv_degree = s.index
    end
  }

  input[2]{mode = 'change', threshold = 4, direction = 'rising',
    change = function()
      action('play_voice', jf)
    end
  }

  output[1]:clock(1)

  one = Voice:new{group = 'jf', id = 'one',
    action = function(self, val)
      self._degree = cv_degree
      self._octave = cv_octave
    end
  }

  two = Voice:new{group = 'jf', id = 'two',
    transpose = 7,
    action = function(self, val)
      self._degree = cv_degree
      self._octave = cv_octave
    end
  }

  snare = Voice:new{group = 'w', id = 'snare',
    octave = -3,
    synth = function(note, level)
      ii.wsyn.curve(5)
      ii.wsyn.ramp(0)
      ii.wsyn.fm_index(0)
      ii.wsyn.fm_env(-1)
      ii.wsyn.lpg_time(-0.5)
      ii.wsyn.lpg_symmetry(-5)
      ii.wsyn.fm_ratio(4,1)

      ii.wsyn.play_note(note, level)
    end,
    action = function(self, val)
      self.seq[1]._division = val
    end
  }
  snare:new_seq{offset = 8, division = 16, action = true}

end


-- ii.wsyn.lpg_symmetry(-5)
-- ii.wsyn.lpg_time(-math.random()*1.5)
-- ii.wsyn.ramp(5)
