using Sylvia
using Base.Test

# write your own tests here
@test :a + :b == :(a + b)
@test :a - :b == :(a - b)
@test :a * :b == :(a * b)
@test :a / :b == :(a / b)
