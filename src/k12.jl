# The KangarroTwelve function works on Byte arrays, so we need to turn things into Byte arrays
# C's version of Byte arrays (unsigned char*) cooresponds to Julia's  Array{UInt8,1}

# This version works on isbits types. We will need to overload it at non isbits type.
"""
     anyToByteArray(x::T)::Vector{UInt8} where {T}
Turn a value into a Vector{UInt8}.
"""
function anyToByteArray(x::T)::Vector{UInt8} where {T}
    [ c for c = reinterpret(UInt8,[x])]
end

# Specialized to AbstractString
function anyToByteArray(x::AbstractString)::Vector{UInt8} where {T}
    Vector{UInt8}(x)
end

"""
    K12(input::T; custom::String="")::Int128 where T
Hash a T object into a Int128
"""
function K12(input::Vector{UInt8}; custom::String="" )
    output = Vector{UInt8}(undef,16)  #Allocate enough to store 128 bits
    customArr = Vector{UInt8}(custom)
    ccall((:KangarooTwelve, libk12),
          Cint,
          (Ref{Cuchar},Cint,Ref{Cuchar},Cint,Ref{Cuchar},Cint),
          input,length(input),
          output,16,  # The size is a constant in this call, see the definition of output above.
          customArr,length(customArr))
    reinterpret(UInt128,output)[1]   #Turn the 128 bits into an Int128
end

function K12(input::T; custom::String="") where {T}
    K12(anyToByteArray(input) ; custom=custom)
end

export K12
