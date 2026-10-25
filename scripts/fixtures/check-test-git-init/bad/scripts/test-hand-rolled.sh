#!/usr/bin/env bash
# a test that makes its throwaway repo by hand
mkdir -p "$scratch/r" && git -C "$scratch/r" init -q --separate-git-dir="$scratch/r.gd"
