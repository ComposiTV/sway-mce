# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, ... }:

let

#  home-manager = builtins.fetchTarball "https://github.com/nix-community/home-manager/archive/master.tar.gz";

  ctv-logo = pkgs.fetchurl {
    url = "https://4906.org/m/compositv.png";
    sha256 = "0d331526923872f6482464890111a5d1404e63af089d80e6f7d5f2e8234b8676";
  };

  configure-gtk = pkgs.writeTextFile {
    name = "configure-gtk";
    destination = "/bin/configure-gtk";
    executable = true;
    text = let
      schema = pkgs.gsettings-desktop-schemas;
      datadir = "${schema}/share/gsettings-schemas/${schema.name}/glib-2.0/schemas";
    in ''
      gnome_schema=org.gnome.desktop.interface
      gsettings --schemadir ${datadir} set $gnome_schema gtk-theme 'Dracula'
      gsettings --schemadir ${datadir} set $gnome_schema cursor-theme 'Adwaita'
      gsettings --schemadir ${datadir} set $gnome_schema cursor-size 32
    '';
  };

  dbus-sway-environment = pkgs.writeTextFile {
    name = "dbus-sway-environment";
    destination = "/bin/dbus-sway-environment";
    executable = true;
    text = ''
      dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP=sway
      systemctl --user stop pipewire wireplumber xdg-desktop-portal xdg-desktop-portal-wlr
      systemctl --user start pipewire wireplumber xdg-desktop-portal xdg-desktop-portal-wlr
    '';
  };

  send-key = pkgs.writeTextFile {
    name = "send-key";
    destination = "/bin/send-key";
    executable = true;
    text = ''
      echo key $1 | dotool
    '';
  };

  mouse-move = pkgs.writeTextFile {
    name = "mouse-move";
    destination = "/bin/mouse-move";
    executable = true;
    text = ''
      echo mousemove $1 $2 | dotoolc
    '';
  };

  click-mouse = pkgs.writeTextFile {
    name = "click-mouse";
    destination = "/bin/click-mouse";
    executable = true;
    text = ''
      echo click $1 | dotool
    '';
  };

  toggle-osk = pkgs.writeTextFile {
    name = "toggle-osk";
    destination = "/bin/toggle-osk";
    executable = true;
    text = ''
      kill -n 34 `pidof wvkbd-mobintl` # SIGRTMIN
    '';
  };

in

