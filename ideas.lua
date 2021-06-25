--- SeqSeqSeq IDEAS
--[[
1. Improve global reset
  Copy reset() to main branch
  Find a way to reset the clock divider
  remove global.reset being reset TWICE
  make global.reset act on the new_divider closure only
  combine reset() and global.reset for the closure
  consider removing the closure al togehter

OPTIONS FOR RESET FUNCTIONALITY
1. Simplify by removing closure
2. Have a simple counter instead
3. No option for adding dividers
4. This saves space but keeps most of the required functionality

  OR

1. Update to crow 3
2. Have an object for Voice, Seq, and Div
3. More space







]]
