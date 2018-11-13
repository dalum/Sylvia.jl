let w = sym(Wild{Any}, :w)
    @! w == w = true
    @! zero(zero(w)) = zero(w)
    @! one(one(w)) = one(w)
end

let w = sym(Wild{Number}, :w)
    @! (+)(w) = w
    @! (*)(w) = w
end

let w = sym(Wild{Bool}, :w)
    @! (|)(w) = w
    @! (&)(w) = w
end

# Create a new context for user rules
const USER_CONTEXT = Context(GLOBAL_CONTEXT)
ACTIVE_CONTEXT[] = USER_CONTEXT
