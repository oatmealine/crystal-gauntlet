
{
  description = "Geometry Dash server reimplementation in Crystal";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.05";
    crystal-flake.url = "github:manveru/crystal-flake";
  };

  outputs = { self, nixpkgs, flake-utils, crystal-flake }:
    (with flake-utils.lib; eachSystem defaultSystems) (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        inherit (crystal-flake.packages.${system}) crystal shards;
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

            buildInputs = with pkgs; [ openssl sqlite pkg-config ] ++ [ crystal ];

            nativeBuildInputs = with pkgs; [ openssl pkg-config yt-dlp ffmpeg ] ++ [ crystal ];

            crystal = crystal;
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