```yaml
name: Release

on:
  push:
    tags:
      - "v*"

permissions:
  contents: write

jobs:
  build:
    name: Build ($%{{ matrix.rid }}%, $%{{ matrix.deployment }}%)
    runs-on: $%{{ matrix.os }}%

    strategy:
      fail-fast: false
      matrix:
        include:
          # Linux x64
          - os: ubuntu-latest
            rid: linux-x64
            binary_ext: ""
            deployment: runtime
            self_contained: false

          - os: ubuntu-latest
            rid: linux-x64
            binary_ext: ""
            deployment: bundled
            self_contained: true

          # Linux ARM64
          - os: ubuntu-latest
            rid: linux-arm64
            binary_ext: ""
            deployment: runtime
            self_contained: false

          - os: ubuntu-latest
            rid: linux-arm64
            binary_ext: ""
            deployment: bundled
            self_contained: true

          # macOS x64
          - os: macos-latest
            rid: osx-x64
            binary_ext: ""
            deployment: runtime
            self_contained: false

          - os: macos-latest
            rid: osx-x64
            binary_ext: ""
            deployment: bundled
            self_contained: true

          # macOS ARM64
          - os: macos-latest
            rid: osx-arm64
            binary_ext: ""
            deployment: runtime
            self_contained: false

          - os: macos-latest
            rid: osx-arm64
            binary_ext: ""
            deployment: bundled
            self_contained: true

          # Windows x64
          - os: windows-latest
            rid: win-x64
            binary_ext: ".exe"
            deployment: runtime
            self_contained: false

          - os: windows-latest
            rid: win-x64
            binary_ext: ".exe"
            deployment: bundled
            self_contained: true

          # Windows ARM64
          - os: windows-latest
            rid: win-arm64
            binary_ext: ".exe"
            deployment: runtime
            self_contained: false

          - os: windows-latest
            rid: win-arm64
            binary_ext: ".exe"
            deployment: bundled
            self_contained: true

    steps:
      - uses: actions/checkout@v6

      - name: Set up .NET
        uses: actions/setup-dotnet@v5
        with:
          dotnet-version: "9.0.x"

      - name: Restore
        run: >
          dotnet restore
          "{{forge.project.name}}/{{forge.project.name}}.csproj"
          --runtime $%{{ matrix.rid }}%

      - name: Publish
        run: >
          dotnet publish
          "{{forge.project.name}}/{{forge.project.name}}.csproj"
          --configuration Release
          --runtime $%{{ matrix.rid }}%
          --self-contained $%{{ matrix.self_contained }}%
          --no-restore
          --output publish
          -p:PublishSingleFile=true
          -p:DebugType=None
          -p:DebugSymbols=false

      - name: Archive binary
        shell: bash
        run: |
          mkdir -p dist

          cp \
            "publish/{{forge.project.name}}$%{{ matrix.binary_ext }}%" \
            "dist/{{forge.project.name}}-$%{{ matrix.rid }}%-$%{{ matrix.deployment }}%$%{{ matrix.binary_ext }}%"

      - name: Upload artifact
        uses: actions/upload-artifact@v7
        with:
          name: "{{forge.project.name}}-$%{{ matrix.rid }}%-$%{{ matrix.deployment }}%"
          path: "dist/{{forge.project.name}}-$%{{ matrix.rid }}%-$%{{ matrix.deployment }}%$%{{ matrix.binary_ext }}%"
          if-no-files-found: error

  release:
    name: Create GitHub Release
    needs: build
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v6

      - name: Download all artifacts
        uses: actions/download-artifact@v8
        with:
          path: dist

      - name: Flatten artifacts
        shell: bash
        run: |
          find dist -mindepth 2 -type f -exec mv {} dist/ \;
          find dist -mindepth 1 -type d -empty -delete

      - name: Generate checksums
        working-directory: dist
        run: |
          find . \
            -maxdepth 1 \
            -type f \
            ! -name SHA256SUMS.txt \
            -printf '%P\0' \
            | sort -z \
            | xargs -0 sha256sum \
            > SHA256SUMS.txt

      - name: Read changelog section for tag
        id: release_notes
        run: |
          RELEASE_NOTES="$(./scripts/changelog_for_tag.bash "$%{{ github.ref_name }}%")"

          {
            echo "body<<__RELEASE_NOTES__"
            printf '%s\n' "$RELEASE_NOTES"
            echo "__RELEASE_NOTES__"
          } >> "$GITHUB_OUTPUT"

      - name: Create release
        uses: softprops/action-gh-release@v3
        with:
          tag_name: $%{{ github.ref_name }}%
          body: $%{{ steps.release_notes.outputs.body }}%
          files: dist/*
```

