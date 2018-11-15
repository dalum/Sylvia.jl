let
    @sym [Wild{Any}] x

    @! set x == x = true
    @! set zero(zero(x)) = zero(x)
    @! set one(one(x)) = one(x)
end

let
    @sym [Wild{Number}] x y [Wild{AbstractMatrix}] X Y

    @! set (+)(x) = x
    @! set (*)(x) = x

    @! set commuteswith(+, x, y) = true
    @! set commuteswith(+, X, y) = true
    @! set commuteswith(+, x, Y) = true
    @! set commuteswith(+, X, Y) = true

    @! set commuteswith(*, x, y) = true
    @! set commuteswith(*, X, y) = true
    @! set commuteswith(*, x, Y) = true
end

let
    @sym [Wild{Bool}] x y

    @! set (|)(x) = x
    @! set (&)(x) = x

    @! set commuteswith(&, x, y) = true
    @! set commuteswith(|, x, y) = true
end

# Create a new context for user rules
const USER_CONTEXT = Context(GLOBAL_CONTEXT)
ACTIVE_CONTEXT[] = USER_CONTEXT
