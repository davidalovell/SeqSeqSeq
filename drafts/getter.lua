-- ii settings getter

wsyn = {
  'ar_mode',
  'curve',
  'ramp',
  'fm_index',
  'fm_env',
  'fm_ratio',
  'lpg_time',
  'lpg_symmetry',
  'patch',
  'voices',
}

function get(device)
  for k, v in pairs(device) do
    ii.wsyn.get(v)
  end
end

ii.wsyn.event = function(e, value)
  print(e.name, value)
end

function init()
  play('wsyn', -3)
end

function play(device, note)
  get(_G[device])
  ii[device].play_note(note, 1)
end
