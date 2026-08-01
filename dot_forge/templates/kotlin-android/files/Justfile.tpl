default:
    just --list

lint:
    ./gradlew lint

test:
    ./gradlew test

build-debug:
    ./gradlew :app:assembleDebug

build-release:
    ./gradlew :app:assembleRelease

uninstall:
    adb uninstall {{ package_name }}

install-debug:
    adb install -r app/build/outputs/apk/debug/app-debug.apk

start-app:
    adb shell monkey -p {{ package_name }} -c android.intent.category.LAUNCHER 1

run-debug:
    just build-debug
    just install-debug
    just start-app
