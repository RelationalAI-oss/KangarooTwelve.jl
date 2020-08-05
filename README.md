# KangarooTwelve.jl

A Julia implementation of the KangarooTwelve algorithm, presently a transliteration of [XKCP's Python implementation of the same](https://github.com/XKCP/XKCP/tree/66121748b9fbff3641d51374d117e349c3db94f3/Standalone/KangarooTwelve/Python).

## Usage

```julia
julia> import KangarooTwelve

julia> input_bytes = UInt8[8, 6, 7, 5]
4-element Array{UInt8,1}:
 0x08
 0x06
 0x07
 0x05

julia> customization_bytes = UInt8[3, 0, 9]
3-element Array{UInt8,1}:
 0x03
 0x00
 0x09

julia> output_byte_length = 16
16

julia> KangarooTwelve.kangaroo_twelve(input_bytes, customization_bytes, output_byte_length)
16-element Array{UInt8,1}:
 0x58
 0x90
 0xbf
 0xac
 0x60
 0x42
 0x18
 0x01
 0xad
 0xfd
 0x1c
 0x89
 0xce
 0x5d
 0x0f
 0xf1
```