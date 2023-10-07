#!/usr/bin/env bash
set -eou pipefail

# check args
PROJECT_NAME="${1-}"
if [ -z "$PROJECT_NAME" ]; then
    echo "Usage: $0 <project_name>" >&2
    exit 1
fi

# check vcpkg
if ! command -v vcpkg > /dev/null 2>&1; then
    echo "vcpkg not found in PATH" >&2
    exit 1
fi
VCPKG_ROOT="$(dirname "$(which vcpkg)")"

# create dir
mkdir "$PROJECT_NAME"
cd "$PROJECT_NAME"

# CMakeLists.txt
cat << EOF > CMakeLists.txt
cmake_minimum_required(VERSION 3.10)
project($PROJECT_NAME)

find_package(fmt REQUIRED)

file(GLOB SRCS src/*.cpp src/*.c)
add_executable(\${PROJECT_NAME} \${SRCS})
target_compile_features(\${PROJECT_NAME} PUBLIC cxx_std_17)
target_link_libraries(\${PROJECT_NAME}
PRIVATE
    fmt::fmt
)
EOF

# src/main.cpp
mkdir "src"
cat << EOF > src/main.cpp
#include <fmt/format.h>

int main() {
fmt::print("It works!\n");
return 0;
}
EOF

# vcpkg.json
cat << EOF > vcpkg.json
{
"dependencies": [
    "fmt"
]
}
EOF

# configure
SANITIZER_FLAGS="-fsanitize=address -fno-omit-frame-pointer"
cmake \
    -Bbuild \
    -DCMAKE_BUILD_TYPE=Debug \
    -DCMAKE_TOOLCHAIN_FILE="$VCPKG_ROOT/scripts/buildsystems/vcpkg.cmake" \
    -DCMAKE_EXPORT_COMPILE_COMMANDS=1 \
    -DCMAKE_C_FLAGS="$SANITIZER_FLAGS" \
    -DCMAKE_CXX_FLAGS="$SANITIZER_FLAGS" \
    -DCMAKE_EXE_LINKER_FLAGS="$SANITIZER_FLAGS" \
    -L

# build
cmake --build build

