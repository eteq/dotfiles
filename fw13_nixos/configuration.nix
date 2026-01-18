# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, lib, ... }:
let 
    earlyIntegratedDrivers = [ "amdgpu" ];
in
{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store = true;
  };


  # any overlays
  # nixpkgs.overlays = [ (self: super: {
  #     blas = super.blas.override {
  #       blasProvider = self.amd-blis;
  #     };

  #     lapack = super.lapack.override {
  #       lapackProvider = self.amd-libflame;
  #     };
  #   }
  # ) ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 10;    
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.timeout = 2;
 
  system.copySystemConfiguration = true;
 
  boot.initrd.kernelModules = lib.mkIf (config.specialisation != {}) earlyIntegratedDrivers;
  #boot.kernelPackages = pkgs.linuxPackages_latest;
  #boot.kernelPackages = pkgs.linuxPackages_6_12; #TODO: change back to latest once https://github.com/NixOS/nixpkgs/pull/375838 is in the stable nixos 
  boot.kernelModules = [ "thunderbolt-net" ]; 
  boot.extraModulePackages = with config.boot.kernelPackages; [ turbostat v4l2loopback ];

  boot.kernel.sysctl = { "kernel.sysrq" = 502; };

  networking.hostName = "falcata"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  # null is default which means it can be set dynamically
  #time.timeZone = "America/New_York";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };
  
  services.hardware.bolt.enable = true;

  security.polkit.enable = true;

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable the GNOME Desktop Environment.
  services.displayManager.gdm = {
    enable = true;
    wayland = true;
  };
  services.desktopManager.gnome = {
    enable = true;     
    extraGSettingsOverridePackages = [ pkgs.mutter ];
    extraGSettingsOverrides = ''
    [org.gnome.mutter]
    experimental-features=['scale-monitor-framebuffer']
  '';
  };

  # Also Enable KDE
  services.desktopManager.plasma6.enable = true;

  services.displayManager.defaultSession = "gnome";

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };
 

  hardware = {
    graphics = {
     # Enable OpenGL
      enable = lib.mkDefault true;
      enable32Bit = lib.mkDefault true;
    };

    # disabled in 25.11
    #amdgpu.amdvlk = {
    #  enable = lib.mkDefault false;
    #  support32Bit.enable = lib.mkDefault false;
    #};
    i2c.enable = true;
  };
 
