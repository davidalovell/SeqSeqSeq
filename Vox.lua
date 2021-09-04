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

-- tables
txi = {param = {0,0,0,0}, input = {0,0,0,0}}
clk = {division = 1}

-- initial values
cv_scale = lydian
cv_degree = 1
cv_octave = 0
--




-- Vox object
Vox = {}

function Vox:new(args)
  local o = setmetatable( {}, {__index = Vox} )
  local args = args == nil and {} or args

  o.on, o._on = args.on == nil and true or args.on, true
  o.level, o._level = args.level == nil and 1 or args.level, 1
  o.octave, o._octave = args.octave == nil and 0 or args.octave, 0
  o.degree, o._degree = args.degree == nil and 1 or args.degree, 1
  o.transpose, o._transpose = args.transpose == nil and 0 or args.transpose, 0

  o.scale = args.scale == nil and cv_scale or args.scale
  o.negharm = args.negharm == nil and false or args.negharm
  o.synth = args.synth == nil and function(note, level) ii.jf.play_note(note / 12, level) end or args.synth

  o.seq = {}

  return o
end

function Vox:play(args)
  local args = args == nil and {} or args

  self._on = args.on == nil and self._on or args.on
  self._level = args.level == nil and self._level or args.level
  self._octave = args.octave == nil and self._octave or args.octave
  self._degree = args.degree == nil and self._degree or args.degree
  self._transpose = args.transpose == nil and self._transpose or args.transpose

  self.scale = args.scale == nil and self.scale or args.scale
  self.negharm = args.negharm == nil and self.negharm or args.negharm
  self.synth = args.synth == nil and self.synth or args.synth

  return self:__on() and self.synth(self:__note(), self:__level())
end

function Vox:__on() return self.on and self._on end
function Vox:__level() return self.level * self._level end
function Vox:__octave() return self.octave + self._octave + math.floor(self:__degree() / #self.scale) end
function Vox:__degree() return (self.degree - 1) + (self._degree - 1) end
function Vox:__transpose() return self.transpose + self._transpose end
function Vox:__pos() return self.scale[self:__degree() % #self.scale + 1] + self:__transpose() end
function Vox:__neg() return (7 - self:__pos()) % 12 end
function Vox:__note() return (self.negharm and self:__neg() or self:__pos()) + self:__octave() * 12 end

-- functions for mulitple Vox objects
function _set(property, val, objects)
  for k, v in pairs(objects) do
    v[property] = val
  end
end

function _do(method, args, objects)
  for k, v in pairs(objects) do
    v[method](v, args)
  end
end
--




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
--




-- inputs
input[1]{mode = 'scale', notes = cv_scale,
  scale = function(s)
    cv_degree = s.index
    cv_octave = s.octave
  end
}

input[2]{mode = 'change', threshold = 4, direction = 'rising',
  change = function()
    tsnm:play{degree = cv_degree, octave = cv_octave}
  end
}
--




-- output 1
output[1]:clock(1)
--




-- init
function init()
  ii.jf.mode(1)
  ii.wsyn.ar_mode(1)
  ii.jf.run_mode(1)
  ii.jf.run(5)

  txi.action = function()
    while true do
      txi_getter()
      clock.sync(1)
      clock.tempo = linlin(txi.input[1], 0, 5, 30, 300)
      clk.division = selector(txi.input[2], divs, 0, 5)
    end
  end
  clk.txi = clock.run(txi.action)

  one = Vox:new{}
  one.seq = {
    sync = sequins{4,3,1,2,2,1,3,4},
    degree = sequins{1,4,5,9},
    action = function()
      while true do
        clock.sync(one.seq.sync() * clk.division)
        one:play{degree = one.seq.degree()}
      end
    end
  }
  clk.one = clock.run(one.seq.action)

  tsnm = Vox:new{
    level = 0.3,
    synth = function(note, level) ii.wsyn.play_note(note / 12, level) end
  }




end
