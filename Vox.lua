--- Vox

-- scales
ionian = {0,2,4,5,7,9,11}
dorian = {0,2,3,5,7,9,10}
phrygian = {0,1,3,5,7,8,10}
lydian = {0,2,4,6,7,9,11}
mixolydian = {0,2,4,5,7,9,10}
aeolian = {0,2,3,5,7,8,10}
locrian = {0,1,3,5,6,8,10}

penta_maj = {0,2,4,7,9} -- ionian, omit 4th and 7th
penta_sus = {0,2,5,7,10} -- dorian, omit 3rd and 6th
blues_min = {0,3,5,8,10} -- phrygian, omit 2nd and 5th
blues_maj = {0,2,5,7,9} -- myxolydian, omit 3rd and 7th
penta_min = {0,3,4,7,10} -- aolian, omit 2nd and 6th
japanese = {0,1,5,7,8} -- phrygian, omit 3rd and 7th

I, II, III, IV, V, VI, VII = 1, 2, 3, 4, 5, 6, 7
-- penta_maj = ionian{I,II,III,V,VI}
-- penta_sus = _dorian{I,II,IV,V,VII}
-- blues_min = _phrygian{I,III,IV,VI,VII}
-- blues_maj = _mixolydian{I,II,IV,V,VI}
-- penta_min = _aeolian{I,III,IV,V,VII}


whole = {0,2,4,6,8,10}

-- divisions
divs = {1/32, 1/16, 1/8, 1/4, 1/2, 1, 2, 4, 8, 16, 32}

-- initial values
cv = {
  scale = mixolydian,
  octave = 0,
  degree = 1
}
--




-- Vox object
-- DL, last modified 2021-09-07

Vox = {}
function Vox:new(args)
  local o = setmetatable( {}, {__index = Vox} )
  local args = args == nil and {} or args

  o.on, o._on = args.on == nil and true or args.on, true
  o.level, o._level = args.level == nil and 1 or args.level, 1
  o.octave, o._octave = args.octave == nil and 0 or args.octave, 0
  o.degree, o._degree = args.degree == nil and 1 or args.degree, 1
  o.transpose, o._transpose = args.transpose == nil and 0 or args.transpose, 0

  o.scale = args.scale == nil and cv.scale or args.scale
  o.negharm = args.negharm == nil and false or args.negharm
  o.synth = args.synth == nil and function(note, level) ii.jf.play_note(note / 12, level) end or args.synth

  o.seq = args.seq == nil and {} or args.seq
  o.preset = args.preset == nil and {} or args.preset

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
function _set(property, objects, val)
  for k, v in pairs(objects) do
    v[property] = val
  end
end

function _do(method, objects, args)
  for k, v in pairs(objects) do
    v[method](v, args)
  end
end
--




-- ii getters and event handlers
-- DL, last modified 2021-09-07

-- ii tables
txi = {param = {0,0,0,0}, input = {0,0,0,0}} -- comment if no txi
-- fb = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0} -- comment if no 16n faderbank

-- ii getters
function ii_getter() -- call this inside a a clock or metro
  if txi then
    for i = 1, 4 do
      ii.txi.get('param', i)
      ii.txi.get('in', i)
    end
  end
  if fb then
    for i = 1, 16 do
      ii.faders.get(i)
    end
  end
end

-- ii event handlers
ii.txi.event = function(e, val)
  if txi then
    txi[e.name == 'in' and 'input' or e.name][e.arg] = val
  end
end

ii.faders.event = function(e, val)
  if fb then
    fb[e.arg] = val
  end
end

-- helper functions
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





-- init
function init()
  ii.jf.mode(1)
  ii.wsyn.ar_mode(1)
  ii.jf.run_mode(1)
  ii.jf.run(5)

  input[1]{mode = 'scale', notes = cv.scale,
    scale = function(s)
      cv.degree = s.index
      cv.octave = s.octave
    end
  }

  input[2]{mode = 'change', threshold = 4, direction = 'rising',
    change = function()
      tsnm:play{
        degree = cv.degree,
        octave = cv.octave,
        on = tsnm.seq.on(),
        level = linlin(txi.input[4], 0, 5, 0, 2)
      }
    end
  }

  output[1]:clock(1)

  all = {
    division = 1,
    degree = 1,
    action = function()
      while true do
        ii_getter()
        clock.sync(1)
        clock.tempo = linlin(txi.input[1], 0, 5, 30, 300)
        all.degree = selector(txi.param[1], {1,4,5,7}, 0, 10)
        -- all.division = selector(txi.input[2], divs, 0, 5)
      end
    end
  }
  all.clock = clock.run(all.action)

  bass = Vox:new{
    octave = -2,
    synth = function(note, level) ii.jf.play_voice(1, note / 12, level) end,
    seq = {
      sync = sequins{3,1},
      degree = sequins{1,1,sequins{5,8,7,5},sequins{8+1,8+5,8+6,8+2}:all():every(4)},
      action = function()
        while true do
          clock.sync(bass.seq.sync())
          bass:play{
            degree = cv.degree + (bass.seq.degree() - 1) + (all.degree - 1),
            level = linlin(txi.input[2], 0, 5, 0, 3)
          }
        end
      end
    }
  }
  bass.clock = clock.run(bass.seq.action)

  lead = Vox:new{
    octave = 0,
    synth = function(note, level) ii.jf.play_note(note / 12, level) end,
    seq = {
      sync = sequins{1},
      degree = sequins{1,4,5,9},
      action = function()
        while true do
          clock.sync(lead.seq.sync())
          lead:play{
            degree = cv.degree + (lead.seq.degree() - 1) + (all.degree - 1),
            level = linlin(txi.input[3], 0, 5, 0, 3)
          }
        end
      end
    }
  }
  lead.clock = clock.run(lead.seq.action)

  tsnm = Vox:new{
    level = 0.3,
    synth = function(note, level) ii.wsyn.play_note(note / 12, level) end,
    seq = {
      on = sequins{true,true,false}
    }
  }




end
