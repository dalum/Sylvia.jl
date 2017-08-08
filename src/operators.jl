macro _call(verbose, name, symbols, expr)
    if eval(verbose)
        return esc(quote
                   print("$($name)(", join($symbols, ", "), ")")
                   retval = $expr
                   println(" => $retval")
                   retval
                   end)
    else
        return esc(expr)
    end
end

function define_operators(verbose::Bool)

    ### Undressed return values

    # One argument
    for (op, name) in ((:(Base.hash), hash),)
        @eval $op(x::Symbolic) = @_call $verbose $name (x,) $name(x.value)
    end

    # Two arguments
    for (op, name) in ((:(Base.:(==)), eq), (:(Base.:<), isless))
        @eval $op(x::Symbolic, y) = @_call $verbose $name (x, y) $name(x.value, y)
        @eval $op(x, y::Symbolic) = @_call $verbose $name (x, y) $name(x, y.value)
        @eval $op(x::Symbolic, y::Symbolic) = @_call $verbose $name (x, y) $name(x.value, y.value)
    end

    ### Dressed return values

    # One argument
    for (op, name) in ((:(Base.:+), identity), (:(Base.:-), neg), (:(Base.inv), inv),
                       (:(Base.conj), conj), (:(Base.transpose), transpose),
                       (:(Base.ctranspose), ctranspose))
        @eval $op(x::Symbolic)::Symbolic = @_call $verbose $name (x,) $name(x.value)
    end

    # Two arguments
    for (op, name) in ((:(Base.:+), add), (:(Base.:-), sub), (:(Base.:*), mul), (:(Base.:/), div),
                       (:(Base.:\), idiv), (:(Base.://), rdiv), (:(Base.:^), pow))
        @eval $op(x::Symbolic, y)::Symbolic = @_call $verbose $name (x, y) $name(x.value, y)
        @eval $op(x, y::Symbolic)::Symbolic = @_call $verbose $name (x, y) $name(x, y.value)
        @eval $op(x::Symbolic, y::Symbolic)::Symbolic = @_call $verbose $name (x, y) $name(x.value, y.value)
    end

    # Needs special treatment
    for (op, name) in ((:(Base.:^), pow),)
        @eval $op(x::Symbolic, y::Integer)::Symbolic = @_call $verbose $name (x, y) $name(x.value, y)
    end

end
