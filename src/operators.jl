macro verbose_call(name, symbols, expr)
    esc(quote
        print("$($name)(", join($symbols, ", "), ")")
        retval = $expr
        println(" => $retval")
        retval
    end)
end

function define_operators(verbose::Bool)

    # One argument

    for (op, name) in ((:(Base.:+), identity), (:(Base.:-), neg), (:(Base.inv), inv),
                       (:(Base.conj), conj), (:(Base.transpose), transpose),
                       (:(Base.ctranspose), ctranspose))
        if verbose
            @eval $op(x::Symbolic)::Symbolic = @verbose_call $name (x,) Symbolic($name(x.value))
        else
            @eval $op(x::Symbolic)::Symbolic = Symbolic($name(x.value))
        end
    end

    # Two arguments

    for (op, name) in ((:(Base.:+), add), (:(Base.:-), sub), (:(Base.:*), mul), (:(Base.:/), div),
                       (:(Base.:\), idiv), (:(Base.://), rdiv), (:(Base.:^), pow))
        if verbose
            @eval $op(x::Symbolic, y)::Symbolic = @verbose_call $name (x, y) Symbolic($name(x.value, y))
            @eval $op(x, y::Symbolic)::Symbolic = @verbose_call $name (x, y) Symbolic($name(x, y.value))
            @eval $op(x::Symbolic, y::Symbolic)::Symbolic = @verbose_call $name (x, y) Symbolic($name(x.value, y.value))
        else
            @eval $op(x::Symbolic, y)::Symbolic = Symbolic($name(x.value, y))
            @eval $op(x, y::Symbolic)::Symbolic = Symbolic($name(x, y.value))
            @eval $op(x::Symbolic, y::Symbolic)::Symbolic = Symbolic($name(x.value, y.value))
        end
    end
    # Need special treatment
    for (op, name) in ((:(Base.:^), pow),)
        if verbose
            @eval $op(x::Symbolic, y::Integer)::Symbolic = @verbose_call $name (x, y) Symbolic($name(x.value, y))
        else
            @eval $op(x::Symbolic, y::Integer)::Symbolic = Symbolic($name(x.value, y))
        end
    end

    # Undressed return values

    for (op, name) in ((:(Base.:(==)), eq), (:(Base.:<), isless))
        if verbose
            @eval $op(x::Symbolic, y)::Bool = @verbose_call $name (x, y) $name(x.value, y)
            @eval $op(x, y::Symbolic)::Bool = @verbose_call $name (x, y) $name(x, y.value)
            @eval $op(x::Symbolic, y::Symbolic)::Bool = @verbose_call $name (x, y) $name(x.value, y.value)
        else
            @eval $op(x::Symbolic, y)::Bool = $name(x.value, y)
            @eval $op(x, y::Symbolic)::Bool = $name(x, y.value)
            @eval $op(x::Symbolic, y::Symbolic)::Bool = $name(x.value, y.value)
        end
    end

end
