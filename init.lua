local Sieve = nil
local pop = table.remove
local push = table.insert
local pred
pred = function(Fn)
  return function(T, P)
    return Fn(T, Sieve.predicate(P))
  end
end
local invert
invert = function(Fn)
  return function(...)
    return not Fn(...)
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
local isArray
isArray = function(T)
  return #T == #(function()
    local _accum_0 = { }
    local _len_0 = 1
    for K in pairs(T) do
      _accum_0[_len_0] = K
      _len_0 = _len_0 + 1
    end
    return _accum_0
  end)()
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
  findValue = function(T, V)
    return Sieve.find(T, function(R)
      return R == V
    end)
  end,
  indexOf = function(T, P)
    local V, I = Sieve.find(T, P)
    return I
  end,
  indexOfValue = function(T, V)
    return Sieve.indexOf(T, function(R)
      return R == V
    end)
  end,
  exists = function(T, P)
    return (Sieve.indexOf(T, P)) ~= nil
  end,
  valueExists = function(T, V)
    return (Sieve.indexOfValue(T, V)) ~= nil
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
  reject = pred(function(T, P)
    return Sieve.filter(T, invert(P))
  end),
  partition = pred(function(T, P)
    local Accept, Reject = { }, { }
    for I, V in pairs(T) do
      local R
      if P(V, I, T) then
        R = Accept
      else
        R = Reject
      end
      push(R, V)
    end
  end),
  test = pred(function(Callback, P)
    return function(...)
      if P(...) then
        return Callback(...)
      end
    end
  end),
  findChild = function(O, P)
    return Sieve.find(O:children(), P)
  end,
  filterChildren = function(O, P)
    return Sieve.filter(O:children(), P)
  end,
  Target = function(Fn)
    return function(...)
      return (Fn(...)), true
    end
  end,
  Any = function()
    return function()
      return true
    end
  end,
  Match = function(Input)
    local _exp_0 = type(Input)
    if 'string' == _exp_0 or 'number' == _exp_0 or 'boolean' == _exp_0 or 'userdata' == _exp_0 then
      return function(Value, Index, Table)
        return Value == Input
      end
    elseif 'function' == _exp_0 then
      return function(...)
        return (Input(...)) and true
      end
    elseif 'table' == _exp_0 then
      if isArray(Input) then
        return function(Value)
          return (Sieve.indexOfValue(Input, Value)) and true
        end
      end
      return function(Value, Index, Table)
        do
          local t = Input.type
          if t then
            local Test = Sieve.Match(t)
            if not (Test(type(Value))) then
              return 
            end
          end
        end
        do
          local i = Input.index
          if i then
            local Test = Sieve.match(i)
            if not (Test(Index)) then
              return 
            end
          end
        end
        do
          local p = Input.passes
          if p then
            if not (p(Value, Index, Table)) then
              return 
            end
          end
        end
        return true
      end
    end
  end,
  scan = function(Input, Rules)
    local RuleCount = #Rules
    if RuleCount == 0 then
      table.insert(Rules, function()
        return true
      end)
    end
    local Index = 1
    local RuleIndex = 1
    local BestMatch = nil
    local Length = #Input
    while Index <= Length do
      local I = Index
      local V = Input[I]
      local Rule = Rules[RuleIndex]
      if not (Rule) then
        return nil
      end
      if (type(Rule)) ~= 'function' then
        Rule = Sieve.Match(Rule)
        Rules[RuleIndex] = Rule
      end
      local isMatch, isTarget = Rule(V, I, Input)
      if isMatch then
        if isTarget then
          BestMatch = {
            key = I,
            value = V
          }
        end
        if RuleIndex == RuleCount and BestMatch then
          return BestMatch
        end
        RuleIndex = RuleIndex + 1
      else
        Index = Index - RuleIndex
        RuleIndex = 1
        Index = Index + 1
        BestMatch = nil
      end
      Index = Index + 1
    end
  end
}
return setmetatable(Sieve, {
  __call = function(self, T, P)
    return Sieve.filter(T, P)
  end
})
