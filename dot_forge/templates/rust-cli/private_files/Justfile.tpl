set positional-arguments

default:
    just --list

fmt:
    cargo clippy --fix --bin "{{ forge.project.name }}"
    cargo fmt --all
    cargo spaced

lint:
    cargo fmt -- --check
    cargo spaced --check
    cargo clippy --all-targets -- -D warnings
    cargo xwin clippy --all-targets -- -D warnings

test:
    cargo nextest run --all --no-tests=pass
    cargo xwin test --all --target x86_64-pc-windows-msvc

verify-release:
    just lint
    just test

run *args:
    cargo run --bin "{{ forge.project.name }}" -- %{{args}}%


prepare version:
    scripts/release/prepare.sh %{{version}}%

promote:
    scripts/release/promote.sh

publish version:
    scripts/release/publish.sh %{{version}}%
    git switch dev
    printf "ready" > .release-state
