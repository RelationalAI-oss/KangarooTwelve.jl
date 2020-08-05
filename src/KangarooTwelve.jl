module KangarooTwelve

# The following is a transliteration of XKCP's Python KangarooTwelve implementation.
# Specifically, this file contains a transliteration of K12.py; the accompanying
# test suite, K12-test.py, was transliterated into ../test/runtests.jl. The
# original can be found at the following location:
#
# https://github.com/XKCP/XKCP/blob/
#   66121748b9fbff3641d51374d117e349c3db94f3/Standalone/KangarooTwelve/Python/K12.py

function ROL64(a, n)
    return ((a >> (64 - (n % 64))) + (a << (n % 64))) % (Int128(1) << 64)
end

function keccak_p1600_on_lanes(lanes, n_rounds)
    R = 1
    for round in 0:23
        if (round + n_rounds >= 24)
            # θ
            C = [xor(lanes[x+1][1], lanes[x+1][2], lanes[x+1][3], lanes[x+1][4], lanes[x+1][5]) for x in 0:4]
            D = [xor(C[((x + 4) % 5) + 1], ROL64(C[((x + 1) % 5) + 1], 1)) for x in 0:4]
            lanes = [[xor(lanes[x+1][y+1], D[x+1]) for y in 0:4] for x in 0:4]
            # ρ and π
            (x, y) = (1, 0)
            current = lanes[x + 1][y + 1]
            for t in 0:23
                (x, y) = (y, (2*x+3*y)%5)
                (current, lanes[x + 1][y + 1]) = (lanes[x + 1][y + 1], ROL64(current, fld((t+1)*(t+2), 2)))
            end
            # χ
            for y in 0:4
                T = [lanes[x + 1][y + 1] for x in 0:4]
                for x in 0:4
                    lanes[x + 1][y + 1] = xor(T[x + 1], (~T[((x+1)%5) + 1]) & T[((x+2)%5) + 1])
                end
            end
            # ι
            for j in 0:6
                R = xor((R << 1), ((R >> 7)*0x71)) % 256
                if !iszero(R & 2)
                    lanes[1][1] = xor(lanes[1][1], (UInt128(1) << ((1<<j)-1)))
                end
            end
        else
            for j in 0:6
                R = xor((R << 1), ((R >> 7)*0x71)) % 256
            end
        end
    end
    return lanes
end

function load64(b)
    return sum((UInt128(b[i + 1]) << (8*i)) for i in 0:7)
end

function store64(a)
    return UInt8[(a >> (8*i)) % 256 for i in 0:7]
end

function keccack_p1600(state, n_rounds)
    lanes = [[load64(state[(8*(x+5*y) + 1):min(8*(x+5*y)+8, length(state))]) for y in 0:4] for x in 0:4]
    lanes = keccak_p1600_on_lanes(lanes, n_rounds)
    state = vcat(Vector{UInt8}[store64(lanes[x + 1][y + 1]) for y in 0:4 for x in 0:4]...)
    return Vector{UInt8}(state)
end

function F(input_bytes, delimited_suffix, output_byte_len)
    output_bytes = Vector{UInt8}()
    state = Vector{UInt8}([0 for i in 0:199])
    rate_in_bytes = fld(1344, 8)
    block_size = 0
    input_offset = 0
    # === Absorb all the input blocks ===
    while(input_offset < length(input_bytes))
        block_size = min(length(input_bytes) - input_offset, rate_in_bytes)
        for i in 0:(block_size - 1)
            state[i+1] = xor(state[i+1], input_bytes[i + input_offset + 1])
        end
        input_offset = input_offset + block_size
        if (block_size == rate_in_bytes)
            state = keccack_p1600(state, 12)
            block_size = 0
        end
    end
    # === Do the padding and switch to the squeezing phase ===
    state[block_size + 1] = xor(state[block_size + 1], delimited_suffix)
    if (((delimited_suffix & 0x80) != 0) && (block_size == (rate_in_bytes-1)))
        state = keccack_p1600(state, 12)
    end
    state[rate_in_bytes-1 + 1] = xor(state[rate_in_bytes-1 + 1], 0x80)
    state = keccack_p1600(state, 12)
    # === Squeeze out all the output blocks ===
    while(output_byte_len > 0)
        block_size = min(output_byte_len, rate_in_bytes)
        append!(output_bytes, state[1:block_size])
        output_byte_len = output_byte_len - block_size
        if (output_byte_len > 0)
            state = keccack_p1600(state, 12)
        end
    end
    return output_bytes
end

function right_encode(x)
    S = Vector{UInt8}()
    while (x > 0)
        pushfirst!(S, x % 256)
        x = fld(x, 256)
    end
    push!(S, length(S))
    return S
end

# comment from the original python code, helpful for inferring types later:
# "input_message and customization_string must be of type byte string or byte array"
function kangaroo_twelve(input_message, customization_string, output_byte_len)
    B = 8192
    c = 256
    S = vcat(Vector{UInt8}(input_message), Vector{UInt8}(customization_string), right_encode(length(customization_string)))
    # === Cut the input string into chunks of B bytes ===
    n = fld(length(S) + B - 1, B)
    Si = [Vector{UInt8}(S[(i*B + 1):min((i+1)*B, length(S))]) for i in 0:(n - 1)]
    if (n == 1)
        # === Process the tree with only a final node ===
        return F(Si[1], 0x07, output_byte_len)
    else
        # === Process the tree with kangaroo hopping ===
        CVi = [F(Si[i+1 + 1], 0x0B, fld(c, 8)) for i in 0:(n-1 - 1)]
        NodeStar = vcat(Si[1], UInt8[3,0,0,0,0,0,0,0], CVi..., right_encode(n-1), UInt8[0xFF, 0xFF])
        return F(NodeStar, 0x06, output_byte_len)
    end
end

end
