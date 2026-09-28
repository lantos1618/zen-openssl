# zen-openssl

OpenSSL-backed TLS for Zen. This package contains the `tls` module consumed by
[zen-http](https://github.com/lantos1618/zen-http). It is separate from the
native Zen algorithms in zen-crypto and the libsodium bindings in zen-sodium.
OpenSSL implements TLS records and cryptography; this is not a native Zen TLS
or cryptographic implementation.

`src/tls.zen` owns certificate-verification policy, client/server context lifetime,
ALPN selection and validation, and nonblocking retry decisions. It exports the
existing `TlsConnection`, `TlsFault`, `Transport` and `ServerContext` APIs.
The module remains named `tls`, so consumers change its build dependency path
without changing protocol imports. Existing `std.net.tls` callers are unchanged.

`src/zen_tls.h` supplies OpenSSL ABI accessors, session construction/cleanup,
and a Linux borrowed-socket BIO using `MSG_NOSIGNAL`. The latter preserves
abrupt-disconnect protection without changing the process signal handler. It
contains native I/O logic, not just declarations. It neither closes nor owns the
socket; callers retain sockets and keep retry buffers stable across TLS retries.
There are no handwritten cryptographic primitives in the adapter.

The client verifies certificate chains and hostnames. Private OpenSSL builds
need an explicit CA bundle (`SSL_CERT_FILE`/`SSL_CERT_DIR`); the macOS Keychain
is not loaded automatically. Graceful TLS shutdown, configurable policy and
client-context reuse remain follow-up work. This package remains experimental.

## Build

Keep compiler, zen-openssl and zen-http as sibling checkouts. Build pinned
OpenSSL 3.5.4 (`c1eeb9406b6142148f267594197d853403d10208`) locally:

```sh
sh scripts/build-openssl.sh
# Or put dependencies in the consuming package's ignored build directory:
sh scripts/build-openssl.sh "$PWD/../zen-http/build"
```

The builder installs static archives in `<destination>/openssl/lib` and headers
in `<destination>/openssl/include`; its default destination is `build/tls`.
It does not install system libraries or alter trust stores. It configures
OpenSSL with `no-tests`; passing consumer tests does not mean the upstream
OpenSSL test suite was executed.

Register `src/tls.zen` as a library named `tls` in the consumer's `build.zen`,
link `ssl` and `crypto`, and include both this package's `src` directory and
OpenSSL's include directory when compiling generated C. The maintained example
is the sibling zen-http build configuration.

## Verify

Integration coverage lives in zen-http and exercises actual plain/TLS clients,
trusted/untrusted certificates, HTTP/2 ALPN, nonblocking I/O, abrupt disconnects,
and UBSan. After preparing that package's compiler and test dependencies:

```sh
PYTHON=python3 sh scripts/check.sh
```

The wrapper runs the sibling HTTP suite; use a Python with TLS 1.3 support.
`ZEN_COMPILER`, `ZEN_STD`, `GO_BIN` and `PYTHON` are forwarded unchanged. These
checks do not establish production readiness, a security audit or a throughput
improvement. The initial extraction preserves the previous files byte-for-byte.
