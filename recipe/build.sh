#!/usr/bin/env bash
set -euxo pipefail
export PYTHONDONTWRITEBYTECODE=1

if [[ "${target_platform}" == win-* ]]; then
    PYTHON="$(cygpath -u "${PYTHON}")"
    LIBRARY_LIB="$(cygpath -u "${LIBRARY_LIB}")"
fi

if [[ "${target_platform}" == win-* ]]; then
    extension=vec0.dll
    export SQLITE_INCLUDE_DIR="${LIBRARY_INC}"
elif [[ "${target_platform}" == osx-* ]]; then
    extension=vec0.dylib
    export SQLITE_INCLUDE_DIR="${PREFIX}/include"
else
    extension=vec0.so
    export SQLITE_INCLUDE_DIR="${PREFIX}/include"
fi

# The patched source builds the native library and a separate Python wheel.
SQLITE_VEC_BUNDLE=0 bash bindings/python/build.sh --no-build-isolation
if [[ "${target_platform}" == win-* ]]; then
    mkdir -p "${LIBRARY_LIB}/sqlite-vec"
    install -m 0755 "dist/${extension}" "${LIBRARY_LIB}/sqlite-vec/${extension}"
else
    mkdir -p "${PREFIX}/lib/sqlite-vec"
    install -m 0755 "dist/${extension}" "${PREFIX}/lib/sqlite-vec/vec0.so"
    if [[ "${target_platform}" == osx-* ]]; then
        "${INSTALL_NAME_TOOL}" -id "@rpath/sqlite-vec/vec0.so" "${PREFIX}/lib/sqlite-vec/vec0.so"
    fi
fi

"${PYTHON}" -m pip install dist/sqlite_vec-*-py3-none-any.whl --no-deps --no-index --no-compile -v
