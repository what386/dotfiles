alias cd = z

def --env gcl [url: string] {
    cd ~/Git

    git clone $url

    let repo = (
        $url
        | path basename
        | str replace --regex '\.git$' ''
    )

    cd $repo
}
