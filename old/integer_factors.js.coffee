Math.factors = (i) ->
  f for f in [1..i] when i % f == 0
