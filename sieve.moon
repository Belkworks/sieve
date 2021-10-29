
Sieve = nil

pop = table.remove
push = table.insert

pred = (Fn) -> (T, P) -> Fn T, Sieve.predicate P
invert = (Fn) -> (...) -> not Fn ...

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

isArray = (T) ->
	#T == #[K for K in pairs T]

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

	findValue: (T, V) ->
		Sieve.find T, (R) -> R == V

	indexOf: (T, P) -> 
		V, I = Sieve.find T, P
		I

	indexOfValue: (T, V) ->
		Sieve.indexOf T, (R) -> R == V

	exists: (T, P) ->
		(Sieve.indexOf T, P) != nil

	valueExists: (T, V) ->
		(Sieve.indexOfValue T, V) != nil

	filter: pred (T, P) ->
		[V for I, V in pairs T when P V, I, T]

	reject: pred (T, P) -> Sieve.filter T, invert P

	partition: pred (T, P) ->
		Accept, Reject = {}, {}
		for I, V in pairs T
			R = if P V, I, T
				Accept
			else Reject
			push R, V

	test: pred (Callback, P) ->
		(...) -> Callback ... if P ...

	findChild: (O, P) -> Sieve.find O\children!, P
	filterChildren: (O, P) -> Sieve.filter O\children!, P

	Target: (Fn) ->
		(...) -> (Fn ...), true

	Any: -> -> true

	Match: (Input) ->
		switch type Input
			when 'string', 'number', 'boolean', 'userdata'
				(Value, Index, Table) -> Value == Input

			when 'function'
				(...) -> (Input ...) and true

			when 'table'
				if isArray Input
					return (Value) ->
						(Sieve.indexOfValue Input, Value) and true

				(Value, Index, Table) ->
					if t = Input.type
						Test = Sieve.Match t
						return unless Test type Value

					if i = Input.index
						Test = Sieve.match i
						return unless Test Index

					if p = Input.passes
						return unless p Value, Index, Table

					true

	scan: (Input, Rules) ->
		RuleCount = #Rules
		if RuleCount == 0
			table.insert Rules, -> true

		Index = 1
		RuleIndex = 1
		BestMatch = nil

		Length = #Input
		while Index <= Length
			I = Index
			V = Input[I]

			Rule = Rules[RuleIndex]
			return nil unless Rule

			if (type Rule) != 'function'
				Rule = Sieve.Match Rule
				Rules[RuleIndex] = Rule
			
			isMatch, isTarget = Rule V, I, Input
			if isMatch
				if isTarget
					BestMatch = key: I, value: V

				if RuleIndex == RuleCount and BestMatch
					return BestMatch

				RuleIndex += 1
			else
				Index -= RuleIndex
				RuleIndex = 1
				Index += 1
				BestMatch = nil

			Index += 1
}

setmetatable Sieve, __call: (T, P) => Sieve.filter T, P
