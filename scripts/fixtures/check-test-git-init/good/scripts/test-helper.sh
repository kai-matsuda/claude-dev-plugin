#!/usr/bin/env bash
# git init here would climb into the enclosing checkout, so the lib's helper does it
fx_git_repo "$scratch/r" || exit 1
( cd "$scratch/r" && bd init --non-interactive --prefix x )
fx_check "the init commits nothing" fx_eq "$(git -C "$scratch/r" rev-parse HEAD)" x
