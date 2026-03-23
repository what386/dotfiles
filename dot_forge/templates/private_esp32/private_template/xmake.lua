add_rules("mode.debug", "mode.release")
set_languages("c++23")
set_policy("build.c++.modules", true)
add_cxxflags("-stdlib=libc++")
add_ldflags("-stdlib=libc++")

local project_name = "{{name}}"

target(project_name .. "-tests")
do
	set_kind("binary")
	add_files("tests/**.cpp")
end

target(project_name)
do
	set_kind("binary")
	add_files("src/**.cpp")
end

add_rules("plugin.compile_commands.autoupdate", { outputdir = "." })

if is_mode("debug") then
	add_defines("DEBUG")
	set_symbols("debug")
	set_optimize("none")
end

if is_mode("release") then
	set_optimize("aggressive")
	set_strip("all")
end
