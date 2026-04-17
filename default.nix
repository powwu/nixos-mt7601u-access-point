{ pkgs
, lib
, kernel ? pkgs.linuxPackages.kernel
}:

let
  kernelPostPatch = kernel.postPatch or "";
in
pkgs.stdenv.mkDerivation {
  pname = "mt7601u-kernel-module";
  inherit (kernel) src version;

  nativeBuildInputs = kernel.nativeBuildInputs or [ ];

  kernel_dev = kernel.dev;
  kernelVersion = kernel.modDirVersion;

  modulePath = "drivers/net/wireless/mediatek/mt7601u";

  postPatch = ''
    ${kernelPostPatch}

    mt7601u_init="$modulePath/init.c"

    if [ ! -e "$mt7601u_init" ]; then
      echo "mt7601u driver source was not found in kernel $kernelVersion" >&2
      exit 1
    fi

    if grep -Fq "BIT(NL80211_IFTYPE_AP)" "$mt7601u_init"; then
      echo "mt7601u AP interface mode is already enabled"
    else
      substituteInPlace "$mt7601u_init" \
        --replace-fail \
        "wiphy->interface_modes = BIT(NL80211_IFTYPE_STATION);" \
        "wiphy->interface_modes = BIT(NL80211_IFTYPE_STATION) |
				 BIT(NL80211_IFTYPE_AP);"
    fi
  '';

  buildPhase = ''
    BUILT_KERNEL=$kernel_dev/lib/modules/$kernelVersion/build

    cp $BUILT_KERNEL/Module.symvers .
    cp $BUILT_KERNEL/.config        .

    if [ -e "$kernel_dev/vmlinux" ]; then
      cp $kernel_dev/vmlinux .
    fi

    make "-j$NIX_BUILD_CORES" modules_prepare
    make "-j$NIX_BUILD_CORES" M=$modulePath modules
  '';

  installPhase = ''
    make INSTALL_MOD_PATH="$out" XZ="xz -T$NIX_BUILD_CORES" M="$modulePath" modules_install
  '';

  meta = {
    description = "MediaTek MT7601U kernel module with access-point patch";
    license = lib.licenses.gpl2;
  };
}
