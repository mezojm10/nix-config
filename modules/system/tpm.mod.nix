{...}: {
  # TPM 2.0 access (devices owned by the `tss` group, FAPI config, PKCS#11
  # provider in /run/current-system/sw/lib). The user joins `tss` in
  # `modules/user.mod.nix`; the SSH key itself lives in the TPM.
  flake.nixosModules.tpm = {...}: {
    security.tpm2 = {
      enable = true;
      pkcs11.enable = true;
      tctiEnvironment.enable = true;
    };
  };
}