#  hardware.graphics.extraPackages = [
#    pkgs.amdvlk
#  ];
#  hardware.graphics.extraPackages32 = [
#    pkgs.driversi686Linux.amdvlk
#  ];



  # Load nvidia driver for Xorg and Wayland
  
  services.xserver.videoDrivers = lib.mkDefault  [ "amdgpu" "nvidia" ];

  hardware.nvidia = {

    # Modesetting is required.
    modesetting.enable = true;

    # Nvidia power management. Experimental, and can cause sleep/suspend to fail.
    # Enable this if you have graphical corruption issues or application crashes after waking
    # up from sleep. This fixes it by saving the entire VRAM memory to /tmp/ instead 
    # of just the bare essentials.
    powerManagement.enable = lib.mkDefault true;

    # Fine-grained power management. Turns off GPU when not in use.
    # Experimental and only works on modern Nvidia GPUs (Turing or newer).
    powerManagement.finegrained = lib.mkDefault false;

    # Use the NVidia open source kernel module (not to be confused with the
    # independent third-party "nouveau" open source driver).
    # Support is limited to the Turing and later architectures. Full list of 
    # supported GPUs is at: 
    # https://github.com/NVIDIA/open-gpu-kernel-modules#compatible-gpus 
    # Only available from driver 515.43.04+
    # Currently alpha-quality/buggy, so false is currently the recommended setting.
    open = true;

    # Enable the Nvidia settings menu,
	# accessible via `nvidia-settings`.
    nvidiaSettings = true;

    # Optionally, you may need to select the appropriate driver version for your specific GPU.
    package = config.boot.kernelPackages.nvidiaPackages.stable;
    #package = config.boot.kernelPackages.nvidiaPackages.mkDriver {
    #  version = "580.95.05";
    #  sha256_64bit = "sha256-hJ7w746EK5gGss3p8RwTA9VPGpp2lGfk5dlhsv4Rgqc=";
    #  sha256_aarch64 = "sha256-zLRCbpiik2fGDa+d80wqV3ZV1U1b4lRjzNQJsLLlICk=";
    #  openSha256 = "sha256-RFwDGQOi9jVngVONCOB5m/IYKZIeGEle7h0+0yGnBEI=";
    #  settingsSha256 = "sha256-F2wmUEaRrpR1Vz0TQSwVK4Fv13f3J9NJLtBe4UP2f14=";
    #  persistencedSha256 = "sha256-QCwxXQfG/Pa7jSTBB0xD3lsIofcerAWWAHKvWjWGQtg=";
    #};
    
    prime = {
      sync.enable = lib.mkDefault false;
      offload.enable = true;
      offload.enableOffloadCmd = true;
      nvidiaBusId = "PCI:70:0:0";
      amdgpuBusId = "PCI:193:0:0"; 
      allowExternalGpu = true;
    };
  };
  

  # Enable CUPS to print documents.
  services.printing.enable = true;
  services.printing.drivers = [ pkgs.hplip pkgs.brlaser pkgs.cups-brother-hll2350dw ];
  services.printing.browsed.enable = false;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    jack.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.erik = {
    isNormalUser = true;
    description = "Erik Tollerud";
    extraGroups = [ "networkmanager" "wheel" "docker" "video" "render" "dialout" "gamemode" ];
    packages = with pkgs; [
    #  thunderbird
    ];
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # fix needed starting 2026-10-28
  nixpkgs.config.permittedInsecurePackages = [ "mbedtls-2.28.10" ];
  
  programs.dconf.enable = true; # maybe cleans up some GTK themes?

  programs.firefox.enable = true;
  programs.nix-ld = {
    enable = true;
    #libraries = [ ];
  };

  programs.git = {
    enable = true;
    prompt.enable = true;
    lfs.enable = true;
    package = pkgs.gitFull;
    config = {
    credential.helper = "${
        pkgs.git.override { withLibsecret = true; }
      }/bin/git-credential-libsecret";
    };
  };

  programs.corefreq.enable = true;
  programs.vim.enable = true;
  programs.tmux.enable = true;
  programs.traceroute.enable = true;

  environment.variables = {
    EDITOR = "vim";
    GI_TYPELIB_PATH = "/run/current-system/sw/lib/girepository-1.0";
  };

  environment.systemPackages = let
    unstable = import <nixos-unstable> { config = { allowUnfree = true; }; };
  in with pkgs; [
    # vim # installed via programs.vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    wget
    file
    curl
    lshw
    lm_sensors
    nvme-cli
    minicom
    tio
    libgtop
    cudatoolkit
    ghostscript
    imagemagick
    element-desktop
    openrgb-with-all-plugins
    openssl
    killall
    entr
    pwvucontrol

    (python3.withPackages (subpkgs: with subpkgs; [
        pip
        numpy
        scipy
        sympy
        astropy
        requests
        ipython
        ipykernel
        matplotlib
        pandas
        jupyterlab
      ])
    )
    
    xonsh

    mkl

    pciutils
    usbutils
    fd
    unzip
    zip
    wl-clipboard

    gimp
    audacity
    orca-slicer
    kicad
    texliveFull
    mpv
    graphviz

    google-chrome

    zoom-us
    webex
    ffmpeg-full
    droidcam
    
    gnumake
    cmake
    gcc
    fftw
    linuxHeaders
    rustup
    pixi
    poetry
    nodejs_24
    nvd
    unstable.vscode.fhs
    devcontainer
    kitty
    openocd
    probe-rs-tools

    rocmPackages.rocminfo
    rocmPackages.rocm-smi

    slack

    superTuxKart
    gamemode

    libreoffice-fresh
    #onlyoffice-bin
    onlyoffice-desktopeditors

    # qt/KDE applications
    kdePackages.discover # Optional: Install if you use Flatpak or fwupd firmware update sevice
    kdePackages.kcalc # Calculator
    kdePackages.kcharselect # Tool to select and copy special characters from all installed fonts
    kdePackages.kcolorchooser # A small utility to select a color
    kdePackages.kolourpaint # Easy-to-use paint program
    kdePackages.ksystemlog # KDE SystemLog Application
    #kdePackages.sddm-kcm # Configuration module for SDDM
    kdiff3 # Compares and merges 2 or 3 files or directories
    kdePackages.isoimagewriter # Optional: Program to write hybrid ISO files onto USB disks
    kdePackages.partitionmanager # Optional Manage the disk devices, partitions and file systems on your computer
    hardinfo2 # System information and benchmarks for Linux systems
    haruna # Open source video player built with Qt/QML and libmpv
  ];

  environment.plasma6.excludePackages = with pkgs.kdePackages; [
    kdepim-runtime
    konsole
  ];

  #environment.sessionVariables.NIXOS_OZONE_WL = "1"; # electron apps aren't resizable in waland right now

  programs = {
    gamescope = let unstable = import <nixos-unstable> { config = { allowUnfree = true; }; }; in {
      enable = true;
      capSysNice = false; # see https://github.com/NixOS/nixpkgs/issues/351516
      package = unstable.gamescope; # contains a  fix to https://github.com/ValveSoftware/gamescope/issues/1445
    };
    
    steam = {
      enable = true;
      remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
      #dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
      localNetworkGameTransfers.openFirewall = true; # Open ports in the firewall for Steam Local Network Game Transfers
      gamescopeSession.enable = true;
      package = pkgs.steam.override {
        extraLibraries = pkgs: [ pkgs.xorg.libxcb ];
        extraPkgs = pkgs: with pkgs; [
            xorg.libXcursor
            xorg.libXi
            xorg.libXinerama
            xorg.libXScrnSaver
            libpng
            libpulseaudio
            libvorbis
            stdenv.cc.cc.lib
            libkrb5
            keyutils
            gamemode
            mangohud
          ];
      };
      extraCompatPackages = [ pkgs.proton-ge-bin ];
    };

    gamemode.enable = true;
  };
  
  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  services.avahi = {
    enable = true;
    nssmdns4 = true;
    nssmdns6 = true;
    openFirewall = true;
  };

  # List services that you want to enable:

  services.flatpak.enable = true;
  services.fwupd.enable = true;
  services.ddccontrol.enable = true;

  virtualisation.docker = {
      enable = true;
      enableOnBoot = false; # socket activation
  };

  hardware.nvidia-container-toolkit.enable = true;

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;
  services.openssh.ports = [ 12322 ];
  services.openssh.settings.GatewayPorts = "yes";

  # have to pick one when both gnome and KDE are present
  #programs.ssh.askPassword = pkgs.lib.mkForce "${pkgs.kdePackages.ksshaskpass.out}/bin/ksshaskpass";
  programs.ssh.askPassword = pkgs.lib.mkForce "${pkgs.seahorse.out}/libexec/seahorse/ssh-askpass";


  # Open ports in the firewall.
  networking.firewall.allowedTCPPorts = [ 12322 ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;



  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.11"; # Did you read the comment?

  specialisation = {
    console.configuration = {
      system.nixos.tags = [ "console" ];
      boot.kernelParams = [ "systemd.unit=multi-user.target" ];
    };

    smart-rebooter.configuration = {
      system.nixos.tags = [ "smart-rebooter" ];
      boot.kernelParams = [ "systemd.unit=rescue.target" ];
      systemd.services.smart-rebooter-script = {
        script = ''
          # The search is case-insensitive.
          DEVICE_ID="07554c17-80dd-a02c-ffff-ffffffffffff"

          if /run/current-system/sw/bin/boltctl info $DEVICE_ID | grep "status:" | grep -iq authorized; then
              # This block runs if the device is found
              echo "Found an authorized '$DEVICE_ID' thunderbolt device. Assuming EGPU present"
              BOOT_ENTRY=`ls /boot/loader/entries/*egpu-only.conf | sort -t '-' -k 3n | tail -n 1 | xargs -- basename`
              else
              echo "No authorized '$DEVICE_ID' thunderbolt device was found. Normal Boot."
              BOOT_ENTRY=`ls /boot/loader/entries/*.conf | grep -v specialisation | sort -t '-' -k 3n | tail -n 1 | xargs -- basename`
          fi

          echo "Rebooting to boot entry '$BOOT_ENTRY'"
          systemctl reboot --boot-loader-entry=$BOOT_ENTRY
        '';
        # script = ''
        #   # The search is case-insensitive.
        #   DEVICE_NAME="GeForce"

        #   if /run/current-system/sw/bin/lspci | grep -iq "$DEVICE_NAME"; then
        #       # This block runs if the device IS found
        #       echo "Found a '$DEVICE_NAME' PCI device. Assuming EGPU present"
        #       BOOT_ENTRY=`ls /boot/loader/entries/*egpu-only.conf | sort -t '-' -k 3n | tail -n 1 | xargs -- basename`
        #   else
        #       echo "No '$DEVICE_NAME' PCI device was found. Normal Boot."
        #       BOOT_ENTRY=`ls /boot/loader/entries/*.conf | grep -v specialisation | sort -t '-' -k 3n | ls /boot/loader/entries/*.conf | grep -v specialisation | sort -t '-' -k 3n | tail -n 1 | xargs -- basename`
              
        #   fi

        #   echo "Rebooting to boot entry '$BOOT_ENTRY'"
        #   #systemctl reboot --boot-loader-entry=$BOOT_ENTRY
        # '';

        serviceConfig = {
          # This service runs once and finishes,
          # instead of the default long-live services
          type = "oneshot";
        };

        # "Enable" the service
        wantedBy = [ "rescue.target" ];
        after = [ "bolt.service" ];
      };
    };
    
    egpu-only.configuration = {
      system.nixos.tags = [ "egpu-only" ];
   
      boot.kernelModules = [ "pci_stub" ];

      boot.kernelParams = [ "pci-stub.ids=1002:15bf" "module_blacklist=simpledrm,amdgpu" "initcall_blacklist=simpledrm_platform_driver_init" ];
      
      services.xserver.videoDrivers = [ "nvidia" ];
      #services.xserver.videoDrivers = lib.mkForce [ "nvidia" ];
      hardware = {
        nvidia = {
          prime = {
		        offload.enable = lib.mkForce false;
            offload.enableOffloadCmd = lib.mkForce false;
            sync.enable = false;
            reverseSync.enable = false;
          };
        };
      };
      services.displayManager.gdm.autoSuspend = false; # we're on wall power if using the egpu and nvidia can be unhappy with gdm suspend
  
      systemd.services.nvidia-container-toolkit-cdi-generator = {
        wantedBy = lib.mkForce [ "docker.service" ];
        after = lib.mkForce [ "docker.service" ];
        requiredBy = lib.mkForce [ ];
        #requires = [ "docker.service" ];
      };
    };
    
  };
  
  # additional udev rules - first is for viture mouse service, second is for MCP2221 as non-root, third for rpi debug probe.  plugdev probably unneceesary but :shrug:
  services.udev.extraRules = ''
  SUBSYSTEM=="tty", ACTION=="add", ATTRS{idVendor}=="35ca", ATTRS{idProduct}=="101d", TAG+="systemd", ENV{SYSTEMD_WANTS}+="vituremouse.service"
  SUBSYSTEM=="usb", ATTRS{idVendor}=="04d8", MODE:="0666"
  SUBSYSTEM=="usb", ATTRS{idVendor}=="2e8a", ATTRS{idProduct}=="000c", MODE:="0666", TAG+="uaccess"
  '';
  # a service to start a mouse-from-head-move script when viture glasses are connected
  systemd.services.vituremouse = {
    description = "Start the viture glasses mouse emulator.";
    path = [pkgs.bash pkgs.nix pkgs.sudo];
    environment = { NIX_PATH = "/home/erik/.nix-defexpr/channels:nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixos:nixos-config=/etc/nixos/configuration.nix:/nix/var/nix/profiles/per-user/root/channels"; };
    unitConfig.StopWhenUnneeded = "yes";
    serviceConfig = {
      Type = "exec";
      ExecStart = "/home/erik/bin/viture_xr_mouse";
    };
  };
  
}
