#!/bin/sh

readonly tools_path="$( cd "$( dirname "$0" )" && pwd )"
readonly root_path="$( cd "${tools_path}/../" && pwd )"

readonly product_name="tuist-dependency-generator"

readonly build_path=".build"
readonly product_path="${build_path}/apple/Products/Release/${product_name}"

build() {
    swift package clean
    swift build --disable-sandbox -c release --arch arm64 --arch x86_64
}

release() {
    cp -f $product_path .
    rm -rf $build_path
}

cd $root_path
build
release
