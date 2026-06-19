default:
    just --list

fmt:
    cargo clippy --fix --bin "{{ forge.project.name }}"
    cargo fmt --all

lint:
    cargo fmt -- --check
    cargo clippy --all-targets -- -D warnings
    cargo xwin clippy --all-targets -- -D warnings

test:
    cargo nextest run --all
    cargo xwin test run --all --target x86_64-pc-windows-msvc


run *args:
    cargo run --bin "{{ forge.project.name }}" -- %{{args}}%

prepare version:
    scripts/release/prepare.sh %{{version}}%

promote:
    just lint
    just test
    scripts/release/promote.sh

publish version:
    scripts/release/publish.sh %{{version}}%
    git switch dev
