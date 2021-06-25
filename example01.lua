--- SeqSeqSeq Example
--------------------------------------------------------
-- paste below inside:
-- function init()
-- and below the following line:
-- declare voices/sequencers/actions

ii.jf.run_mode(1)
ii.jf.run(5)

output[2](lfo(8,5,'sine'))

triads = {{1,3,5}, {2,4,6}, {3,5,7}, {4,6,1}, {5,7,2}, {6,1,3}, {7,2,4}}

new_chord = Seq:new(true, {1,5,4,1}, 24, 1, 'next')

arp = Voice:new(true, false, false, 0.75, 0, 1, 0)
arp:new_seq(1, true, {1}, 3, 1, 'next', true)
arp:new_seq(2, true, {1,2,3}, 4, 1, 'prev')
arp:new_seq(3, true, {4,1,1,3,1}, 1, 1, 'next')
function arp:action(val)
  self.seq[1].sequence = triads[chord]
  self.seq[1].sequence[4] = self.seq[1].sequence[self:play_seq(2)] + math.random(0,1) * 7
  self.seq[1].mod.division = self:play_seq(3)
  self.mod.degree = val
end

arp2 = Voice:new(true, false, false, 0.5, 0, 5, 0)
arp2:new_seq(1, true, {1}, 2, 2, 'next', true)
arp2:new_seq(2, true, {6,4,1,1}, 1, 1, 'next')
function arp2:action(val)
  self.seq[1].sequence = triads[chord]
  self.seq[1].mod.division = self:play_seq(2)
  self.mod.degree = val + math.random(-1,0) * 7
end

bass = Voice:new(true, false, false, 1, -2, 1, 0, function(note, level) ii.jf.play_voice(1, note, level) end)
bass:new_seq(1, true, {1,1,1}, 6, 1, 'next', true)
bass:new_seq(2, true, {4,3,1}, 1, 1, 'next')
function bass:action(val)
  self.seq[1].sequence[3] = triads[chord][3] + math.random(-1,1)
  self.seq[1].mod.division = self:play_seq(2)
  self.mod.degree = val + (triads[chord][1] - 1)
end

--------------------------------------------------------
-- paste below inside:
-- input[2].change = function()
-- and below the following line:
-- voices/seqeuncers to play on trigger to crow input[2]

--------------------------------------------------------
-- paste below inside:
-- function on_clock()
-- and below the following line:
-- variables to be set on clock, e.g.

global.bpm = linlin(txi.input[1], 0, 5, 10, 3000)
global.division = selector(txi.input[2], div.x2, 0, 4)
global.negharm = selector(txi.input[3], {false,true}, 0, 4)
global.count = global.division * new_chord.division * #new_chord.sequence * 4

--------------------------------------------------------
-- paste below inside:
-- function on_division()
-- and below the following line:
-- voices/sequencers to play on every clock division

chord = new_chord:play_seq()
arp:play_seq()
arp2:play_seq()
bass:play_seq()
