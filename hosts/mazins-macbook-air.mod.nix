{
  inputs,
  lib,
  ...
}: let
  inherit (import ../lib/systems.nix {inherit inputs;}) darwinSystem;
in {
  imports = [(darwinSystem "Mazins-MacBook-Air" {})];
}
