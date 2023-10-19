{ pkgs }:

pkgs.stdenv.mkDerivation rec {
  pname = "google-benchmark";
  version = "1.8.3";

  srcs = [
    (pkgs.fetchFromGitHub
      {
        owner = "google";
        repo = "benchmark";
        rev = "v${version}";
        hash = "sha256-gztnxui9Fe/FTieMjdvfJjWHjkImtlsHn6fM1FruyME=";
      })
    (pkgs.fetchFromGitHub
      {
        name = "googletest";
        owner = "google";
        repo = "googletest";
        rev = "v1.14.0";
        hash = "sha256-t0RchAHTJbuI5YW4uyBPykTvcjy90JW9AOPNjIhwh6U=";
      })
  ];

  strictDeps = true;
  nativeBuildInputs = [
    pkgs.cmake
  ];

  sourceRoot = ".";
  postUnpack = ''
    BUILD_DIR=$(mktemp -d)
    cp -r ${builtins.elemAt srcs 0}/* $BUILD_DIR
    mkdir $BUILD_DIR/googletest
    cp -r ${builtins.elemAt srcs 1}/* $BUILD_DIR/googletest
  '';
  configurePhase = ''
    cd $BUILD_DIR
    cmake -E make_directory "build"
    cmake -E chdir "build" cmake -DCMAKE_BUILD_TYPE=Release ../
  '';
  buildPhase = ''
    cmake --build "build" --config Release$ -j $NIX_BUILD_CORES
  '';
  checkPhase = ''
    cmake -E chdir "build" ctest --build-config Release
  '';
  installPhase = ''
    cmake --install "build" --prefix $out
  '';

  meta = {
    description = "A C++ microbenchmark support library";
    homepage = "https://github.com/google/benchmark";
    license = pkgs.lib.licenses.asl20;
    platforms = pkgs.lib.platforms.all;
  };
}
