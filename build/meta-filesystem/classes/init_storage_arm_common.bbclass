
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
    IB_DEVICE = d.getVar('IB_DEVICE')
    IB_DIR = d.getVar('IB_DIR')
    WORKDIR = d.getVar('WORKDIR')

    store_filename = "sdcard.img." + IB_PLATFORM

    if IB_STORAGE == "soft":

        # Create image first
        print("Creating sdcard.img.{} ...".format(IB_PLATFORM))

        dd_size = IB_ROOTFS_SIZE
        subprocess.run(["truncate", "-s", dd_size, os.path.join(WORKDIR, "sdcard.img.{}".format(IB_PLATFORM))])

        devname = subprocess.run(["sudo", "losetup", "--partscan", "--find", "--show", os.path.join(WORKDIR, "sdcard.img.{}".format(IB_PLATFORM))], capture_output=True, text=True).stdout.strip()

        # Keep device name only without /dev/
        devname = devname.replace("/dev/", "")

        print("Linking the storage image", IB_DIR)

        os.makedirs(os.path.join(WORKDIR, "filesystem"), exist_ok=True)

        target_link = os.path.join(IB_DIR, "filesystem/"+store_filename)
        source_link = os.path.join(WORKDIR, store_filename)

        # Check if the symbolic link already exists
        if os.path.islink(target_link):
            # Remove the existing symbolic link
            os.unlink(target_link)

        os.symlink(source_link, target_link)

    else:

        devname = IB_DEVICE + ":" + IB_PLATFORM

    print("devname is defined as", devname)

    if not os.path.exists("/dev/{}".format(devname)):
        print("Unfortunately, /dev/{} does not exist...".format(devname))
        exit(1)

    # Create the partition layout this way
    fdisk_input = "o\nn\np\n\n\n+128M\nt\nc\na\nn\np\n\n\n+1600M\nw\n"
    subprocess.run(["sudo", "fdisk", "/dev/{}".format(devname)], input=fdisk_input.encode())

    print("Waiting ...")

    # Give a chance to the real SD-card to be sync'd
    time.sleep(2)

    if devname[-1].isdigit():
        devname += "p"

    subprocess.run(["sudo", "mkfs.fat", "-F32", "-a", "-v", "-n", "boot", "/dev/{}1".format(devname)])
    subprocess.run(["sudo", "mkfs.ext4", "-L", "rootfs1", "/dev/{}2".format(devname)])

    if IB_STORAGE == "soft":
        subprocess.run(["sudo", "losetup", "-D"])

    print("Done! The storage is now initialized")



