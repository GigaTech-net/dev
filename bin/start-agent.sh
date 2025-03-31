#!/bin/bash
if [[ -d "$HOME/.ssh" ]]; then
  eval "$(ssh-agent -s)"
  for key in "$HOME"/.ssh/id_*; do
    [[ -f "$key" && "$key" != *.pub ]] && ssh-add "$key" 2>/dev/null
  done
fi
