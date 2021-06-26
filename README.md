# SeqSeqSeq
A customisable script for crow that can act as a CV quantiser and create mutliple sequencers influenced by this. Notes are sent to Just Friends by default but this too is customisable. Parameters can be controlled by live coding in druid, but a TXi (or other ii input device) really helps.

Based on ...

## Requirements:
- crow
- written for crow firmware 2.20

## Recommended:
- Just Friends
- TXi

(script requires some small changes without these)

## Optional:
- Any other ii capable device

## Limitations
- Script length - you can only add around 40 lines of user code before the script becomes too long
- However, additional voices/sequencers can be created in druid after the script is run

## Getting started:
```lua
Voice:new(on, ext_octave, ext_degree, level, octave, degree, transpose, synth)
  -- on:          is the voice enabled?, (true/false), defaults to true
  -- ext_octave:  octave transposition based on external CV to input[1], (true/false), defaults to false
  -- ext_degree:  diatonic transposition based on external CV to input[1] (true/false), defaults to false
  -- level:       volume level, defaults to 1
  -- octave:      octave, defaults to 0
  -- degree:      scale degree, 1 based (i.e. 1 is 1st degree, 2 is 2nd etc.), defaults to 1
  -- transpose:   transposition in semitones, 0 based (i.e. 0 is no transposition, 7 is transposition by 7 semitones etc.), defaults 0
  -- synth:       function to play synth (send ii message or set outputs to create CV/gate information), defaults to:
                  function(note, level) ii.jf.play_note(note, level) end
  
  other available properties:
  -- scale:       chosen scale, (list of scales at start of script), defaults to the scale set by CV_SCALE at top of script
                  (Set CV_SCALE to the scale setting of your external sequencer)
                  CV_SCALE = lydian
                  CV_SCALE = {0,2,3,5,7,8,10}
  -- neg_harm:    transforms note to negative harmony equivalent, (true/false), defaults to false
  
  modulation properties:
  -- create sequencers to modulate these properties without affecting the main properties above
  -- mod.on:
  -- mod.level:ts
  -- mod.octave:
  -- mod.degree:
  -- mod.transpose: 
  
  

```
This creates a new Voice called `myvoice`. 

```lua
myvoices:
``


## Reference:
- scales
- divisions
- global settings
- Voice object
- Seq object
- divider
- Txi
- selector
- linlin
- init (declaring voices/sequencers/actions)
- on_clock (variables to be set on on clock)
- input[2].change (voices/sequencers to play on trigger)
- on_division (voices/sequencers to play on clock division)


