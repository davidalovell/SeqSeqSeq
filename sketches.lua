ii.jf.run_mode(1)
ii.jf.run(5)

output[2](lfo(8,5,'sine'))

v = {}

v[1] = Voice:new(true, true, true, 0.5, -1, 1, 0)
v[1]:new_seq(1, true, {1,2,3,1/2}, 1, 1, 'next', true)
v[1]:new_seq(2, true, {true,false},1, 1, 'next')
v[1].action = function(self, val)
  self.seq[1].mod.division = val * selector(txi.param[2], div.even, 0, 10)
  self.mod.on = self:play_seq(2)
  self.seq[2].mod.division = selector(txi.param[1], div.x2, 0, 10)
end

v[2] = Voice:new(true, true, true, 0.5, -2, 5, 0)
v[2]:new_seq(1, true, {1,5}, 1, 1, 'next', true)
v[2]:new_seq(2, true, {true,false},1, 1, 'next')
v[2].action = function(self, val)
  self.seq[1].mod.division = val * selector(txi.param[2], div.odd, 0, 10)
  self.mod.on = self:play_seq(2)
  self.seq[2].mod.division = selector(txi.param[1], div.x2, 0, 10)
end

v[3] = Voice:new(true, true, true, 0.5, 1, 3, 0, function(note, level) ii.wsyn.play_note(note, level) end)
v[3]:new_seq(1, true, {3,1, 3,1, 3,1, 2,1,1}, 1, 1, 'next', true)
v[3].action = function(self, val)
  self.seq[1].mod.division = val
end

v[4] = Voice:new(true, false, true, 1.5, -2, 1, 0, function(note, level) ii.jf.play_voice(1, note, level) end)
v[4]:new_seq(1, true, {4,3,1}, 1, 1, 'next', true)
v[4]:new_seq(2, true, {1,1,1}, 1, 1, 'next')
v[4].action = function(self, val)
  self.seq[1].mod.division = val * selector(txi.param[3], div.x2, 0, 10)
  self.seq[1].sequence = selector(txi.param[4], {{4,3,1}, {2,1/2,1/2,1}}, 0, 10)
  self.seq[2].sequence[3] = math.random(3,4)
  self.mod.degree = self:play_seq(2)
end








v.div1 = Voice:new(true, false, false, 0.5, 1, 1, 0, function(note, level) ii.wsyn.play_note(note, level) end)
v.div1:new_seq(1, true, {1,2,3,4,5,6,7}, 1, 2, 'next', true)
v.div1:new_seq(2, true, {1,3,5}, 4, 1, 'next')
v.div1:new_seq(3, true, {2,3,1}, 1, 1, 'next')
function v.div1:action(val)
  self.mod.degree = val + self:play_seq(2)
  self.seq[1].mod.division = self:play_seq(3)
end

v.div2 = Voice:new(true, false, true, 1.5, -2, 1, 0, function(note, level) ii.jf.play_voice(1, note, level) end)
v.div2:new_seq(1, true, {4,3,1}, 1, 1, 'next', true)
v.div2:new_seq(2, true, {1,1,1}, 1, 1, 'next')
function v.div2:action(val)
  self.seq[1].mod.division = val * selector(txi.param[3], div.x2, 0, 10)
  self.seq[1].sequence = selector(txi.param[4], {{4,3,1}, {2,1/2,1/2,1}}, 0, 10)
  self.seq[2].sequence[3] = math.random(3,4)
  self.mod.degree = self:play_seq(2)
end
end



function r(voice)
  for k, v in pairs(_G[voice]['seq']) do
    _G[voice]['seq'][k]['reset'] = true
  end
end






bass = Voice:new(true, false, false, 1, -2, 1, 0, function(note, level) ii.jf.play_voice(1, note, level) end)
bass:new_seq(1, true, {1,1,1}, 4, 1, 'next', true)
bass:new_seq(2, true, {6,4,2}, 1, 1, 'next')
function bass:action(val)
  self.seq[1].sequence[3] = triads[chord][3] + math.random(-1,1)
  self.seq[1].mod.division = self:play_seq(2)
  self.mod.degree = val + (triads[chord][1] - 1)
end
