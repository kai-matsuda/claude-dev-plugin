#!/usr/bin/env bash
git_t() { git -c user.name=t "$@"; }
git_t init -q "$scratch/r"
