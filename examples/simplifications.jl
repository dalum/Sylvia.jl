module Simplifications

using Sylvia

export simplify

const base_ctx = Sylvia.Context(Sylvia.@__context__)
const ctx = Sylvia.Context(base_ctx)

function simplify end
Sylvia.@register ctx simplify 1

@sym [Number] a b c d

@scope base_ctx let
    @sym [Wild{Number}] x y z
    @! set simplify(x) --> x
end

@scope ctx let
    @sym [Wild{Number}] x y z
    _0 = @! 0::Number
    _1 = @! 1::Number

    @! set simplify(x*y) --> simplify(x)*simplify(y) |> simplify
    @! set simplify(x*y*z) --> simplify(x*y)*simplify(z) |> simplify
    @! set simplify(x + y) --> simplify(x) + simplify(y) |> simplify
    @! set simplify(x + y + z) --> simplify(x + y) + simplify(z) |> simplify
    @! set simplify(x*y + y) --> simplify(x + 1)*simplify(y) |> simplify
    @! set simplify(x*z + y*z) --> simplify(x + y)*simplify(z) |> simplify

    @! set simplify(x + x) --> 2simplify(x) |> simplify
    @! set simplify(x*x) --> simplify(x)^2 |> simplify
    @! set simplify(x*x*x) --> simplify(x*x)*simplify(x) |> simplify

    @! set simplify(x/x) --> _1
    @! set simplify(x/_1) --> simplify(x)

    @! set simplify(-x) --> -simplify(x)
    @! set simplify(-(-x)) --> simplify(x)

    @! set simplify(_0 + x) --> simplify(x)
    @! set simplify(x + _0) --> simplify(x)

    @! set simplify(_0*x) --> _0
    @! set simplify(x*_0) --> _0
    @! set simplify(_1*x) --> simplify(x)
    @! set simplify(x*_1) --> simplify(x)

    @! set simplify(x^_1) --> simplify(x)
end

end
