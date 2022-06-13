if status is-interactive
    # Commands to run in interactive sessions can go here
end

# Alias is just using eval to make a function anyway. It also
# seems to call out to sed, so that might be why it's slow.
# I tend to think alias should be removed from fish anyway.

# For optimal startup time you should use functions and make them lazy-loaded
# which you can do interactively with funced and funcsave,
# or manually by saving each function in its own file
# ~/.config/fish/functions/name-of-function.fish

## eliminate fish_prompt:
# set -U fish_greeting ""
# fish_prompt
