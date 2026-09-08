#!/bin/bash

# Copyright (c) 2025-2026 EDGEMTech SA

# Resolve project root from this script's own location, cd there, and
# source env.sh — prompting the user first if the parent shell points
# at a different tree. Every relative path below (filesystem/...,
# build/conf/local.conf) is anchored on that root. See
# scripts/common/setup_env.sh.

# Handled before setup_env.sh: printing the help should not trigger the
# tree-switch prompt that sourcing the environment can raise.

case "$1" in
    -h|--help)
        echo "Usage: $(basename "$0") [-d] [qemu-option]"
        echo "  Run the deployed image under QEMU. Headless by default: the"
        echo "  serial console is multiplexed onto stdio."
        echo "    -d   graphical — open an SDL window with a virtio GPU and"
        echo "         virtio keyboard/mouse attached to the guest"
        exit 0
        ;;
esac

. "$(cd "$(dirname "$(command -v -- "$0")")" && pwd)/common/setup_env.sh"

QEMU_AUDIO_DRV="none"
GDB_PORT_BASE=1234

# Parse our own options out of the argument list before what is left is
# forwarded to QEMU as USR_OPTION.

WITH_DISPLAY=0
POSARGS=()
for _a in "$@"; do
    case "$_a" in
        -d) WITH_DISPLAY=1 ;;
        *)  POSARGS+=("$_a") ;;
    esac
done
set -- "${POSARGS[@]}"
USR_OPTION=$1

# Display mode. Headless by default: serial only, no window. With -d, present
# the guest on a virtio GPU in an SDL window and give it virtio input devices
# — the console stays on stdio either way, so a graphical run is still
# scriptable. This replaces the former separate stg.sh.

if [ "$WITH_DISPLAY" = "1" ]; then
    DISPLAY_OPT="-device virtio-gpu-pci -device virtio-keyboard-pci \
		-device virtio-mouse-pci -display sdl"
else
    DISPLAY_OPT="-display none"
fi

# QEMU_BIN is selected per IB_PLATFORM below (qemu-system-aarch64 for
# virt64, qemu-system-arm for virt32).

# Count every emulator, whatever the architecture: "qemu-system-arm" does
# not match "qemu-system-aarch64", so a 64-bit instance used to go
# uncounted and a second run reused its MAC address and GDB port.

N_QEMU_INSTANCES=`ps -A | grep qemu-system | wc -l`

