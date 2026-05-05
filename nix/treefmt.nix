# SPDX-FileCopyrightText: 2026 Mika Tammi
# SPDX-License-Identifier: MIT
{inputs, ...}: {
  imports = with inputs; [
    flake-root.flakeModule
    treefmt-nix.flakeModule
  ];
  perSystem = {
    config,
    pkgs,
    ...
  }: {
    treefmt.config = {
      package = pkgs.treefmt;
      inherit (config.flake-root) projectRootFile;

      # Pandoc-flavoured Markdown has syntax (fenced divs, slide-level
      # markers, raw HTML attributes) that prettier loves to mangle.
      # Keep prettier off SLIDES.md and the built docs/ tree.
      settings.global.excludes = [
        "docs/**"
        "LICENSES/**"
        "SLIDES.md"
        "flake.lock"
        "assets/images/**"
      ];

      programs = {
        alejandra.enable = true;
        deadnix.enable = true;
        statix.enable = true;
        shellcheck.enable = true;
        fourmolu = {
          enable = true;
          package = pkgs.haskellPackages.fourmolu;
        };
        prettier = {
          enable = true;
          includes = [
            "*.css"
            "*.json"
            "*.yaml"
            "*.yml"
          ];
        };
      };
    };

    formatter = config.treefmt.build.wrapper;
  };
}
