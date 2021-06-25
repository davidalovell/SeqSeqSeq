--- SeqSeqSeq Example
--------------------------------------------------------
-- paste below inside:
-- function init()
-- and below the following line:
-- declare voices/sequencers/actions


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
