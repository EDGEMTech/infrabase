# Copyright (c) 2025-2026 EDGEMTech SA

SUMMARY = "Linux root filesystem (initrd) packaging"
DESCRIPTION = "Overrides rootfs-linux do_deploy to package the buildroot \
               rootfs.cpio as a compressed initrd (initrd.cpio.gz) for the \
               platform, instead of copying files onto a partition."
LICENSE = "GPLv2"

inherit rootfs
inherit filesystem
 
do_deploy[noexec] = "1"
python do_deploy () {
    import shutil
    import gzip

    bb.plain("Transform the rootfs to a compressed initrd")

    IB_TARGET   = d.getVar('IB_TARGET')
    IB_PLATFORM = d.getVar('IB_PLATFORM')

    board_dir   = os.path.join(IB_TARGET, "board", IB_PLATFORM)
    src         = os.path.join(board_dir, "rootfs.cpio")
    initrd      = os.path.join(board_dir, "initrd.cpio")
    initrd_gz   = initrd + ".gz"

    if not os.path.exists(src):
        bb.fatal("rootfs.cpio not found: {}".format(src))

    shutil.move(src, initrd)
    bb.plain("Moved {} -> {}".format(src, initrd))

    with open(initrd, 'rb') as f_in, gzip.open(initrd_gz, 'wb') as f_out:
        shutil.copyfileobj(f_in, f_out)
    bb.plain("Compressed {} -> {}".format(initrd, initrd_gz))

}
addtask do_deploy

