# Global tables

struct AssumptionTable
    table::Dict
    age::UInt
end
function Base.setindex!(A::AssumptionTable, a, b)
    A.age += 1
    A.table[a] = b
    nothing
end
Base.get(A::AssumptionTable, a, d) = get(A.table, a, d)

AssumedTypes = AssumptionTable(Dict{Symbol, Type}(), 0)

function assumed_typeof(a::Symbolic)
    if a.atyp.age != AssumedTypes.age
        a.atyp.age = AssumedTypes.age
        a.atyp.typ = assumed_typeof(a.value)
    end
    a.atyp.typ
end

assumed_typeof(a) = typeof(a)
assumed_typeof(a::Symbol) = get(AssumedTypes, a, Any)
assumed_typeof(a::Expr) = get(AssumedTypes, a, Any)

# assumptions

macro assume(exprs::Expr...)
    for expr in exprs
        if expr.head === :(::)
            expr.head = :(=)
            expr.args = [Expr(:ref, :AssumedTypes, expr.args[1]), expr.args[2]]
        end
        if expr.head === :(=)
            expr.args[1].args[2] = Expr(:quote, expr.args[1].args[2])
            expr.args[2] = Expr(:escape, expr.args[2])
        end
    end
    Expr(:block, exprs...)
end
