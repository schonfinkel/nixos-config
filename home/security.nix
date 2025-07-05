{pkgs, ...}:

{
  home.packages = with pkgs; [
    age
    openssl
    tomb
    zbar # for pass-otp
  ];

  programs.password-store = {
    enable = true;
    package = pkgs.pass.withExtensions (
      exts: [
        exts.pass-tomb
        exts.pass-otp
      ]
    );
    settings = {
      PASSWORD_STORE_DIR = "\$HOME/.password-store";
      PASSWORD_STORE_CLIP_TIME = "60";
    };
  };
}
