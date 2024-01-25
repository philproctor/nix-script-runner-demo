#!/usr/bin/env bash
# HELPTEXT: Update the flake.lock with the latest version of all dependencies

nix flake lock --update-input nixpkgs
