#!/bin/bash

# Configure Terminal to start tmux by default
# To configure your terminal to automatically start tmux as default, add the following lines to your ~/.bash_profile shell startup file, just above your aliases section.
if command -v tmux &> /dev/null && [ -z "$TMUX" ]; then
    tmux attach -t default || tmux new -s default
fi