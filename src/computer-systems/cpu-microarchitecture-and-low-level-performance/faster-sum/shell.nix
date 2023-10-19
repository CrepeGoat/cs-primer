{ pkgs ? import <nixpkgs> { } }:

pkgs.mkShell {
  buildInputs = [
    pkgs.binutils
    (import ./google_benchmark.nix { inherit pkgs; })
  ];
  shellHook = ''
    export PATH=$PATH:/Users/beckerawqatty/.local/opt/zig/
  '';
}