launch_qemu() {
    QEMU_MAC_ADDR="$(printf 'DE:AD:BE:EF:%02X:%02X\n' $((N_QEMU_INSTANCES)) $((N_QEMU_INSTANCES)))"

    GDB_PORT=$((${GDB_PORT_BASE} + ${N_QEMU_INSTANCES}))

    echo -e "\033[01;36mMAC addr: " ${QEMU_MAC_ADDR} "\033[0;37m"
    echo -e "\033[01;36mGDB port: " ${GDB_PORT} "\033[0;37m"

    # Read a plain (non-override) assignment out of the configuration.
    # Reads local.conf THEN site.conf, in the order bitbake.conf includes
    # them, and takes the LAST match: bitbake is last-assignment-wins, so a
    # site.conf override has to win here too — otherwise the launcher would
    # boot a machine differently from how it was built. (An image build may
    # likewise append its own value after the "?=" default.)
    conf_value() {
        cat build/conf/local.conf build/conf/site.conf 2>/dev/null \
            | grep -E "^$1[[:space:]]*[?:]?=" \
            | grep -v "^$1:" \
            | tail -1 | sed -n 's/.*"\([^"]*\)".*/\1/p'
    }

    IB_PLATFORM="$(conf_value IB_PLATFORM)"

    # The hypervisor axis decides whether the guest needs EL2. Defaults to
    # "none" so an older local.conf without the variable behaves as before.
    IB_HYPERVISOR="$(conf_value IB_HYPERVISOR)"
    : "${IB_HYPERVISOR:=none}"

    if [ "$IB_PLATFORM" == "virt64" ]; then
    QEMU_BIN="$IB_ROOT_DIR/qemu/build/qemu-system-aarch64"
    echo Starting on virt64
    # User-mode (slirp) networking: QEMU plays DHCP + DNS + NAT internally, so
    # the guest gets 10.0.2.15 immediately and NetworkManager-wait-online
    # succeeds in <1 s instead of timing out at 60 s as it did with tap+host
    # bridge that had no DHCP server. hostfwd exposes guest SSH on host
    # port 2222 for convenience. Trade-off: guest is NAT'd, no LAN visibility.
    # Bonus: no sudo needed (no tap device creation), so QEMU artefacts stay
    # owned by the regular user across runs.
    #
    # Boot mode is picked from artefacts in filesystem/ (built by bsp.bbclass
    # :do_deploy_boot_chain → bsp_virt64.inc:__do_platform_boot_chain):
    #   * flash0.img present → ATF chain (IB_BOOT_CHAIN=atf+uboot / full,
    #     ATF BL1+FIP, optionally OP-TEE). QEMU exposes EL3 (secure=on) and
    #     pflash-loads BL1+FIP; EL2 enabled so U-Boot's hyp-mode can run.
    #   * flash0.img absent, IB_HYPERVISOR=avz → bare U-Boot chain, but AVZ
    #     is an EL2 hypervisor, so QEMU must still expose EL2
    #     (virtualization=on). No secure world: the two axes are
    #     independent, and AVZ needs EL2 rather than EL3.
    #   * flash0.img absent, IB_HYPERVISOR=none → standalone Linux
    #     (IB_BOOT_CHAIN=uboot). The boot chain is just U-Boot + Linux; QEMU
    #     `-kernel`-loads the U-Boot ELF (u-boot/u-boot) at EL1 directly.
    #     EL2 (and EL3) are deliberately disabled — the qemu-arm64 U-Boot
    #     config expects to run at EL1, and running at EL2 without firmware
    #     handling PSCI / breaking the bootm path triggers a synchronous
    #     external abort during AMBA PL011 probe.

    if [ -f filesystem/flash0.img ]; then
        MACHINE_OPT="-M virt,virtualization=on,gic-version=2,secure=on"
        BOOT_OPT="-drive if=pflash,format=raw,file=filesystem/flash0.img"
    elif [ "$IB_HYPERVISOR" = "avz" ]; then
        echo "AVZ guest on the bare U-Boot chain — enabling EL2 (virtualization=on)"
        MACHINE_OPT="-M virt,gic-version=2,virtualization=on"
        BOOT_OPT="-kernel u-boot/u-boot"
    else
        MACHINE_OPT="-M virt,gic-version=2"
        BOOT_OPT="-kernel u-boot/u-boot"
    fi
    ${QEMU_BIN} $@ ${USR_OPTION} \
		-smp 4  \
		-chardev stdio,id=char0,mux=on,signal=off \
		-mon chardev=char0 \
		-serial chardev:char0 \
		${MACHINE_OPT} -cpu cortex-a72  \
		${BOOT_OPT} \
		-device virtio-blk-device,drive=hd0 \
		-drive if=none,file=filesystem/sdcard.img.virt64,id=hd0,format=raw,file.locking=off \
		-m 1024 \
		${DISPLAY_OPT} \
		-netdev user,id=n1,hostfwd=tcp::2222-:22 \
		-device virtio-net-device,netdev=n1,mac=${QEMU_MAC_ADDR} \
        	-gdb tcp::${GDB_PORT}
	fi

    if [ "$IB_PLATFORM" == "virt32" ]; then
    QEMU_BIN="$IB_ROOT_DIR/qemu/build/qemu-system-arm"
    echo Starting on virt32
    # 32-bit ARM virt: U-Boot is loaded directly with -kernel (no ATF/flash
    # chain on this platform) and cortex-a15 matches the virt32 kernel build.
    # Serial console is muxed onto stdio and networking is slirp, exactly as
    # on virt64. Without this branch a virt32 tree ran nothing at all.
    ${QEMU_BIN} $@ ${USR_OPTION} \
		-smp 4  \
		-chardev stdio,id=char0,mux=on,signal=off \
		-mon chardev=char0 \
		-serial chardev:char0 \
		-M virt -cpu cortex-a15 \
		-kernel u-boot/u-boot \
		-device virtio-blk-device,drive=hd0 \
		-drive if=none,file=filesystem/sdcard.img.virt32,id=hd0,format=raw,file.locking=off \
		-m 1024 \
		${DISPLAY_OPT} \
		-netdev user,id=n1,hostfwd=tcp::2222-:22 \
		-device virtio-net-device,netdev=n1,mac=${QEMU_MAC_ADDR} \
        	-gdb tcp::${GDB_PORT}
	fi

    QEMU_RESULT=$?
}

launch_qemu
