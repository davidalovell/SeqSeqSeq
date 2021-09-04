#SeqSeqSeq (INCOMPLETE)

A crow script that allows you to create multiple voice and sequencer objects.  
This was designed to be part of this small system:

![image](image.jpg)

- crow is acting as the main clock, a quantiser and sequencer
- TXi allows for hands on control of the script in a customisable way
- Just Friends and w/ are the sound sources
- Doboz XIIO is a touch controller, sending CV and triggers to crow

## Requirements:
- crow
- crow firmware 2.2

## Recommended:
- Just Friends
- w/
- TXi
(script requires some small changes without these)

## Optional:
- Any other ii capable device

## Limitations:
- Script length
- Not tested with scales > 7 notes

## Getting started:
### 1. Create voices
```lua
Voice:new{
 on = true,                      -- defaults to true
 level = 1,                      -- defaults to 1
 octave = 0,                     -- defaults to 0
 degree = 1,                     -- defaults to 1 (1-based)
 transpose = 0,                  -- defaults to 0 (0-based)
 scale = lydian                  -- defaults to the value of CV_scale (CV_scale also determines the notes in input[1].notes)
                                 -- (set CV_scale to the scale setting of your external CV source)
 neg_harm = false                -- defaults to false
                                 -- (plays the negative harmony equivalent of the note based on the selected scale)

 synth = function(note, level)   -- defaults to this function which plays a note on Just Friends
   ii.jf.play_note(note, level)
 end,

 action = function(self, val)    -- defaults to this empty function, the idea is to add custom commands to this
 end
}
```
Examples:
```lua
my_voice = Voice:new()            -- creates a voice with default settings

my_voice = Voice:new{             -- creates a voice transposed up and octave and a diatonic fifth
 octave = 1,                     -- (note {} syntax)
 degree = 5
}

my_voice = Voice:new{               -- play w/syn instead of the default
 synth = function(note, level)
   ii.wsyn.play_note(note, level)
 end
}

my_voice = Voice:new{               -- play Just Friends first voice
 synth = function(note, level)
   ii.jf.play_voice(1, note, level)
 end
}

my_voice = Voice:new{               -- creates a voice you can play with your external CV source into input[1]
 action = function(self, val)
   self.mod.degree = val + (CV_degree - 1) -- (subtract 1 from CV_degree as degree is 1-based)
   self.mod.octave = val + CV_octave
 end
}
```
### 2. Create sequencers within the voices
```lua
Voice:new_seq(id, on, sequence, division, step, behaviour, action)
-- arguments:
 -- id:          each sequencer should be given an id, typically
 -- on:          is the sequencer enabled?, (true/false), defaults to true
 -- sequence:    defaults to {1,2,3,4}
 -- division:    clock divider for sequencer, defaults to 1
 -- step:        number of steps advance, defaults to 1
 -- behaviour:   'next', 'prev', 'drunk', 'random', defaults to 'next'
 -- action:      options:
 --                no argument, or nil     -   sequencer returns a value
 --                true                    -   sequencer plays the voice
                                           -   (you can choose to create several sequences within the voice with action = true for some polymetric patterns)
 --                pass a custom function  -   e.g.
                                               function(val) global.bpm = val end
```
Examples:
```lua
my_voice:new_seq(1, true, {1,2,1,3}, 1, 1, 'next', true)
my_voice:new_seq(2, true, {true, false, true}, 4, 1, 'next')
my_voice:new_seq(3)
```
### 3. Create actions within the voices to play the sequencers
```lua
function my_voice:action(val)
 self.mod.degree = val
 self.mod.on = self:play_seq(2)
 self.mod.division = self:play_seq(3)
end
```
If a sequencer that has been created has action = true (see above) then this function will be played when the sequencer is called. As you can see you can make it do whatever you want.

### 4. Standalone sequencers
Create standalone sequencers
```lua
Seq:new(on, sequence, division, step, behaviour, action)
-- arguments:

```
Other details:
```lua
-- other available properties:
 -- scale:         chosen scale, (list of scales at start of script), defaults to the scale set by CV_SCALE at top of script                  
 -- neg_harm:      transforms note to negative harmony equivalent, (true/false), defaults to false

-- modulation properties:
 -- create sequencers to modulate these properties without affecting the main properties above
 -- mod.on:        all 'on' properties need to be true for the Voice to play
 -- mod.level:     multiplies with other 'level' properties
 -- mod.octave:    adds to other 'octave' properties
 -- mod.degree:    adds to other 'degree' properties
 -- mod.transpose: adds to other 'transpose' properties
```

This creates a new Voice called `myvoice`.

```lua
myvoices:

 --              (Set CV_SCALE to the scale setting of your external sequencer)
                 CV_SCALE = lydian
                 CV_SCALE = {0,2,3,5,7,8,10}
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