#!/usr/bin/env bash
set -euo pipefail

readonly RED="\033[0;31m"
readonly GREEN="\033[0;32m"
readonly BLUE="\033[0;34m"
readonly NC="\033[0m"

if [[ $# -ne 1 ]]; then
    echo -e "${RED}Usage: nuget <version>${NC}"
    exit 1
fi

readonly version="$1"
readonly configuration="Release"
readonly output_dir="./artifacts/packages"

if [[ -z "${NUGET_API_KEY:-}" ]]; then
    echo -e "${RED}NUGET_API_KEY is not set.${NC}"
    exit 1
fi

echo -e "${BLUE}Building NuGet package ${version}...${NC}"
rm -rf "$output_dir"

dotnet pack \
    --configuration "$configuration" \
    --output "$output_dir" \
    -p:PackageVersion="$version"

mapfile -t packages < <(
    find "$output_dir" \
        -maxdepth 1 \
        -type f \
        -name '*.nupkg' \
        ! -name '*.symbols.nupkg'
)

if (( ${#packages[@]} == 0 )); then
    echo -e "${RED}No NuGet packages were generated.${NC}"
    exit 1
fi

echo -e "${BLUE}Publishing to NuGet.org...${NC}"

for package in "${packages[@]}"; do
    dotnet nuget push "$package" \
        --source "https://api.nuget.org/v3/index.json" \
        --api-key "$NUGET_API_KEY" \
        --skip-duplicate
done

echo -e "${GREEN}${version} published to NuGet.org successfully.${NC}"
