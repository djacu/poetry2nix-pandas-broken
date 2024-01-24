{
  description = "Test poetry2nix env to investigate why pandas 2.2.0 won't build.";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.poetry2nix.url = "github:nix-community/poetry2nix";
  inputs.poetry2nix.inputs.flake-utils.follows = "flake-utils";
  inputs.poetry2nix.inputs.nixpkgs.follows = "nixpkgs";

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    poetry2nix,
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = nixpkgs.legacyPackages.${system};

        inherit
          (poetry2nix.lib.mkPoetry2Nix {inherit pkgs;})
          mkPoetryEnv
          defaultPoetryOverrides
          ;

        python = pkgs.python39;
        pandas-env = mkPoetryEnv {
          projectDir = ./.;
          inherit python;
          #preferWheels = true;
          overrides =
            defaultPoetryOverrides.extend
            (final: prev: {
              pandas =
                prev.pandas.overridePythonAttrs
                (
                  old: {
                    buildInputs =
                      (old.buildInputs or [])
                      ++ [
                        prev.cython_3
                      ];
                  }
                );
            });
        };
      in {
        devShells = {
          poetry = pkgs.mkShell {
            packages = [
              pkgs.poetry
              python
            ];
          };
          pandas = pkgs.mkShell {
            buildInputs = [
              pandas-env
              pkgs.poetry
            ];
          };
        };
      }
    );
}
