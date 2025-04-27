{pkgs, config, ...}:

{
  environment.systemPackages = with pkgs; [
	flac
    pavucontrol
  ];

  # Enable sound.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };
}
