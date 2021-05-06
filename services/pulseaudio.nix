{pkgs, config, ...}:

{
  sound.enable = true;

  hardware.pulseaudio = {
    enable = true;
    support32Bit = true;
    package = pkgs.pulseaudioFull;
  };

  environment.systemPackages = with pkgs; [
	flac
    pavucontrol
  ];
}
