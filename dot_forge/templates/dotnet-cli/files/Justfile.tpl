default:
    just --list

fmt:
    dotnet format "{{ project_name }}.slnx"

lint:
    dotnet format "{{ project_name }}.slnx" --verify-no-changes
    dotnet build "{{ project_name }}.slnx" --no-restore -p:TreatWarningsAsErrors=true

test:
    dotnet test "{{ project_name }}.slnx"

test-all:
    dotnet test "{{ project_name }}.slnx" --runtime linux-x64
    dotnet test "{{ project_name }}.slnx" --runtime osx-arm64
    dotnet test "{{ project_name }}.slnx" --runtime win-x64

verify-release:
    just lint
    just test

run *args:
    dotnet run --project "src/{{ project_name }}" -- %{{args}}%

prepare version:
    scripts/release/prepare.sh %{{version}}%

promote:
    scripts/release/promote.sh

publish version:
    scripts/release/publish.sh %{{version}}%
    git switch dev
    printf "ready" > .release-state
