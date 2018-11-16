push!(LOAD_PATH,"../src/")

using Documenter
using Sylvia

makedocs(
    sitename = "Sylvia",
    format = :html,
    modules = [Sylvia],
    pages = [
        "Home" => "index.md"
        # "Basics" => "basics.md"
        "Symbols" => "symbols.md"
        "Expressions" => "expressions.md"
        "Contexts" => "contexts.md"
    ]
)

# Documenter can also automatically deploy documentation to gh-pages.
# See "Hosting Documentation" and deploydocs() in the Documenter manual
# for more information.
deploydocs(
    repo = "github.com/dalum/Sylvia.jl.git"
)
