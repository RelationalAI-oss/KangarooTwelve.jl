using Test
import KangarooTwelve

# The following is a transliteration of XKCP's Python KangarooTwelve implementation.
# Specifically, this file contains a transliteration of K12-test.py; the accompanying
# implementation, KangarooTwelve.py, was transliterated into ../src/KangarooTwelve.jl. The
# original can be found at the following location:
#
# https://github.com/XKCP/XKCP/blob/
#   66121748b9fbff3641d51374d117e349c3db94f3/Standalone/KangarooTwelve/Python/K12-test.py

using Printf

function generate_simple_raw_material(length, seed1, seed2)
    seed2 = seed2 % 8
    return UInt8[((seed1 + 161*length - ((i % 256) << seed2) - ((i % 256) >> (8 - seed2)) + i) % 256)
        for i in 0:(length - 1)]
end

const customization_byte_size = 32

function perform_test_kangaroo_twelve_one_input(input_len, output_len, custom_len)
    customization_string = generate_simple_raw_material(customization_byte_size, custom_len, 97)
    customization_string = customization_string[1:custom_len]
    input_message = generate_simple_raw_material(input_len, output_len, input_len + custom_len)
    @printf("output_len %5d, input_len %5d, custom_len %5d\n", output_len, input_len, custom_len)
    output = KangarooTwelve.kangaroo_twelve(input_message, customization_string, output_len)
    println("Kangaroo-Twelve")
    @printf("Input of %d bytes:\n", input_len)
    for i in 1:min(input_len, 16)
        @printf(" %02x\n", input_message[i])
    end
    if input_len > 16
        println(" ...")
    end
    println()
    @printf("Output of %d byte:", output_len)
    for i in 1:output_len
        print(" %02x", output[i])
    end
    println()
    println()
end

function perform_test_kangaroo_twelve()
    c_block_size = 8192
    output_len = div(256, 8)
    custom_len = 0
    for input_len in 0:(c_block_size*9 + 124 - 1)
        perform_test_kangaroo_twelve_one_input(input_len, output_len, custom_len)
    end

    output_len = div(128, 8)
    while output_len <= div(512, 8)
        input_len = 0
        while input_len <= 3*c_block_size
            perform_test_kangaroo_twelve_one_input(input_len, output_len, custom_len)
            custom_len += 7
        end
        input_len = input_len > 0 ? (input_len + 167) : 1
    end
    output_len = output_len * 2
end

function perform_short_test_kangaroo_twelve()
    c_block_size = 8192
    output_len = div(256, 8)
    custom_len = 0
    for input_len in 0:3
        perform_test_kangaroo_twelve_one_input(input_len, output_len, custom_len)
    end
    perform_test_kangaroo_twelve_one_input(27121, output_len, custom_len)
end

# perform_test_kangaroo_twelve()
# perform_short_test_kangaroo_twelve()

function output_hex(s)
    for i in 1:length(s)
        @printf("%02x ", s[i])
    end
    println()
    println()
end

function print_test_vectors()
    println("kangaroo_twelve(M=empty, C=empty, 32 output bytes):")
    output_hex(KangarooTwelve.kangaroo_twelve(UInt8[], UInt8[], 32))
    println("kangaroo_twelve(M=empty, C=empty, 64 output bytes):")
    output_hex(KangarooTwelve.kangaroo_twelve(UInt8[], UInt8[], 64))
    println("kangaroo_twelve(M=empty, C=empty, 10032 output bytes), last 32 bytes:")
    output_hex(KangarooTwelve.kangaroo_twelve(UInt8[], UInt8[], 10032)[10001:end])
    for i in 0:6
        C = Vector{UInt8}()
        M = UInt8[(j % 251) for j in 0:(17^i - 1)]
        @printf("kangaroo_twelve(M=pattern 0x00 to 0xFA for 17^%d bytes, C=empty, 32 output bytes):\n", i)
        output_hex(KangarooTwelve.kangaroo_twelve(M, C, 32))
    end
    for i in 0:3
        M = UInt8[0xFF for j in 0:(2^i-1 - 1)]
        C = UInt8[(j % 251) for j in 0:(41^i - 1)]
        print("kangaroo_twelve(M=%d times byte 0xFF, C=pattern 0x00 to 0xFA for 41^%d bytes, 32 output bytes):\n", 2^i-1, i)
        output_hex(KangarooTwelve.kangaroo_twelve(M, C, 32))
    end
end

# print_test_vectors()
