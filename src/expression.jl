getsymbols(x::Symbolic) = getsymbols(x.value)
getsymbols(::Number) = Set(Symbol[])
getsymbols(x::Symbol) = Set(Symbol[x])
getsymbols(A::AbstractArray) = mapreduce(getsymbols, union, A)
getsymbols(x::Expr) = getsymbols(Val{x.head}, x.args)
getsymbols(::Any, args) = mapreduce(getsymbols, union, args)
getsymbols(::Type{Val{:call}}, args) = mapreduce(getsymbols, union, args[2:end])

hassymbols(x::Symbolic) = hassymbols(x.value)
hassymbols(::Number) = false
hassymbols(::Symbol) = true
hassymbols(x::Expr) = hassymbols(Val{x.head}, x.args)
hassymbols(::Any, args) = any(map(hassymbols, args))
hassymbols(::Type{Val{:call}}, args) = any(map(hassymbols, args[2:end]))

firstsymbol(x::Symbolic, d) = firstsymbol(x.value, d)
firstsymbol(x, d=nothing) = (s = _firstsymbol(x)) == nothing ? d : s

_firstsymbol(x) = nothing
_firstsymbol(x::Symbol) = x
_firstsymbol(x::AbstractArray) = for arg in x
    (s = _firstsymbol(arg)) != nothing && return s
end # else return nothing
_firstsymbol(x::Expr) = _firstsymbol(Val{x.head}, x.args)
_firstsymbol(::Any, args) = _firstsymbol(args)
_firstsymbol(::Type{Val{:call}}, args) = _firstsymbol(args[2:end])

split_expr(x, f::Symbol) = _split_expr(x, f)
split_expr(x::Expr, f::Symbol) = _split_expr(Val{x.head}, x, f)

_split_expr(x, f::Symbol) = (x, idelemr(Val{f}))
_split_expr(::Any, x, f::Symbol) = _split_expr(x, f)
function _split_expr(::Type{Val{:call}}, x::Expr, f::Symbol)
    x.args[1] != f && return _split_expr(x, f)
    length(x.args[2:end]) == 2 && return x.args[2:end]
    (x.args[2], Expr(:call, f, x.args[3:end]...))
end

unroll_expr(x, ::Symbol) = [x]
unroll_expr(x::Expr, f::Symbol) = x.args[1] == f ? x.args[2:end] : [x]

mulsort(a, i) = begin
    a isa Number ? (i, a) : (a, i)
end


function addcollect(x)
    if length(x) == 0
        return 0
    end
    if length(x) == 1
        return x[1]
    end
    Expr(:call, :+, x...)
end

addunroll(x) = x
function addunroll(x::Expr)
    isneg(x) && return map(neg, unroll_expr(x.args[2], :+))

    x = unroll_expr(x, :-)
    length(x) == 1 && return unroll_expr(x[1], :+)
    length(x) == 2 && return [unroll_expr(x[1], :+);
                              map(neg, unroll_expr(x[2], :+))]
end


function mulcollect(x)
    if length(x) == 0
        return 1
    end
    if length(x) == 1
        return x[1]
    end
    Expr(:call, :*, x...)
end

function mulunroll(x)
    x = unroll_expr(x, :/)
    length(x) == 1 && return unroll_expr(x[1], :*)
    length(x) == 2 && return [unroll_expr(x[1], :*);
                              map(inv, reverse(unroll_expr(x[2], :*)))]
end
