--- sequins test

function init()
  mycounter = metro.init{
    event = count_event,
    time  = 0.5,
  }

  mycounter:start()

  s = sequins

  seq = s{1,2,3,4,5,6,7,8,9,10}
end


function count_event()
  print(seq())

end
