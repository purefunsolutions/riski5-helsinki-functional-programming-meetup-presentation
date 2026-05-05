# SPDX-FileCopyrightText: 2026 Mika Tammi
# SPDX-License-Identifier: MIT
#
# Flake checks beyond treefmt's own. REUSE-compliance linting refuses
# to land any commit that forgets an SPDX header or unknown licence
# identifier — content under CC-BY-4.0, code under MIT.
{self, ...}: {
  perSystem = {pkgs, ...}: {
    checks = {
      reuse =
        pkgs.runCommand "reuse-lint" {
          nativeBuildInputs = [pkgs.reuse];
        } ''
          cp -r ${self}/. ./src
          cd ./src
          reuse lint
          touch "$out"
        '';
    };
  };
}
