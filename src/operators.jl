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

    # Two arguments
    for op in (:(Base.:(==)), :(Base.:<))
        @eval $op(x::Symbolic, y) = @_call $verbose $op (x, y) $op(x, Symbolic(y))
        @eval $op(x, y::Symbolic) = @_call $verbose $op (x, y) $op(Symbolic(x), y)
    end

    ### Dressed return values

    # Two arguments
    for op in (:(Base.:+), :(Base.:-), :(Base.:*), :(Base.:/), :(Base.:\), :(Base.://), :(Base.:^))
        @eval $op(x::Symbolic, y)::Symbolic = @_call $verbose $op (x, y) $op(x, Symbolic(y))
        @eval $op(x, y::Symbolic)::Symbolic = @_call $verbose $op (x, y) $op(Symbolic(x), y)
    end

    # Needs special treatment
    Base.:^(x::Symbolic, y::Integer)::Symbolic = x ^ Symbolic(y)

end
