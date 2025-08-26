###################################################################
#
#   Various utility functions
#
#   Copyright (c) 2025 EDGEMTech Ltd
#
#   Authors: 
#       EDGEMTech Ltd, Daniel Rossier (daniel.rossier@edgemtech.ch)
#       EDGEMTech Ltd, Erik Tagirov (erik.tagirov@edgemtech.ch)
#
###################################################################

def base_set_filespath(path, d):
    filespath = []
    extrapaths = (d.getVar("FILESEXTRAPATHS") or "")

    # Remove default flag which was used for checking
    extrapaths = extrapaths.replace("__default:", "")

    # Don't prepend empty strings to the path list
    if extrapaths != "":
        path = extrapaths.split(":") + path

    # The ":" ensures we have an 'empty' override
    overrides = (":" + (d.getVar("FILESOVERRIDES") or "")).split(":")
    overrides.reverse()
    for o in overrides:
        for p in path:
            if p != "":
                filespath.append(os.path.join(p, o))
    return ":".join(filespath)

# Check if the user is root
def utils_chk_is_root_user(d):

    import os

    if os.geteuid() == 0:
        return True

    return False

# Get uid of the user that ran sudo or su, by
# getting the username via logname(1) which uses
# the user name of the active session similar to who -m
def utils_get_user_uid():
    import subprocess

    try:
        login_name = subprocess.check_output(["logname"],
            stderr=subprocess.DEVNULL).strip().decode()

        uid = subprocess.check_output(["id", "-u", login_name],
            stderr=subprocess.DEVNULL).strip().decode()

    except Exception as e:
        bb.fatal(f"Failed to retrieve user name error: {e}")

    return int(uid)

# Change the owner of a file or directory to the user that opened the
# the session because for the filesystem or rootfs recipes bitbake
# is executed through sudo, Therefore
# changing back to the user required to avoid
# the need for sudo when cleaning the build/tmp directory
def utils_chown_file(path, follow_symlinks=True, recursive=True):
    import os
    import subprocess

    uid = utils_get_user_uid()

    try:
        param = "-"

        if follow_symlinks:
            param = f"{param}L"

        if os.path.isdir(path) and recursive:
            param = f"{param}R"

        if os.path.islink(path):
            # Change the owner of the link itself
            subprocess.check_output(["chown", f"{uid}:{uid}", path]).strip().decode()

        if param != "-":
            subprocess.check_output(["chown", param, f"{uid}:{uid}", path]).strip().decode()
        else:
            subprocess.check_output(["chown", f"{uid}:{uid}", path]).strip().decode()

    except Exception as e:
        bb.fatal(f"Failed to change the owner of dir/file: {path} error: {e}")


# Change ownership of directory -
# seperate function for clarity at the call site
def utils_chown_dir(dir_path, follow_symlinks=True, recursive=True):

    utils_chown_file(dir_path, follow_symlinks, recursive)

# Changes ownership of bitbake cache tmp/cache
# and the temp dir of the task
# NOTE: This is only called by tasks executed as root
def utils_restore_user_ownership(d):

    CACHE_PATH = d.getVar("CACHE")
    WORKDIR = d.getVar("WORKDIR")

    # Reset the ownership incl. symlinks bitbake creates
    utils_chown_dir(CACHE_PATH)
    utils_chown_dir(CACHE_PATH, follow_symlinks=False)

    utils_chown_dir(f"{WORKDIR}/temp")
    utils_chown_dir(f"{WORKDIR}/temp", follow_symlinks=False)
