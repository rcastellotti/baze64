# Understanding base64 encoding and decoding

In order to understand how this works you first need to understand bitops[1].

## Spliting 8-bits chunks into 6-bits chunks

A combination of shifting and `bitwise-OR`-ing binary strings can be used to chunk an input.  
Base64 encoding transforms 3 chunks of 8-bit strings (bytes) in 4 chunks of 6-bits strings (sextets).  
Should the string not be divisible by 3 padding is added, and the shifts and OR-s change a bit [2].

Here's an example of the process using letters, it should be noted that the OR operation (|) is a sum in binary.

The `encode_3_bytes` function does the following:
```
// input:
// input[0]: AAAAAAAA (8 bits)
// input[1]: BBBBBBBB (8 bits)
// input[2]: CCCCCCCC (8 bits)

// goal:
// output[0]: AAAAAA (6 bits)
// output[1]: AABBBB (6 bits)
// output[2]: BBBBCC (6 bits)
// output[3]: CCCCCC (6 bits)

// output[0]: input[0] >> 2    -> extract the first 6 bits of input[0]: `AAAAAA`

// output[1]: (input[0] & 0x03) << 4 | input[1] >> 4
//             input[0] & 0x03 -> last 2 bits of input[0]: `AA`
//           (a) << 4          -> shift them left: `AA____`
//           (b) input[1] >> 4 -> first 4 bits of input[1]: `BBBB`
//             a | b = `AABBBBB`

// output[2]: (input[1] & 0x0f) << 2 | input[2] >> 6
//             input[1] & 0x0f -> last 4 bits of input[1]: `BBBB`
//           (a) << 2          -> shift them left: `BBBB__`
//           (b) input[2] >> 6 -> gets first 2 bits of input[2]: `CC`
//             a | b = `BBBBCC`

// output[3]: input[2] & 0x3f  -> extract last 6 bits of input[2]: `CCCCCC`
```

It is left as an exercise for the reader to understand the `encode_1_byte` and `encode_2_bytes` functions.


Note: *AND*-ing a string with a string with strategically placed `1`s can be used to extract bits from a string. 
In programming hex values are often used in bitops, note that:

+ 0x03 = 0b00000011
+ 0x0F = 0b00001111
+ 0x3F = 0b00111111

Additionally, remember that `0` bits to the left are not significant and can be omitted, this means that:

+ 0b11=0b0000011
+ 0b11=0b00000000000000000011

It is sometimes helpful to add enough zeroes to reach a `8-bit` number.


## Using the sextets 

Once the string has been split into sextets, they are used as indices in a specific alphabet 

[1]: https://en.wikipedia.org/wiki/Bitwise_operation
[2]: https://datatracker.ietf.org/doc/html/rfc4648#section-4