{ pkgs ? import <nixpkgs> { } }:

pkgs.mkShell {
  buildInputs = [
    pkgs.binutils
    (import ../../../../nix-custom-pkgs/google_benchmark.nix { inherit pkgs; })
  ];
  shellHook = ''
    export PATH=$PATH:/Users/beckerawqatty/.local/opt/zig/
  '';
}
