# sway-mce
NixOS configuration to create an autostarting Sway session that may be controlled using a remote.

## Installing
From a minimal configuration (generated with `nixos-generate-config`), add the included `compositv.nix` to your imports in `configuration.nix`, alongside `hardware-configuration.nix`.

## Buttons
- Win+Alt+b (Back): Cycle through default/keyboard/select/move/size modes.
- Win+Alt+m (Play/Pause): Opens app launcher.
- Win+Alt+n (Stop): Close app or exit launcher/keyboard.
- Win+Alt+f (No suggestion): Toggle fullscreen mode.
- Win+Alt+y (OK): Left click (default/keyboard), Toggle focus between tiled/floating windows (select), Toggle floating (size).
- Arrow Keys: Move mouse (default/keyboard), Select app (app), Change focus (select), Move window (move), Resize window (size)
## CEC
My attempts to write a CEC client that will send the above keys in response to remote inputs for a real TV have been delayed by NixOS not officially supporting Raspberry Pi 5 and the fact that my Pi 4 seems to be broken.
