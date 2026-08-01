default:
    just --list

fmt:
    dotnet format "{{ forge.project.name }}.slnx"

lint:
    dotnet format "{{ forge.project.name }}.slnx" --verify-no-changes
    dotnet build "{{ forge.project.name }}.slnx" --no-restore -p:TreatWarningsAsErrors=true

test:
    dotnet test "{{ forge.project.name }}.slnx"

test-all:
    dotnet test "{{ forge.project.name }}.slnx" --runtime linux-x64
    dotnet test "{{ forge.project.name }}.slnx" --runtime osx-arm64
    dotnet test "{{ forge.project.name }}.slnx" --runtime win-x64

run *args:
    dotnet run --project "{{ forge.project.name }}" -- %{{args}}%

prepare version:
    scripts/release/prepare.sh %{{version}}%

promote:
    just lint
    just test
    scripts/release/promote.sh

publish version:
    scripts/release/publish.sh %{{version}}%
    git switch dev
