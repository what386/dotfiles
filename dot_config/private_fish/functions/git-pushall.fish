function git-pushall
    set -l args $argv
    
    # If no arguments provided, default to current branch
    if test (count $args) -eq 0
        set args (git branch --show-current)
    end
    
    # If only one argument and it's a branch name, push to both remotes
    if test (count $args) -eq 1
        echo "Pushing to github..."
        git push github $args
        and echo "Pushing to gitea..."
        and git push gitea $args
    else
        # Handle cases like: git-pushall origin main, git-pushall -f, etc.
        # Just push to both remotes with all arguments
        echo "Pushing to github..."
        git push github $args
        and echo "Pushing to gitea..."
        and git push gitea $args
    end
end
