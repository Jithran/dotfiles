# Function for directory lister whilst cd-ing
function cd {
    builtin cd "$@" && ls -hal -F
}


