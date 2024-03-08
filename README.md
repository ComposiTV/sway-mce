# sway-mce
NixOS configuration to create an autostarting Sway session controlled using a remote.

## Installing
From a minimal configuration (generated with `nixos-generate-config`), add the included `compositv.nix` to your imports in `configuration.nix`, alongside `hardware-configuration.nix`.

## Buttons
- xf86dvd/"DVD MENU": Toggle on-screen keyboard, move mouse with directional buttons and click with OK button.
- xf86audiomedia: Opens app launcher.
- "TV": Cycle through window navigation modes.
- xf86close/"Back": Close app or exit launcher/keyboard.
- xf86info/"More": Toggle fullscreen mode.