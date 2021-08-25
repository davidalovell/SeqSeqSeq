--- Vox

-- scales
ionian = {0,2,4,5,7,9,11}
dorian = {0,2,3,5,7,9,10}
phrygian = {0,1,3,5,7,8,10}
lydian = {0,2,4,6,7,9,11}
mixolydian = {0,2,4,5,7,9,10}
aeolian = {0,2,3,5,7,8,10}
locrian = {0,1,3,5,6,8,10}

-- divisions
divs = {1/32, 1/16, 1/8, 1/4, 1/2, 1, 2, 4, 8, 16, 32}

-- declare tables
txi = {param = {}, input = {}}
clk = {}

-- initial values
cv_scale = lydian
cv_degree = 1
cv_octave = 0
division = 1

-- Vox object
Vox = {}
function Vox:new(args)
  local o = setmetatable( {}, {__index = Vox} )
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

  return o
end

function Vox:__on() return self.on and self._on end
function Vox:__level() return self.level * self._level end
function Vox:__octave() return self.octave + self._octave + math.floor(self:__degree() / #self.scale) end
function Vox:__degree() return (self.degree - 1) + (self._degree - 1) end
function Vox:__transpose() return self.transpose + self._transpose end

function Vox:__pos() return self.scale[self:__degree() % #self.scale + 1] + self:__transpose() end
function Vox:__neg() return (7 - self:__pos()) % 12 end
function Vox:__note() return (self.neg_harm and self:__neg() or self:__pos()) / 12 + self:__octave() end

function Vox:play_note() return self:__on() and self.synth(self:__note(), self:__level()) end
function Vox:play(val) self:action(val); self:play_note() end

-- functions for mulitple Vox objects
function _set(names, property, val)
  if type(names) == 'table' then
    for k, v in pairs(names) do
      _G[v][property] = val
    end
  end
end

function _do(method, names)
  if type(names) == 'table' then
    for k, v in pairs(names) do
      _G[v][method](_G[v])
    end
  end
end

-- txi getter and event handler
function txi_getter()
  for i = 1, 4 do
    ii.txi.get('param', i)
    ii.txi.get('in', i)
  end
end

ii.txi.event = function(e, val)
  if txi then
    txi[e.name == 'in' and 'input' or e.name][e.arg] = val
  end
end

-- txi helper functions
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

-- input 1 (cv)
input[1]{mode = 'scale', notes = cv_scale,
  scale = function(s)
    cv_degree = s.index
    cv_octave = s.octave
  end
}

-- input 2 (gate)
input[2]{mode = 'change', threshold = 4, direction = 'rising',
  change = function()
    on_gate()
  end
}

-- outputs
output[1]:clock(1)

-- init
function init()
  ii.jf.mode(1)
  ii.wsyn.ar_mode(1)
  ii.jf.run_mode(1)
  ii.jf.run(4)

  clk.txi = clock.run(
    function()
      while true do
        txi_getter()
        clock.sync(1)
        clock.tempo = linlin(txi.input[1], 0, 5, 30, 300)
        division = selector(txi.input[2], divs, 0, 5)
      end
    end
  )

  clk.print = clock.run(
    function()
      while true do
        clock.sync(division)
        print(round(clock.tempo * 10) / 10, division)
      end
    end
  )

  one = Vox:new{group = 'tsnm', id = 'one',
    action = function(self)
      self._level = linlin(txi.input[3], 0, 5, 0, 5)
      self._octave = cv_octave
      self._degree = cv_degree
    end
  }

  snare = Vox:new{group = 'voices', id = 'snare',
    octave = -2,
    synth = function(note, level)
      ii.wsyn.lpg_symmetry(-5)
      ii.wsyn.lpg_time(-math.random()*1.5)
      ii.wsyn.ramp(5)
      ii.wsyn.play_note(note, level)
    end,
    action = function(self)
      self._level = linlin(txi.input[4], 0, 5, 0, 2)
    end
  }

end

function on_gate()
  one:play()
end












-- Lattice
Lattice, Pattern = {}, {}

--- instantiate a new lattice
-- @tparam[opt] table args optional named attributes are:
-- - "auto" (boolean) turn off "auto" pulses from the norns clock, defaults to true
-- - "meter" (number) of quarter notes per measure, defaults to 4
-- - "ppqn" (number) the number of pulses per quarter note of this superclock, defaults to 96
-- @treturn table a new lattice
function Lattice:new(args)
  local l = setmetatable({}, { __index = Lattice })
  local args = args == nil and {} or args
  l.auto = args.auto == nil and true or args.auto
  l.meter = args.meter == nil and 4 or args.meter
  l.ppqn = args.ppqn == nil and 96 or args.ppqn
  l.enabled = false
  l.transport = 0
  l.superclock_id = nil
  l.pattern_id_counter = 100
  l.patterns = {}
  return l
end

--- start running the lattice
function Lattice:start()
  if self.auto and self.superclock_id == nil then
    self.superclock_id = clock.run(self.auto_pulse, self)
  end
  self.enabled = true
end

--- stop the lattice
function Lattice:stop()
  self.enabled = false
end

--- toggle the lattice
function Lattice:toggle()
  self.enabled = not self.enabled
end

--- destroy the lattice
function Lattice:destroy()
  self:stop()
  if self.superclock_id ~= nil then
    clock.cancel(self.superclock_id)
  end
  self.patterns = {}
end

--- set the meter of the lattice
-- @tparam number meter the meter the lattice counts
function Lattice:set_meter(meter)
  self.meter = meter
end

--- use the norns clock to pulse
-- @tparam table s this lattice
function Lattice.auto_pulse(s)
  while true do
    s:pulse()
    clock.sync(1/s.ppqn)
  end
end

--- advance all patterns in this lattice a single by pulse, call this manually if lattice.auto = false
function Lattice:pulse()
  if self.enabled then
    local ppm = self.ppqn * self.meter
    for id, pattern in pairs(self.patterns) do
      if pattern.enabled then
        pattern.phase = pattern.phase + 1
        if pattern.phase > (pattern.division * ppm) then
          pattern.phase = pattern.phase - (pattern.division * ppm)
          pattern.action(self.transport)
        end
      elseif pattern.flag then
        self.patterns[pattern.id] = nil
      end
    end
    self.transport = self.transport + 1
  end
end

--- factory method to add a new pattern to this lattice
-- @tparam[opt] table args optional named attributes are:
-- - "action" (function) function called on each step of this division
-- - "division" (number) the division of the pattern, defaults to 1/4
-- - "enabled" (boolean) is this pattern enabled, defaults to true
-- @treturn table a new pattern
function Lattice:new_pattern(args)
  self.pattern_id_counter = self.pattern_id_counter + 1
  local args = args == nil and {} or args
  args.id = self.pattern_id_counter
  args.action = args.action == nil and function(t) return end or args.action
  args.division = args.division == nil and 1/4 or args.division
  args.enabled = args.enabled == nil and true or args.enabled
  args.phase_end = args.division * self.ppqn * self.meter
  local pattern = Pattern:new(args)
  self.patterns[self.pattern_id_counter] = pattern
  return pattern
end

--- "private" method to instantiate a new pattern, only called by Lattice:new_pattern()
-- @treturn table a new pattern
function Pattern:new(args)
  local p = setmetatable({}, { __index = Pattern })
  p.id = args.id
  p.division = args.division
  p.action = args.action
  p.enabled = args.enabled
  p.phase = args.phase_end
  p.flag = false
  return p
end

--- start the pattern
function Pattern:start()
  self.enabled = true
end

--- stop the pattern
function Pattern:stop()
  self.enabled = false
end

--- toggle the pattern
function Pattern:toggle()
  self.enabled = not self.enabled
end

--- flag the pattern to be destroyed
function Pattern:destroy()
  self.enabled = false
  self.flag = true
end

--- set the division of the pattern
-- @tparam number n the division of the pattern
function Pattern:set_division(n)
   self.division = n
end

--- set the action for this pattern
-- @tparam function the action
function Pattern:set_action(fn)
  self.action = fn
end
