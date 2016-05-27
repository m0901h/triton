{ callPackage
, lib
, newScope

, self
, channel
}:

let
  callPackage' = callPackage;
in
let
  buildRustPackage = callPackage ../all-pkgs/build-rust-package { };

  fetchCargo = callPackage ../all-pkgs/fetch-cargo { };

  cargo_bootstrap = callPackage' ../all-pkgs/cargo/bootstrap.nix {
    inherit (self) rustc;
  };

  rustc_bootstrap = callPackage' ../all-pkgs/rustc/bootstrap.nix { };

  callPackage = newScope (self // {
    rustPackages = self;
    inherit buildRustPackage fetchCargo;
  });
in
{
  cargo = callPackage ../all-pkgs/cargo {
    inherit cargo_bootstrap;
    buildRustPackage = buildRustPackage.override {
      cargo = cargo_bootstrap;
    };
    fetchCargo = fetchCargo.override {
      cargo = cargo_bootstrap;
    };
  };

  # These packages are special in that they use the top-level callPackage since they aren't cargo packages
  rustc = callPackage' ../all-pkgs/rustc {
    inherit channel rustc_bootstrap;
  };
}
