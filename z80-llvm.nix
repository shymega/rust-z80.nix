with import <nixpkgs> {};
let
  gccForLibs = stdenv.cc.cc;
in llvmPackages.llvm.overrideAttrs (final: prev: {
  name = "llvm-z80";
  src = builtins.fetchGit {
    url = "https://github.com/jacobly0/llvm-project";
    ref= "z80";
  };
  buildInputs = [
    bashInteractive
    python3
    ninja
    cmake
  ];

  # where to find libgcc
  NIX_LDFLAGS="-L${gccForLibs}/lib/gcc/${targetPlatform.config}/${gccForLibs.version}";
  # teach clang about C startup file locations
  CFLAGS="-B${gccForLibs}/lib/gcc/${targetPlatform.config}/${gccForLibs.version} -B ${stdenv.cc.libc}/lib";

  cmakeFlags = [
    "-DCMAKE_BUILD_TYPE=Debug"
    "-DCMAKE_C_COMPILER=clang"
    "-DCMAKE_CXX_COMPILER=clang++"
    "-DLLVM_ENABLE_PROJECTS=clang"
    "-DLLVM_EXPERIMENTAL_TARGETS_TO_BUILD=Z80"
    "-DBUILD_SHARED_LIBS=ON"
  ];
  })
