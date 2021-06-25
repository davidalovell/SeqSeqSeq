# SeqSeqSeq
A customisable script for crow that can act as a CV quantiser and then create mutliple sequencers which can be influenced by this. Notes are sent to Just Friends by default but this too is customisable. Parameters can be controlled by live coding in druid or by TXi.

Based on ...

## Requirements:
- crow
- written for crow firmware 2.20

## Recommended:
- Just Friends
- TXi

(script requires some small changes without these)

## Optional:
- Any other ii capable module

## Limitations
- Script length - you can add around 40 lines of user code before the script becomes too long
- However, additional voices/sequencers can be created in druid after the script is run

## Things:
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

## How to use:


