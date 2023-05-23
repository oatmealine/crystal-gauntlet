
{
  description = "Geometry Dash server reimplementation in Crystal";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.05";
    crystal-flake.url = "github:manveru/crystal-flake";
  };

  outputs = { self, nixpkgs, flake-utils, crystal-flake }:
    flake-utils.lib.eachDefaultSystem (system:
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
      }) // {
        nixosModules = {
          crystal-gauntlet = { config, lib, pkgs, ... }:
            with lib;
            let
              cfg = config.services.crystal-gauntlet;
            in {
              options.services.crystal-gauntlet = {
                enable = mkEnableOption "Enables the crystal-gauntlet server";

                domain = mkOption {
                  type = types.nullOr types.str;
                  default = null;
                  description = "Which domain to host the server under; if disabled, NGINX is not used";
                };
                port = mkOption {
                  type = types.port;
                  default = 8050;
                };
                package = mkOption {
                  type = types.package;
                  default = self.defaultPackage.${pkgs.system};
                };
              };

              config = mkIf cfg.enable {
                systemd.services."crystal-gauntlet" = {
                  wantedBy = [ "multi-user.target" ];

                  environment = {
                    LISTEN_ON = "http://127.0.0.1:${toString cfg.port}";
                  };

                  serviceConfig = {
                    Restart = "on-failure";
                    ExecStart = "${getExe cfg.package}";
                    DynamicUser = "yes";
                    RuntimeDirectory = "crystal-gauntlet";
                    RuntimeDirectoryMode = "0755";
                    StateDirectory = "crystal-gauntlet";
                    StateDirectoryMode = "0700";
                    CacheDirectory = "crystal-gauntlet";
                    CacheDirectoryMode = "0750";
                  };
                };

                services.nginx = mkIf (cfg.domain != null) {
                  virtualHosts."${cfg.domain}" = {
                    enableACME = true;
                    forceSSL = false;
                    addSSL = true;
                    locations."/" = {
                      proxyPass = "http://127.0.0.1:${toString cfg.port}/";
                    };
                    extraConfig = ''
                      client_max_body_size 500M;
                    '';
                  };
                };
              };
            };
        };
      };
}