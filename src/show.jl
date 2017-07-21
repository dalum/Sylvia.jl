show_prefix = ""
show_suffix = ""
function setshow(prefix, suffix)
    global show_prefix, show_suffix
    show_prefix = prefix
    show_suffix = suffix
    println("Symbolic types printed as print(Symbolic(x)) -> $(show_prefix)x$(show_suffix)")
end

Base.show(io::IO, x::Symbolic) = print(io, "$show_prefix$(x.value)$show_suffix")
