{ pkgs ? import <nixpkgs> { } }:

pkgs.mkShell {
  buildInputs = [
    pkgs.binutils
    (import ../../../../nix-custom-pkgs/google_benchmark.nix { inherit pkgs; })
  ];
}
