# Installation
## With flakes
In your configuration's `flake.nix`:
```
inputs = {
    mt7601u-access-point = {
        url = "github:powwu/nixos-mt7601u-access-point";
    };
};
```
Then import the NixOS module and enable it:
```
{
  outputs = { nixpkgs, mt7601u-access-point, ... }: {
    nixosConfigurations.your-host = nixpkgs.lib.nixosSystem {
      modules = [
        mt7601u-access-point.nixosModules.default
        ({ ... }: {
          hardware.mt7601u-access-point.enable = true;
        })
      ];
    };
  };
}
```
The module builds the driver against `config.boot.kernelPackages.kernel`, so it follows whichever kernel package set your system already uses.

Alternatively, add the overlay and pass the active kernel explicitly:
```
{
  nixpkgs.overlays = [
    inputs.mt7601u-access-point.overlays.default
  ];

  boot.extraModulePackages = [
    (pkgs.mt7601u-access-pointFor config.boot.kernelPackages.kernel)
  ];
}
```

## As a local package
In your `configuration.nix`:
```
let mt7601u-kernel-module = pkgs.callPackage ../pkgs/nixos-mt7601u-access-point/default.nix { kernel = config.boot.kernelPackages.kernel; }; in {
  boot.extraModulePackages = [ mt7601u-kernel-module ];
};
```
Point the default.nix path to this repo. (in my case, it's in /etc/nixos/pkgs/, while my `configuration.nix` is in /etc/nixos/nixos/). **You may need to remove .git from the cloned directory.** Depending on how you reference the repository, you may need to add the `--impure` argument to your `nixos-rebuild`. If this happens, try using a relative path instead of an absolute one.

## With boot.kernelPatches (not recommended)
In your `configuration.nix`:
```
boot.kernelPatches = [
  {
    name = "mt7601u-access-point";
    patch = (pkgs.fetchFromGitHub {
      owner = "powwu";
      repo = "nixos-mt7601u-access-point";
      rev = "182783ad73a2b86c39ae7da511ec61892dc0fa32";
      hash = "sha256-n+kpsvV2JOBPGPHVJVUnicybhn98rKNuw2QBKNuh/Ss=";
     } + /access-point.patch );
  }
];
```
**This is not recommended** as the system will rebuild your entire kernel instead of only the module. However, it is the option with the lowest maintenance.

### Installation notes
- You may have to set `coherent_pool=4M` as a command-line kernel parameter for proper functionality.

# Usage
Apply configuration and reboot (or use modprobe). From here, you should see it available for AP mode with `iw list` (may need to run `nix-shell -p iw`):
```
Supported interface modes:
		 * managed
		 * AP
		 * AP/VLAN
		 * monitor
```
You can bring an access point up with `nmcli device wifi hotspot con-name access-point` if using NetworkManager. Performance is subpar, do not plan on usage for reliability-dependent tasks such as gaming or voice/video calls.
