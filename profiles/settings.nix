{
  euclid = {
    hostname = "euclid";
    device = "nvme0n1";
    swap = {
      size = "16G";
    };
  };

  peano = {
    hostname = "peano";
    device = "vda";
    swap = {
      size = "4G";
    };
  };

  # Single-disk workstation. A second drive (`sda`) is fitted but left
  # untouched: no profile in use here claims it. Adding `dataDevice = "sda";`
  # plus the luks_multi profile is what would bring it in -- see
  # profiles/disko/luks_multi.nix.
  schonfinkel = {
    hostname = "schonfinkel";
    device = "nvme0n1";
    swap = {
      size = "16G";
    };
  };

  tarski = {
    hostname = "tarski";
    device = "nvme0n1";
    swap = {
      size = "16G";
    };
  };
}
