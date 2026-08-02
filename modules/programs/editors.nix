{...}: {
  flake.modules.homeManager.editors = {config, ...}: {
    programs.helix = {
      enable = true;
      defaultEditor = true;
    };

    programs.neovim = {
      enable = true;
      defaultEditor = false;

      withNodeJs = true;
      withPython3 = true;
      withRuby = true;

      # ~/.config/nvim is a git-managed kickstart.nvim checkout, so home-manager
      # must not own init.lua. This passes the provider host_prog settings via
      # wrapper args (--cmd 'lua dofile(...)') instead of writing a config file.
      sideloadInitLua = true;
    };
  };
}
