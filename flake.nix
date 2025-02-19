{
  description = "DevOS environment configuriguration library.";

  nixConfig.extra-experimental-features = "nix-command flakes";
  nixConfig.extra-substituters = "https://nrdxp.cachix.org https://nix-community.cachix.org";
  nixConfig.extra-trusted-public-keys = "nrdxp.cachix.org-1:Fc5PSqY2Jm1TrWfm88l6cvGWwz3s93c6IOifQWnhNW4= nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=";

  inputs =
    {
      nixpkgs.url = "github:nixos/nixpkgs/release-21.11";
      latest.url = "github:nixos/nixpkgs/nixos-unstable";
      nixlib.url = "github:nix-community/nixpkgs.lib";
      blank.url = "github:divnix/blank";

      deploy.url = "github:serokell/deploy-rs";
      deploy.inputs.nixpkgs.follows = "latest";

      home-manager.url = "github:nix-community/home-manager/release-21.11";
      home-manager.inputs.nixpkgs.follows = "nixlib";

      devshell.url = "github:numtide/devshell";
      flake-utils-plus.url = "github:gytis-ivaskevicius/flake-utils-plus";

      nixos-generators.url = "github:nix-community/nixos-generators";
      nixos-generators.inputs.nixpkgs.follows = "blank";

      flake-compat = {
        url = "github:edolstra/flake-compat";
        flake = false;
      };
    };

  outputs =
    { self
    , nixlib
    , nixpkgs
    , latest
    , deploy
    , devshell
    , flake-utils-plus
    , nixos-generators
    , home-manager
    , ...
    }@inputs:
    let

      tests = import ./src/tests.nix { inherit (nixlib) lib; };

      internal-modules = import ./src/modules.nix {
        inherit (nixlib) lib;
        inherit nixos-generators;
      };

      importers = import ./src/importers.nix {
        inherit (nixlib) lib;
      };

      generators = import ./src/generators.nix {
        inherit (nixlib) lib;
        inherit deploy;
      };

      mkFlake =
        let
          mkFlake' = import ./src/mkFlake {
            inherit (nixlib) lib;
            inherit (flake-utils-plus.inputs) flake-utils;
            inherit deploy devshell home-manager flake-utils-plus internal-modules tests;
          };
        in
        {
          __functor = _: args: (mkFlake' args).flake;
          options = args: (mkFlake' args).options;
        };

      # Unofficial Flakes Roadmap - Polyfills
      # This project is committed to the Unofficial Flakes Roadmap!
      # .. see: https://demo.hedgedoc.org/s/_W6Ve03GK#

      # Super Stupid Flakes (ssf) / System As an Input - Style:
      supportedSystems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" ];

      # Pass this flake(self) as "digga"
      polyfillInputs = self.inputs // { digga = self; };
      polyfillOutput = loc: nixlib.lib.genAttrs supportedSystems (system:
        import loc { inherit system; inputs = polyfillInputs; }
      );
      # .. we hope you like this style.
      # .. it's adopted by a growing number of projects.
      # Please consider adopting it if you want to help to improve flakes.



      # DEPRECATED - will be removed timely
      deprecated = import ./deprecated.nix {
        inherit (nixlib) lib;
        inherit (self) nixosModules;
        inherit flake-utils-plus internal-modules importers;
      };

    in

    {
      # what you came for ...
      lib = {
        inherit (flake-utils-plus.inputs.flake-utils.lib) defaultSystems eachSystem eachDefaultSystem filterPackages;
        inherit (flake-utils-plus.lib) exportModules exportOverlays exportPackages;
        inherit mkFlake;
        inherit (tests) mkTest allProfilesTest;
        inherit (importers) flattenTree rakeLeaves importOverlays importExportableModules importHosts;
        inherit (generators) mkDeployNodes mkHomeConfigurations;

        # DEPRECATED - will be removed soon
        inherit (deprecated)
          mkSuites
          profileMap
          mkProfileAttrs
          exporters
          modules
          importModules
          importers
          ;

      };

      # a little extra service ...
      overlays = import ./overlays { inherit inputs; };
      nixosModules = import ./modules;

      defaultTemplate = self.templates.devos;
      templates.devos.path = ./examples/devos;
      templates.devos.description = ''
        an awesome template for NixOS users, with consideration for common tools like home-manager, devshell, and more.
      '';

      # digga-local use
      # system-space and pass sytem and input to each file
      jobs = polyfillOutput ./jobs;
      checks = polyfillOutput ./checks;
      devShell = polyfillOutput ./shell.nix;
    };

}
