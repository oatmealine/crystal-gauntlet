
{
  description = "Geometry Dash server reimplementation in Crystal";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs, flake-utils }:
    (with flake-utils.lib; eachSystem defaultSystems) (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      rec {
        packages = flake-utils.lib.flattenTree rec {
          crystal-gauntlet = pkgs.crystal.buildCrystalPackage {
            pname = "crystal-gauntlet";
            version = "0.1.0";

            src = ./.;

            format = "shards";
            lockFile = ./shard.lock;
            shardsFile = ./shards.nix;

            buildInputs = with pkgs; [ openssl ];

            nativeBuildInputs = with pkgs; [ pkg-config ];
          };
        };

        defaultPackage = packages.crystal-gauntlet;

        devShell = pkgs.mkShell {
          buildInputs = with pkgs; [
            openssl
          ];

          nativeBuildInputs = with pkgs; [
            pkgconfig
            crystal
            shards
          ];
        };
      });
}