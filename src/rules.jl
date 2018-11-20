@scope GLOBAL_CONTEXT let
    @sym [Wild{Any}] x y

    @! set x == y         --> y == x
    @! set x == x         --> true
    @! set zero(zero(x))  --> zero(x)
    @! set one(one(x))    --> one(x)
end

@scope GLOBAL_CONTEXT let
    @sym [Wild{Number}] x y [Wild{AbstractMatrix}] X Y

    @! set (+)(x) --> x
    @! set (*)(x) --> x

    @! set x + y --> y + x
    @! set x*y   --> y*x

    @! set commuteswith(+, x, y) --> true
    @! set commuteswith(+, X, y) --> true
    @! set commuteswith(+, x, Y) --> true
    @! set commuteswith(+, X, Y) --> true

    @! set commuteswith(*, x, y) --> true
    @! set commuteswith(*, X, y) --> true
    @! set commuteswith(*, x, Y) --> true
end

@scope GLOBAL_CONTEXT let
    @sym [Wild{Bool}] x y

    @! set (|)(x) --> x
    @! set (&)(x) --> x

    @! set commuteswith(&, x, y) --> true
    @! set commuteswith(|, x, y) --> true
end
