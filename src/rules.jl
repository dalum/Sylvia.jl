let w = S"w::Wild{Any}"
    @! w == w = true
    @! zero(zero(w)) = zero(w)
    @! one(one(w)) = one(w)
end

let w = S"w::Wild{Number}"
    @! (+)(w) = w
    @! (*)(w) = w
end

let w = S"w::Wild{Bool}"
    @! (|)(w) = w
    @! (&)(w) = w
end

# Create a new context for user rules
const USER_CONTEXT = Context(GLOBAL_CONTEXT)
ACTIVE_CONTEXT[] = USER_CONTEXT
