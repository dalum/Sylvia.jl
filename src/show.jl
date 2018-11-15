const ANNOTATE = Ref(false)

function Base.show(io::IO, x::T) where {T <: Sym}
    e = expr(x, annotate=ANNOTATE[])
    if !get(io, :compact, false)
        print(io, "@! ")
    end
    print(io, sprint(print, e, context=io))
end

function Base.show_unquoted(io::IO, x::T, ::Int, precedence::Int) where {T <: Sym}
    print(io, "(")
    show(io, x)
    print(io, ")")
end

function set_annotations(yes::Bool)
    ANNOTATE[] = yes
end
