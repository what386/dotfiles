package]
name = "{{ forge.project.name }}"
version = "0.1.0"
edition = "2024"
license = "MIT OR Apache-2.0"
readme = "README.md"
repository = "https://github.com/what386/{{ forge.project.name }}"
description = ""
keywords = []
categories = []

exclude = [
    ".github",
    "scripts/",
    "completions/"
]

[features]
default = []
shell-completions = ["dep:clap_complete"]

[[bin]]
name = "completions"
path = "src/completions.rs"
required-features = ["shell-completions"]

[[bin]]
name = "{{ forge.project.name }}"
path = "src/main.rs"

[dependencies]
clap = { version = "4.6", features = ["derive"] }
clap_complete = { version = "4.6", optional = true }

