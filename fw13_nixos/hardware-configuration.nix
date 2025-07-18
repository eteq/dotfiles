# Do not modify this file!  It was generated by ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes
# to /etc/nixos/configuration.nix instead.
{ config, lib, pkgs, modulesPath, ... }:

{
  imports =
    [ (modulesPath + "/installer/scan/not-detected.nix")
    ];

  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "thunderbolt" "usbhid" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" =
    { device = "/dev/disk/by-uuid/1d530301-d7d6-4e5b-adec-5c352a8a4de3";
      fsType = "btrfs";
      options = [ "subvol=root" ];
    };

  fileSystems."/home" =
    { device = "/dev/disk/by-uuid/1d530301-d7d6-4e5b-adec-5c352a8a4de3";
      fsType = "btrfs";
      options = [ "subvol=home" ];
    };

  fileSystems."/nix" =
    { device = "/dev/disk/by-uuid/1d530301-d7d6-4e5b-adec-5c352a8a4de3";
      fsType = "btrfs";
      options = [ "subvol=nix" "noatime" ];
    };


  fileSystems."/var/log" =
    { device = "/dev/disk/by-uuid/1d530301-d7d6-4e5b-adec-5c352a8a4de3";
      fsType = "btrfs";
      options = [ "subvol=log" ];
    };

  fileSystems."/var/lib/docker" =
    { device = "/dev/disk/by-uuid/1d530301-d7d6-4e5b-adec-5c352a8a4de3";
      fsType = "btrfs";
      options = [ "subvol=dockervol" "compress=zstd" ]; # compression might not behave due to btrfs limitations
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/6C86-121D";
      fsType = "vfat";
      options = [ "fmask=0022" "dmask=0022" ];
    };

  swapDevices = [ { device = "/swap/swapfile"; } ];

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.eth0.useDHCP = lib.mkDefault true;
  # networking.interfaces.wlp1s0.useDHCP = lib.mkDefault true;


  # for some reasons this seems to be necessary to make any ROCm stuff work on a 780m - see https://www.reddit.com/r/ROCm/comments/17e2b5o/rocmpytorch_problem/
  environment.sessionVariables.HSA_OVERRIDE_GFX_VERSION = "11.0.0";

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
