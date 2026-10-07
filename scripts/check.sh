#!/bin/zsh
set -euo pipefail

export DEVELOPER_DIR="${DEVELOPER_DIR:-$HOME/Applications/Xcode.app/Contents/Developer}"

root="${0:A:h:h}"
cd "$root"

sources=(
    Niversario
    Packages/BirthdayKit/Package.swift
    Packages/BirthdayKit/Sources
    Packages/BirthdayKit/Tests
)

echo "==> swift format"
swift format format --in-place --recursive --parallel "${sources[@]}"

echo "==> swift format lint --strict"
swift format lint --strict --recursive --parallel "${sources[@]}"

echo "==> swift test"
swift test --package-path Packages/BirthdayKit -Xswiftc -warnings-as-errors

echo "==> OK"
