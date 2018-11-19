module Derivatives

using Sylvia

export derivative,
    a, b, c, d,
    ctx

const ctx = Sylvia.Context(Sylvia.@__context__)

function derivative end
Sylvia.@register ctx derivative 2

@sym [Number] a b c d

@scope ctx let
    @sym [Wild{Function}] f
    @sym [Wild{Number}] x y z

    @! set -(-x) --> x

    @! set derivative(f(x), y) --> derivative(f(x), x) * derivative(x, y)
    @! set derivative(x, x) --> 1
    @! set derivative(-x, y) --> -derivative(x, y)
    @! set derivative(x + y, z) --> derivative(x, z) + derivative(y, z)
    @! set derivative(x - y, z) --> derivative(x, z) - derivative(y, z)
    @! set derivative(x*y, z) --> derivative(x, z)*y + x*derivative(y, z)
    @! set derivative(x^y, x) --> y*x^(1 - y)
    @! set derivative(cos(x), x) --> -sin(x)
    @! set derivative(sin(x), x) --> cos(x)
end

end
