--- voice

ionian = {0,2,4,5,7,9,11}
dorian = {0,2,3,5,7,9,10}
phrygian = {0,1,3,5,7,8,10}
lydian = {0,2,4,6,7,9,11}
mixolydian = {0,2,4,5,7,9,10}
aeolian = {0,2,3,5,7,8,10}

pow2 = {1/32, 1/16, 1/8, 1/4, 1/2, 1, 2, 4, 8, 16}
odd = {1,3,5,7,9}
even = {1,2,4,6,8,10}

cv_scale = phrygian
cv_degree = 1
cv_octave = 0

txi = {param = {}, input = {}}

division = 1

voice = {}
function voice:new(args)
  local o = setmetatable( {}, {__index = voice} )
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

function voice:__on() return self.on and self._on end
function voice:__level() return self.level * self._level end
function voice:__octave() return self.octave + self._octave + math.floor(self:__degree() / #self.scale) end
function voice:__degree() return (self.degree - 1) + (self._degree - 1) end
function voice:__transpose() return self.transpose + self._transpose end

function voice:play_note()
  local s = self
  s.pos = s.scale[s:__degree() % #s.scale + 1] + s:__transpose()
  s.neg = (7 - s.pos) % 12
  s.note = (s.neg_harm and s.neg or s.pos) / 12 + s:__octave()
  return s:__on() and s.synth( s.note, s:__level() )
end

function voice:play(val)
  self:action(val)
  self:play_note()
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

function init()
  txi_getter()

  input[1]{mode = 'scale', notes = cv_scale,
    scale = function(s)
      cv_octave = s.octave
      cv_degree = s.index
    end
  }

  input[2]{mode = 'change', threshold = 4, direction = 'rising',
    change = function()
      action('play', voices)
    end
  }

  clk = clock.run(
    function ()
      while true do
        clock.sync(division)
        output[1](pulse())

        txi_getter()
        clock.tempo = linlin(txi.param[1], 0, 10, 30, 300)
        division = selector(txi.param[2], pow2, 0, 10)

        print(round(clock.tempo * 10) / 10, division)
      end
    end
  )

  ii.jf.mode(1)
  ii.wsyn.ar_mode(1)

  ii.jf.run_mode(1)
  ii.jf.run(5)

  one = voice:new{group = 'voices', id = 'one',
    action = function(self, val)
      self._octave = cv_octave
      self._degree = cv_degree
    end
  }

  two = voice:new{group = 'voices', id = 'two',
    transpose = 7,
    action = function(self, val)
      self._octave = cv_octave
      self._degree = cv_degree
    end
  }

  print('test')
end
