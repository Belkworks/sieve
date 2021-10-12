local Sieve = nil
local pop = table.remove
local pred
pred = function(Fn)
  return function(T, P)
    return Fn(T, Sieve.predicate(P))
  end
end
local recurses
recurses = function(Fn)
  return function(A, B, Seen)
    if Seen == nil then
      Seen = { }
    end
    if Seen[B] then
      return 
    end
    Seen[B] = true
    return Fn(A, B, Seen)
  end
end
local matches = nil
matches = (recurses(function(P, T, Seen)
  if not (T) then
    return 
  end
  for I, V in pairs(P) do
    local D = T[I]
    local Type = type(V)
    if Type == 'userdata' or Type == 'table' then
      if not (matches(V, D, Seen)) then
        return 
      end
    else
      if not (D == V) then
        return 
      end
    end
  end
  return true
end))
local partial
partial = function(Fn, ...)
  local Args = {
    ...
  }
  return function(...)
    return Fn((unpack(Args)), ...)
  end
end
Sieve = {
  predicate = function(Any)
    local _exp_0 = type(Any)
    if 'function' == _exp_0 then
      return Any
    elseif 'table' == _exp_0 then
      return Sieve.matcher(Any)
    elseif 'string' == _exp_0 then
      return Sieve.property(Any)
    end
  end,
  property = function(K)
    return function(T)
      return T[K] ~= nil
    end
  end,
  matcher = function(P)
    return function(V)
      return matches(P, V)
    end
  end,
  find = pred(function(T, P)
    for I, V in pairs(T) do
      if P(V, I, T) then
        return V, I
      end
    end
  end),
  indexOf = function(T, P)
    return pop({
      Sieve.find(T, P)
    })
  end,
  filter = pred(function(T, P)
    local _accum_0 = { }
    local _len_0 = 1
    for I, V in pairs(T) do
      if P(V, I, T) then
        _accum_0[_len_0] = V
        _len_0 = _len_0 + 1
      end
    end
    return _accum_0
  end),
  test = pred(function(Callback, P)
    return function(...)
      if P(...) then
        return Callback(...)
      end
    end
  end)
}
return setmetatable(Sieve, {
  __call = function(self, T, P)
    return Sieve.filter(T, P)
  end
})
