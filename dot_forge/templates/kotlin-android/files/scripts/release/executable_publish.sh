#!/usr/bin/env bash
set -euo pipefail

readonly RED="\033[0;31m"
readonly GREEN="\033[0;32m"
readonly BLUE="\033[0;34m"
readonly NC="\033[0m"

if [[ $# == 0 ]] || (( $# > 1 )); then
    echo -e "${RED}Usage: publish <version>${NC}"
    exit 1
fi

version="${1}"

if [[ ! -r .release-state ]] || [[ "$(<.release-state)" != "promoted" ]]; then
    echo -e "${RED}Invalid release state: should be 'promoted'${NC}"
    exit 1
fi

if [[ "$(git branch --show-current)" != "main" ]]; then
    echo -e "${RED}Not on main branch${NC}"
    exit 1
fi

if [[ -n "$(git status --porcelain)" ]]; then
    echo -e "${RED}Working tree must be clean before publishing a release.${NC}"
    exit 1
fi

project_version="$(awk -F '"' '/^[[:space:]]*versionName = "/ { print $2; exit }' app/build.gradle.kts)"
if [[ -z "$project_version" ]] || [[ "${version#v}" != "$project_version" ]]; then
    echo -e "${RED}Version ${version} does not match app version ${project_version:-<missing>}.${NC}"
    exit 1
fi

if [[ "$(git tag --list "${version}")" != "" ]]; then
    echo -e "${RED}Tag ${version} already exists.${NC}"
    exit 1
fi

git tag "${version}"

echo -e "${BLUE}Publishing release on GitHub...${NC}"
git push github "${version}"
echo -e "${GREEN}Published on GitHub${NC}"

printf "published" > .release-state

echo -e "${GREEN}${version} published successfully.${NC}"
