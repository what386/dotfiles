use std/config *

# Initialize the PWD hook as an empty list if it doesn't exist
$env.config.hooks.env_change.PWD = (
  $env.config.hooks.env_change.PWD? | default []
)

$env.config.hooks.env_change.PWD ++= [{||
  if (which direnv | is-empty) {
    return
  }

  direnv export json | from json | default {} | load-env

  # If direnv changes PATH, it may become a string, so convert it back to Nu's list form.
  $env.PATH = do (env-conversions).path.from_string $env.PATH
}]
