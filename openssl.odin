package openssl

import "core:c"
import "core:c/libc"

when ODIN_OS == .Windows {
    LINK :: #config(OPENSSL_LINK, "shared")
} else {
    LINK :: #config(OPENSSL_LINK, "system")
}

when ODIN_OS == .Windows {
    when ODIN_ARCH == .amd64 {
        when LINK == "shared" {
            foreign import lib {"windows_x64/libssl.lib", "windows_x64/libcrypto.lib"}
        } else when LINK == "static" {
            foreign import lib {"windows_x64/libssl_static.lib", "windows_x64/libcrypto_static.lib", "system:ws2_32.lib", "system:gdi32.lib", "system:advapi32.lib", "system:crypt32.lib", "system:user32.lib"}
        } else {
            #panic("vendor/openssl does not support system link on Windows")
        }
    } else when ODIN_ARCH == .arm64 {
        when LINK == "shared" {
            foreign import lib {"windows_arm64/libssl.lib", "windows_arm64/libcrypto.lib"}
        } else when LINK == "static" {
            foreign import lib {"windows_arm64/libssl_static.lib", "windows_arm64/libcrypto_static.lib", "system:ws2_32.lib", "system:gdi32.lib", "system:advapi32.lib", "system:crypt32.lib", "system:user32.lib"}
        } else {
            #panic("vendor/openssl does not support system link on Windows")
        }
    } else {
        #panic("vendor/openssl supports windows amd64/arm64 only")
    }
} else when ODIN_OS == .Darwin {
    when ODIN_ARCH == .amd64 {
        when LINK == "shared" {
            foreign import lib {"darwin_x64/libssl.3.dylib", "darwin_x64/libcrypto.3.dylib"}
        } else when LINK == "static" {
            foreign import lib {"darwin_x64/libssl.darwin.a", "darwin_x64/libcrypto.darwin.a"}
        } else {
            foreign import lib {"system:ssl.3", "system:crypto.3"}
        }
    } else when ODIN_ARCH == .arm64 {
        when LINK == "shared" {
            foreign import lib {"darwin_arm64/libssl.3.dylib", "darwin_arm64/libcrypto.3.dylib"}
        } else when LINK == "static" {
            foreign import lib {"darwin_arm64/libssl.darwin.a", "darwin_arm64/libcrypto.darwin.a"}
        } else {
            foreign import lib {"system:ssl.3", "system:crypto.3"}
        }
    } else {
        #panic("vendor/openssl supports Darwin amd64/arm64 only")
    }
} else when ODIN_OS == .Linux {
    when ODIN_ARCH == .amd64 {
        when LINK == "shared" {
            foreign import lib {"linux_x64/libssl.so.3", "linux_x64/libcrypto.so.3"}
        } else when LINK == "static" {
            foreign import lib {"linux_x64/libssl.linux.a", "linux_x64/libcrypto.linux.a"}
        } else {
            foreign import lib {"system:ssl", "system:crypto"}
        }
    } else when ODIN_ARCH == .arm64 {
        when LINK == "shared" {
            foreign import lib {"linux_arm64/libssl.so.3", "linux_arm64/libcrypto.so.3"}
        } else when LINK == "static" {
            foreign import lib {"linux_arm64/libssl.linux.a", "linux_arm64/libcrypto.linux.a"}
        } else {
            foreign import lib {"system:ssl", "system:crypto"}
        }
    } else {
        #panic("vendor/openssl supports Linux amd64/arm64 only")
    }
}

Version :: bit_field u32 {
    pre_release: uint | 4,
    patch:       uint | 16,
    minor:       uint | 8,
    major:       uint | 4,
}

VERSION: Version

@(private, init)
// #+vet redundancy public-api
version_check :: proc "contextless" () {
    VERSION = Version(OpenSSL_version_num())
    assert_contextless(VERSION.major == 3, "invalid OpenSSL library version, expected 3.x")
}

SSL_METHOD :: struct {}
SSL_CTX :: struct {}
SSL :: struct {}

SSL_CTRL_SET_TLSEXT_HOSTNAME :: 55

TLSEXT_NAMETYPE_host_name :: 0

foreign lib {
    TLS_client_method :: proc() -> ^SSL_METHOD ---
    SSL_CTX_new :: proc(method: ^SSL_METHOD) -> ^SSL_CTX ---
    SSL_new :: proc(ctx: ^SSL_CTX) -> ^SSL ---
    SSL_set_fd :: proc(ssl: ^SSL, fd: c.int) -> c.int ---
    SSL_connect :: proc(ssl: ^SSL) -> c.int ---
    SSL_get_error :: proc(ssl: ^SSL, ret: c.int) -> c.int ---
    SSL_read :: proc(ssl: ^SSL, buf: [^]byte, num: c.int) -> c.int ---
    SSL_write :: proc(ssl: ^SSL, buf: [^]byte, num: c.int) -> c.int ---
    SSL_free :: proc(ssl: ^SSL) ---
    SSL_CTX_free :: proc(ctx: ^SSL_CTX) ---
    ERR_print_errors_fp :: proc(fp: ^libc.FILE) ---
    SSL_ctrl :: proc(ssl: ^SSL, cmd: c.int, larg: c.long, parg: rawptr) -> c.long ---
    OpenSSL_version_num :: proc() -> c.ulong ---
}

// This is a macro in c land.
SSL_set_tlsext_host_name :: proc(ssl: ^SSL, name: cstring) -> c.int {
    return c.int(SSL_ctrl(ssl, SSL_CTRL_SET_TLSEXT_HOSTNAME, TLSEXT_NAMETYPE_host_name, rawptr(name)))
}

// #+vet redundancy public-api
ERR_print_errors :: proc {
    ERR_print_errors_fp,
    ERR_print_errors_stderr,
}

// #+vet redundancy public-api
ERR_print_errors_stderr :: proc() {
    ERR_print_errors_fp(libc.stderr)
}
