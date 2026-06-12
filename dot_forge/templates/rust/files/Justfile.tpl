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
    lash run scripts/release/prepare.lash %{{version}}%

promote:
    just lint
    just test
    lash run scripts/release/promote.lash

publish version:
    lash run scripts/release/publish.lash %{{version}}%
    git switch dev
