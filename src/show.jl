const ANNOTATE = Ref(false)

function Base.show(io::IO, x::T) where {T <: Sym}
    e = expr(x, annotate=ANNOTATE[])
    print(io, sprint(print, e, context=io))
end

function set_annotations(yes::Bool)
    ANNOTATE[] = yes
end
