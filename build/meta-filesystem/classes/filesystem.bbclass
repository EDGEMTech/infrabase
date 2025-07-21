
# Class for filesystem

inherit logging
inherit init_storage_${IB_PLATFORM}

IB_FILESYSTEM_PATH = "${IB_DIR}/filesystem"

# Create and initialize the storage (including formatting partitions) 
def __do_fs_init_storage(d):
 
    IB_STORAGE = d.getVar('IB_STORAGE')
    IB_DEVICE = d.getVar('IB_DEVICE')

    if IB_STORAGE == "remote":
        return None

    if IB_STORAGE == "hard" and IB_DEVICE == "":
        bb.fatal("No device found; please edit conf/local.conf")
     
    # Perform the tasks specific to the platform
    __platform_init_storage(d)
    
    # Finally create a symlink to the workdir to be able
    # to mount/umount properly
    target_link = os.path.join(d.getVar('IB_DIR'), "filesystem/work")
 
    # Check if the symbolic link already exists
    if os.path.islink(target_link):
        # Remove the existing symbolic link
        os.unlink(target_link)

    os.symlink(d.getVar('WORKDIR'), target_link)


python do_fs_init_storage () {
    __do_fs_init_storage(d)
}
addtask do_fs_init_storage
do_fs_init_storage[nostamp] = "1"

# Check the presence of the virtual disk image
# if the deployment is done on the virtual ("soft") storage
# and perform the filesystem:fs_init_storage() if it does not exist.
def __do_check_fs(d):
        IB_PLATFORM = d.getVar('IB_PLATFORM')
        IB_STORAGE = d.getVar('IB_STORAGE')
        IB_FILESYSTEM_PATH = d.getVar('IB_FILESYSTEM_PATH')

        if IB_STORAGE == "soft":
            image_path = os.path.join(IB_FILESYSTEM_PATH, f"sdcard.img.{IB_PLATFORM}")
            if not os.path.isfile(image_path):
                __do_fs_init_storage(d)

python do_check_fs () {
    __do_check_fs(d)
}

do_check_fs[nostamp] = "1"
addtask do_check_fs

# Mount the partitions to p1, p2 respectively
def __do_fs_mount(d):
    import os
    import subprocess
    import json
 
    WORKDIR = d.getVar('IB_FILESYSTEM_PATH') + "/work"
    IB_STORAGE = d.getVar('IB_STORAGE')
    IB_PLATFORM = d.getVar('IB_PLATFORM')
    IB_DEVICE = d.getVar('IB_DEVICE')
    IB_FILESYSTEM_PATH = d.getVar('IB_FILESYSTEM_PATH')

    os.makedirs(os.path.join(WORKDIR, 'p1'), exist_ok=True)
    os.makedirs(os.path.join(WORKDIR, 'p2'), exist_ok=True)

    if IB_STORAGE == "soft":

        devname = subprocess.check_output(
            f"sudo losetup --partscan --find --show {WORKDIR}/sdcard.img.{IB_PLATFORM}", shell=True,
            text=True).strip()

        # Keep device name only without /dev/
        devname = devname.replace("/dev/", "")
    else:
        devname = d.getVar('IB_DEVICE')
    
    shdata = {
        'IB_FILESYSTEM_DEVNAME': devname
    }
  
    with open(os.path.join(d.getVar('TMPDIR'), 'global_datastore.json'), 'w') as f:
        json.dump(shdata, f);
    f.close()
	
    if devname[-1].isdigit():
        devname += "p"

    try:
        subprocess.run(['sudo', 'mount', f'/dev/{devname}1', os.path.join(WORKDIR, 'p1')], check=True)
        subprocess.run(['sudo', 'mount', f'/dev/{devname}2', os.path.join(WORKDIR, 'p2')], check=True)
    except subprocess.CalledProcessError:
        # Handle any errors that occur during mounting
        pass

    if os.path.ismount(os.path.join(WORKDIR, 'p1')):
        if os.path.lexists(IB_FILESYSTEM_PATH + "/p1"):
            os.remove(IB_FILESYSTEM_PATH + "/p1")
        os.symlink(os.path.join(WORKDIR, 'p1'), IB_FILESYSTEM_PATH+"/p1")

    if os.path.ismount(os.path.join(WORKDIR, 'p2')):
        if os.path.lexists(IB_FILESYSTEM_PATH + "/p2"):
            os.remove(IB_FILESYSTEM_PATH + "/p2")
        os.symlink(os.path.join(WORKDIR, 'p2'), IB_FILESYSTEM_PATH+"/p2")
        
# Required to execute commands with sudo
do_fs_mount[nostamp] = "1"

python do_fs_mount () {
    __do_fs_mount(d)
}
addtask do_fs_mount

def __do_main_umount(directory):
    import os 
    
    if os.path.ismount(directory):
        while True:
            # Check if the source directory is still mounted
            if not os.path.ismount(directory):
                break
            
            os.sync()
            time.sleep(1)
            
            # Unmount the source directory
            os.system("sudo umount '{}'".format(directory))
    
    # Remove the target dir
    os.system("sudo rm -rf {}".format(directory))
    

def __do_fs_umount(d):
	
    __do_main_umount(d.getVar('IB_FILESYSTEM_PATH') + "/work/p1")
    __do_main_umount(d.getVar('IB_FILESYSTEM_PATH') + "/work/p2")
	
    os.system("sudo losetup -D")
 
do_fs_umount[nostamp] = "1"

python do_fs_umount() {
  __do_fs_umount(d)
}
addtask do_fs_umount


 

