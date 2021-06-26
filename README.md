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
myvoice = Voice:new(true, true, true, 1, 0, 1, 0)
```
This creates a new Voice called `myvoice`


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


