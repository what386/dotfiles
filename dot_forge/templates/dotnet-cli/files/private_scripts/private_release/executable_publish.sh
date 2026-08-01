#!/usr/bin/env bash
set -euo pipefail

readonly RED="\033[0;31m"
readonly GREEN="\033[0;32m"
readonly BLUE="\033[0;34m"
readonly NC="\033[0m"

if [[ $# -ne 1 ]]; then
    echo -e "${RED}Usage: publish <version>${NC}"
    exit 1
fi

readonly version="$1"

if [[ "$(git branch --show-current)" != "main" ]]; then
    echo -e "${RED}Not on main branch.${NC}"
    exit 1
fi

if [[ -n "$(git tag --list "$version")" ]]; then
    echo -e "${RED}Tag ${version} already exists.${NC}"
    exit 1
fi

echo -e "${BLUE}Creating tag ${version}...${NC}"
git tag "$version"

echo -e "${BLUE}Publishing release tag on GitHub...${NC}"
git push github "$version"

echo -e "${GREEN}${version} published on GitHub successfully.${NC}"
