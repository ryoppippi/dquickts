{
  description = "QuickJS with durable execution and native TypeScript";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs =
    { self, nixpkgs }:
    let
      systems = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-linux"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          dquickts = pkgs.stdenv.mkDerivation {
            pname = "dquickts";
            version = pkgs.lib.removeSuffix "\n" (builtins.readFile ./VERSION);
            src = pkgs.lib.cleanSource ./.;

            makeFlags = [
              "PREFIX=${placeholder "out"}"
              "CC=${pkgs.stdenv.cc.targetPrefix}cc"
              "HOST_CC=${pkgs.stdenv.cc.targetPrefix}cc"
              "AR=${pkgs.stdenv.cc.bintools.targetPrefix}ar"
              "STRIP=${pkgs.stdenv.cc.bintools.targetPrefix}strip"
            ];
            enableParallelBuilding = true;
            doCheck = true;
            checkTarget = [
              "test"
              "test-snapshot"
            ];

            meta = {
              description = "QuickJS with durable execution and native TypeScript";
              homepage = "https://github.com/stencil-hq/dquickts";
              license = pkgs.lib.licenses.mit;
              platforms = systems;
              mainProgram = "qjs";
            };
          };
        in
        {
          inherit dquickts;
          default = dquickts;
        }
      );

      apps = forAllSystems (system: {
        default = {
          type = "app";
          program = "${self.packages.${system}.dquickts}/bin/qjs";
        };
      });

      checks = forAllSystems (system: {
        dquickts = self.packages.${system}.dquickts;
      });

      devShells = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = pkgs.mkShell {
            inputsFrom = [ self.packages.${system}.dquickts ];
          };
        }
      );

      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt-tree);
    };
}
