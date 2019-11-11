__precompile__(true)

module KangarooTwelve

include("../deps/deps.jl")

include("k12.jl")

function __init__()
    check_deps()
end

end
