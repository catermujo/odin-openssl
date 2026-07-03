#!/usr/bin/env bash

set -euo pipefail

OPENSSL_REF="openssl-3.6.2"
OPENSSL_REMOTE="https://github.com/openssl/openssl.git"
OPENSSL_DIR="openssl"

linux_arch_dir() {
    case "$(uname -m)" in
        x86_64 | amd64) echo "linux_x64" ;;
        aarch64 | arm64) echo "linux_arm64" ;;
        *) echo "linux_$(uname -m)" ;;
    esac
}

darwin_arch_dir() {
    case "$(uname -m)" in
        x86_64 | amd64) echo "darwin_x64" ;;
        aarch64 | arm64) echo "darwin_arm64" ;;
        *) echo "darwin_$(uname -m)" ;;
    esac
}

host_output_dir() {
    case "$(uname -s)" in
        Darwin) darwin_arch_dir ;;
        Linux) linux_arch_dir ;;
        *)
            echo "unsupported host: $(uname -s)" >&2
            return 1
            ;;
    esac
}

cpu_count() {
    case "$(uname -s)" in
        Darwin) sysctl -n hw.ncpu ;;
        Linux) nproc ;;
        *) echo 1 ;;
    esac
}

ensure_checkout() {
    if [ ! -d "$OPENSSL_DIR/.git" ]; then
        git clone --depth=1 --branch "$OPENSSL_REF" "$OPENSSL_REMOTE" "$OPENSSL_DIR"
        return
    fi

    git -C "$OPENSSL_DIR" fetch --depth=1 origin "$OPENSSL_REF"
    git -C "$OPENSSL_DIR" checkout --detach FETCH_HEAD
}

reset_checkout() {
    git -C "$OPENSSL_DIR" reset --hard HEAD
    git -C "$OPENSSL_DIR" clean -fdx
}

copy_shared_artifacts() {
    local output_dir="$1"
    case "$(uname -s)" in
        Darwin)
            cp "libssl.3.dylib" "../$output_dir/"
            cp "libcrypto.3.dylib" "../$output_dir/"
            ;;
        Linux)
            cp "libssl.so.3" "../$output_dir/"
            cp "libcrypto.so.3" "../$output_dir/"
            ;;
    esac
}

main() {
    ensure_checkout

    local output_dir
    output_dir="$(host_output_dir)"
    mkdir -p "$output_dir"

    reset_checkout
    pushd "$OPENSSL_DIR" >/dev/null
    ./config no-tests shared
    make -j"$(cpu_count)"
    copy_shared_artifacts "$output_dir"
    popd >/dev/null
}

main "$@"
