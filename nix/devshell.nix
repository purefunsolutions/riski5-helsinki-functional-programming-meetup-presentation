# SPDX-FileCopyrightText: 2026 Mika Tammi
# SPDX-License-Identifier: MIT
_: {
  perSystem = {pkgs, ...}: let
    ghcWithHakyll = pkgs.haskellPackages.ghcWithPackages (ps:
      with ps; [
        hakyll
      ]);
  in {
    devShells.default = pkgs.mkShell {
      name = "riski5-presentation";
      packages = [
        ghcWithHakyll
        pkgs.cabal-install
        pkgs.haskell-language-server
        pkgs.haskellPackages.fourmolu
        pkgs.pandoc
        pkgs.graphviz
        pkgs.reuse
        pkgs.nodePackages.prettier
        pkgs.python3
      ];
      shellHook = ''
        echo "riski5 presentation devshell."
        echo ""
        echo "  cabal run site -- build      Build docs/ once"
        echo "  cabal run site -- watch      Live-rebuild on http://localhost:8000"
        echo "  cabal run site -- clean      Drop _cache/ + docs/"
        echo "  nix fmt                       Run treefmt across the tree"
        echo "  nix flake check               REUSE compliance + treefmt check"
        echo ""
      '';
    };
  };
}
