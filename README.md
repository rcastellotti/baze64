# baze64

`baze64` is a simple base64 encoder/decoder to learn zig.

```bash
rc@bearbook ~/baze64 (main)> zig run src/main.zig -- --help
Usage: baze64 [options]

Options:
  --encode <string>    Encode the given string to base64
  --decode <string>    Decode the given base64 string
  -h, --help          Show this help message
```

# References

1. https://pedropark99.github.io/zig-book/Chapters/01-base64.html
2. https://datatracker.ietf.org/doc/html/rfc464
3. https://en.wikipedia.org/wiki/Base64
4. https://claude.ai