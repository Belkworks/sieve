
Sieve = nil

pop = table.remove

pred = (Fn) ->
	(T, P) -> Fn T, Sieve.predicate P

recurses = (Fn) ->
	(A, B, Seen = {}) ->
		return if Seen[B]
		Seen[B] = true
		Fn A, B, Seen

matches = nil
matches = (recurses (P, T, Seen) ->
	return unless T
	for I, V in pairs P
		D = T[I]
		Type = type V
		if Type == 'userdata' or Type == 'table'
			return unless matches V, D, Seen
		else return unless D == V

	true
)

partial = (Fn, ...) ->
	Args = { ... }
	(...) -> Fn (unpack Args), ...

Sieve = {
	predicate: (Any) ->
		switch type Any
			when 'function'
				Any
			when 'table'
				Sieve.matcher Any
			when 'string'
				Sieve.property Any

	property: (K) -> (T) -> T[K] != nil
	matcher: (P) -> (V) -> matches P, V

	find: pred (T, P) ->
		return V, I for I, V in pairs T when P V, I, T

	indexOf: (T, P) -> pop { Sieve.find T, P}

	filter: pred (T, P) ->
		[V for I, V in pairs T when P V, I, T]

	test: pred (Callback, P) ->
		(...) -> Callback ... if P ...

}

setmetatable Sieve, __call: (T, P) => Sieve.filter T, P
