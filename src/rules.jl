let
    @sym [Wild{Any}] x

    @! x == x = true
    @! zero(zero(x)) = zero(x)
    @! one(one(x)) = one(x)
end

let
    @sym [Wild{Number}] x y [Wild{AbstractMatrix}] X Y

    @! (+)(x) = x
    @! (*)(x) = x

    @! commuteswith(+, x, y) = true
    @! commuteswith(+, X, y) = true
    @! commuteswith(+, x, Y) = true
    @! commuteswith(+, X, Y) = true

    @! commuteswith(*, x, y) = true
    @! commuteswith(*, X, y) = true
    @! commuteswith(*, x, Y) = true
end

let
    @sym [Wild{Bool}] x y

    @! (|)(x) = x
    @! (&)(x) = x

    @! commuteswith(&, x, y) = true
    @! commuteswith(|, x, y) = true
end

# Create a new context for user rules
const USER_CONTEXT = Context(GLOBAL_CONTEXT)
ACTIVE_CONTEXT[] = USER_CONTEXT
