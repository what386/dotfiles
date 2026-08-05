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
      - uses: actions/checkout@v7

      - name: Set up .NET
        uses: actions/setup-dotnet@v5
        with:
          dotnet-version: "10.0.x"

      - name: Restore
        run: >
          dotnet restore
          "src/{{project_name}}/{{project_name}}.csproj"
          --runtime $%{{ matrix.rid }}%

      - name: Publish
        run: >
          dotnet publish
          "src/{{project_name}}/{{project_name}}.csproj"
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
            "publish/{{project_name}}$%{{ matrix.binary_ext }}%" \
            "dist/{{project_name}}-$%{{ matrix.rid }}%-$%{{ matrix.deployment }}%$%{{ matrix.binary_ext }}%"

      - name: Upload artifact
        uses: actions/upload-artifact@v7
        with:
          name: "{{project_name}}-$%{{ matrix.rid }}%-$%{{ matrix.deployment }}%"
          path: "dist/{{project_name}}-$%{{ matrix.rid }}%-$%{{ matrix.deployment }}%$%{{ matrix.binary_ext }}%"
          if-no-files-found: error

  release:
    name: Create GitHub Release
    needs: build
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v7

      - name: Download all artifacts
        uses: actions/download-artifact@v8
        with:
          path: dist
          merge-multiple: true

      - name: Generate checksums
        run: |
          cd dist
          set -- \
            {{project_name}}-linux-x64-runtime \
            {{project_name}}-linux-x64-bundled \
            {{project_name}}-linux-arm64-runtime \
            {{project_name}}-linux-arm64-bundled \
            {{project_name}}-osx-x64-runtime \
            {{project_name}}-osx-x64-bundled \
            {{project_name}}-osx-arm64-runtime \
            {{project_name}}-osx-arm64-bundled \
            {{project_name}}-win-x64-runtime.exe \
            {{project_name}}-win-x64-bundled.exe \
            {{project_name}}-win-arm64-runtime.exe \
            {{project_name}}-win-arm64-bundled.exe
          for asset in "$@"; do
            test -f "$asset" || { echo "Missing release asset: $asset" >&2; exit 1; }
          done
          sha256sum "$@" > SHA256SUMS.txt

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
          fail_on_unmatched_files: true
