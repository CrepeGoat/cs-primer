{ pkgs ? import <nixpkgs> { } }:

pkgs.mkShell {
  buildInputs = [
    (import ./google_benchmark.nix { inherit pkgs; })
  ];
}
