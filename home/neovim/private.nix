{ pkgs, config }:

let
  plugin = pkgs.vimUtils.buildVimPlugin;
in
{
  vim-taskjuggler = plugin {
    pname = "vim-taskjuggler";
    version = "2024-01-01";
    src = pkgs.fetchFromGitHub {
      owner = "kalafut";
      repo = "vim-taskjuggler";
      rev = "e94c9a0b06022d11a34310ad5f82c1c2bcd86fb7";
      sha256 = "0f8smjl6wi52p8n1hhl5zhk8i3lpsfndxxdammyybw2vz17s0j8q";
    };
  };
}
