
# Specific task description for formatting
# the storage of ARM platform with 3 partitions

# Partition layout is as follows:
# - Partition #1: 128 MB (u-boot, kernel, etc.)
# - Partition #2: 400 MB (Main rootfs)
# - Partition #3: 100 MB (A data partition used for SO3 capsules for example)

def __platform_init_storage(d):
    import os
    import subprocess

    IB_STORAGE = d.getVar('IB_STORAGE')
    IB_ROOTFS_SIZE = d.getVar('IB_ROOTFS_SIZE')
    IB_PLATFORM = d.getVar('IB_PLATFORM')
    IB_STORAGE_DEVICE = d.getVar('IB_STORAGE_DEVICE')
    IB_DIR = d.getVar('IB_DIR')
    WORKDIR = d.getVar('WORKDIR')

    store_filename = f"sdcard.img.{IB_PLATFORM}"
    store_path = os.path.join(WORKDIR, store_filename)
    devname = IB_STORAGE_DEVICE

    if IB_STORAGE == "soft":

        # Create image first
        print(f"Creating {store_path}")

        dd_size = IB_ROOTFS_SIZE
        subprocess.run(["truncate", "-s", dd_size, store_path])

        devname = subprocess.run(["losetup", "--partscan", "--find", "--show", store_path],
                capture_output=True, text=True).stdout.strip()
        print(devname)

        if devname == "":
            bb.fatal(f"{store_path}")

        # Keep device name only without /dev/
        devname = devname.replace("/dev/", "")

        print("Linking the storage image", IB_DIR)

        os.makedirs(os.path.join(WORKDIR, "filesystem"), exist_ok=True)

        target_link = os.path.join(IB_DIR, f"filesystem/{store_filename}")
        source_link = store_path

        # Check if the symbolic link already exists
        if os.path.islink(target_link):
            # Remove the existing symbolic link
            os.unlink(target_link)

        os.symlink(source_link, target_link)



    if not os.path.exists(f"/dev/{devname}"):
        print(f"Unfortunately, /dev/{devname} does not exist...")
        exit(1)

    print(f"Partitioning and formatting: {devname}")

    # Create the partition layout this way
    # TODO: use sfdisk(8) which is more suitable for scripting
    fdisk_input = "o\nn\np\n\n\n+128M\nt\nc\na\nn\np\n\n\n+1600M\nw\n"
    subprocess.run(["fdisk", f"/dev/{devname}"], input=fdisk_input.encode())

    print("Waiting ...")

    # TODO: use ionotify(7)
    # Give a chance to the real SD-card to be sync'd
    time.sleep(2)

    if devname[-1].isdigit():
        devname += "p"

    subprocess.run(["mkfs.fat", "-F32", "-a", "-v", "-n", "boot", f"/dev/{devname}1"])
    subprocess.run(["mkfs.ext4", "-L", "rootfs1", f"/dev/{devname}2"])

    if IB_STORAGE == "soft":
        subprocess.run(["losetup", "-D"])

    print("Done! The storage is now initialized")

