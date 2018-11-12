let w = S"w::Wild{Any}"
    @set! w == w => true
    @set! zero(zero(w)) => zero(w)
    @set! one(one(w)) => one(w)
end

let w = S"w::Wild{Number}"
    @set! (+)(w) => w
    @set! (*)(w) => w
end

let w = S"w::Wild{Bool}"
    @set! (|)(w) => w
    @set! (&)(w) => w
end
