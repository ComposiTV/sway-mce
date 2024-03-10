# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, ... }:

let

  home-manager = builtins.fetchTarball "https://github.com/nix-community/home-manager/archive/master.tar.gz";

  ctv-logo = pkgs.fetchurl {
    url = "https://4906.org/m/compositv.png";
    sha256 = "e54994679b94f7e1e42212bd6a58b733005f6aec4e8cf6102366283e6cd91e75";
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
      echo key $1 | dotoolc
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
      echo click $1 | dotoolc
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
  imports = [
    (import "${home-manager}/nixos")
  ];

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
#    v4l-utils
    wayland
    wvkbd
    xdg-utils
  ];

  environment.etc = {
    "sway/config.d/compositv.conf" = {
      text = ''
exec dotoold
# 360 - OK
# 385 - TV
set $term alacritty
set $menu fuzzel | xargs swaymsg exec --
font monospace 12
seat seat0 xcursor_theme "Adwaita" 32
output * scale 2
output * bg ${ctv-logo} center
bindsym xf86close kill
bindsym xf86audiomedia exec $menu & swaymsg mode "app"
bindsym xf86info fullscreen

mode "app" {
    bindcode 360 exec send-key enter && swaymsg mode "default"
    bindsym xf86close exec send-key esc && swaymsg mode "default"
    bindsym xf86dvd exec send-key esc && toggle-osk && swaymsg mode "keyboard"
}

mode "select" {
    bindsym Left focus left
    bindsym Down focus down
    bindsym Up focus up
    bindsym Right focus right
    bindcode 360 focus mode_toggle
    bindcode 385 mode "move"
    bindsym xf86close mode "default"
}
mode "move" {
    bindsym Left move left
    bindsym Down move down
    bindsym Up move up
    bindsym Right move right
    bindcode 385 mode "size"
    bindsym xf86close mode "default"
}
mode "size" {
    bindsym Up resize shrink height 16px
    bindsym Down resize grow height 16px
    bindsym Right resize grow width 16px
    bindsym Left resize shrink width 16px
    bindcode 360 floating toggle
    bindcode 385 mode "default"
    bindsym xf86close mode "default"
}
bindcode 385 mode "select"

exec wvkbd-mobintl --hidden
bindsym xf86dvd exec toggle-osk && swaymsg mode "keyboard"
mode "keyboard" {
    bindsym Left exec mouse-move -16 0
    bindsym Down exec mouse-move 0 16
    bindsym Up exec mouse-move 0 -16
    bindsym Right exec mouse-move 16 0
    bindcode 360 exec click-mouse left
    bindsym xf86close exec toggle-osk && swaymsg mode "default"
    bindsym xf86dvd exec toggle-osk && swaymsg mode "mouse"
    bindsym xf86audiomedia exec toggle-osk && $menu & swaymsg mode "app"
}
mode "mouse" {
    bindsym Left exec mouse-move -16 0
    bindsym Down exec mouse-move 0 16
    bindsym Up exec mouse-move 0 -16
    bindsym Right exec mouse-move 16 0
    bindcode 360 exec click-mouse left
    bindsym xf86close mode "default"
    bindsym xf86dvd mode "default"
    bindsym xf86audiomedia exec $menu & swaymsg mode "app"
}
exec dbus-sway-environment
exec configure-gtk
      '';
    };
    "xdg/fuzzel/fuzzel.ini" = {
      text = ''
        font=monospace:size=12
      '';
    };
  };

  documentation.nixos.enable = false;

  home-manager.users.tv = {
    home.pointerCursor = {
      name = "Adwaita";
      package = pkgs.gnome.adwaita-icon-theme;
      size = 32;
      x11 = {
        enable = true;
        defaultCursor = "Adwaita";
      };
    };
    home.stateVersion = "24.05";
  };

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

