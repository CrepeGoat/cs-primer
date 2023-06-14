{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  buildInputs = [
    # pkgs.zig
    pkgs.python311Packages.python
    pkgs.python311Packages.setuptools
  ];
}