{
#  imports = [
#    (import "${home-manager}/nixos")
#  ];

  security.polkit = {
    extraConfig = ''
      polkit.addRule(function(action,subject){
        if(action.id == "org.freedesktop.systemd1.manage-units" 
        || action.id == "org.freedesktop.systemd1.manage-unit-files") {
          if(action.lookup("unit") == "poweroff.target"
          || action.lookup("unit") == "reboot.target") {
            return polkit.Result.YES;
          }
        }
      });
    '';
  };

  programs.firefox.enable = true;
  programs.firefox.policies = {
    DisablePocket = true;
    ExtensionSettings = {
      "uBlock0@raymondhill.net" = {
        installation_mode = "normal_installed";
        install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
      };
    };
  };

#  nixpkgs.config.packageOverrides = pkgs: {
#    nur = import (builtins.fetchTarball "https://github.com/nix-community/NUR/archive/master.tar.gz") {
#      inherit pkgs;
#    };
#  };

  boot.plymouth = {
    enable = true;
    logo = ctv-logo;
  };

  programs.dconf.enable = true;

  programs.sway = {
    enable = true;
    wrapperFeatures.gtk = true;
    extraPackages = with pkgs; [ ];
  };

  # Enable sound.
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.enable = true;
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.tv = {
    isNormalUser = true;
    extraGroups = [ "audio" "input" "video" "wheel" ]; # Enable ‘sudo’ for the user.
    packages = with pkgs; [
      alacritty
#      wev
#      firefox
#      nur.repos.rycee.firefox-addons.ublock-origin
      minitube
      vlc
    ];
  };

  environment.sessionVariables = {
    QT_STYLE_OVERRIDE = "Dracula";
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    click-mouse
    configure-gtk
    dbus
    dbus-sway-environment
    dotool
    dracula-theme
    fuzzel
    glib
    gnome3.adwaita-icon-theme
    gsettings-desktop-schemas
    mako
    mouse-move
    pavucontrol
    send-key
    toggle-osk
    libcec
#    v4l-utils
    wayland
    wvkbd
    xdg-utils
  ];

  environment.etc = {
    "sway/config.d/compositv.conf" = {
      text = ''
# Mod4+Mod1+y = OK
# Mod4+Mod1+n = Stop
# Mod4+Mod1+b = Back
# Mod4+Mod1+m = Play/Pause
# Mod4+Mod1+e = Power
set $term alacritty
set $menu fuzzel | xargs swaymsg exec --
font monospace 12
seat seat0 xcursor_theme "Adwaita" 32
output * scale 2
output * bg ${ctv-logo} center
bindsym Mod4+Mod1+n kill
bindsym Mod4+Mod1+m exec $menu & swaymsg mode "app"
bindsym Mod4+Mod1+f fullscreen
bindsym Mod4+Mod1+e exec swaynag -t warning -m "You pressed the power button." -B 'Restart' 'reboot' -B 'Power off' 'poweroff'
bindsym Mod4+Mod1+r reload
mode "app" {
    bindsym Mod4+Mod1+y exec send-key enter && swaymsg mode "default"
    bindsym Mod4+Mod1+n exec send-key esc && swaymsg mode "default"
    bindsym Mod4+Mod1+b exec send-key esc && toggle-osk && swaymsg mode "keyboard"
}

mode "select" {
    bindsym Left focus left
    bindsym Down focus down
    bindsym Up focus up
    bindsym Right focus right
    bindsym Mod4+Mod1+y focus mode_toggle
    bindsym Mod4+Mod1+n mode "default"
    bindsym Mod4+Mod1+b mode "move"
}
mode "move" {
    bindsym Left move left
    bindsym Down move down
    bindsym Up move up
    bindsym Right move right
    bindsym Mod4+Mod1+n mode "default"
    bindsym Mod4+Mod1+b mode "size"
}
mode "size" {
    bindsym Up resize shrink height 16px
    bindsym Down resize grow height 16px
    bindsym Right resize grow width 16px
    bindsym Left resize shrink width 16px
    bindsym Mod4+Mod1+y floating toggle
    bindsym Mod4+Mod1+n mode "default"
    bindsym Mod4+Mod1+b mode "default"
}
#bindsym Mod4+Mod1+s mode "select"

exec wvkbd-mobintl --hidden
bindsym Mod4+Mod1+b exec toggle-osk && swaymsg mode "keyboard"
mode "keyboard" {
    bindsym Left exec mouse-move -16 0
    bindsym Down exec mouse-move 0 16
    bindsym Up exec mouse-move 0 -16
    bindsym Right exec mouse-move 16 0
    bindsym Mod4+Mod1+y exec click-mouse left
    bindsym Mod4+Mod1+n exec toggle-osk && swaymsg mode "default"
    bindsym Mod4+Mod1+b exec toggle-osk && swaymsg mode "select"
    bindsym Mod4+Mod1+m exec toggle-osk && $menu & swaymsg mode "app"
    bindsym Mod4+Mod1+f fullscreen
}
bindsym Left exec mouse-move -16 0
bindsym Down exec mouse-move 0 16
bindsym Up exec mouse-move 0 -16
bindsym Right exec mouse-move 16 0
bindsym Mod4+Mod1+y exec click-mouse left
    #bindsym Mod4+Mod1+m exec $menu & swaymsg mode "app"
    #bindsym Mod4+Mod1+f fullscreen
exec dbus-sway-environment
exec configure-gtk
exec dotoold
      '';
    };
    "xdg/fuzzel/fuzzel.ini" = {
      text = ''
        font=monospace:size=12
      '';
    };
  };

  documentation.nixos.enable = false;

  system.autoUpgrade = {
    enable = true;
    operation = "boot";
  };

#  home-manager.users.tv = {
#    home.pointerCursor = {
#      name = "Adwaita";
#      package = pkgs.gnome.adwaita-icon-theme;
#      size = 32;
#      x11 = {
#        enable = true;
#        defaultCursor = "Adwaita";
#      };
#    };
#    home.stateVersion = "24.05";
#  };

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  services.dbus.enable = true;
  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };

  services.gnome.gnome-keyring.enable = true;

  services.greetd = {
    enable = true;
    settings = {
      initial_session = {
        command = "${pkgs.sway}/bin/sway";
        user = "tv";
      };
      default_session = {
        command = "${pkgs.greetd.tuigreet}/bin/tuigreet --greeting 'Welcome!' --asterisks --remember --remember-user-session --time --cmd ${pkgs.sway}/bin/sway";
        user = "greeter";
      };
    };
  };

  services.udev.extraRules = ''
    KERNEL=="uinput", GROUP="input", MODE="0660", OPTIONS+="static_node=uinput"
  '';
  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
  # to actually do that.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  # system.stateVersion = "24.05"; # Did you read the comment?

}

