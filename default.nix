{ pkgs ? import <unstable> { } }:

pkgs.callPackage ./derivation.nix { }
