.. _user_guide:

User Guide
##########
   
The installation should work in any Ubuntu/Kubuntu installation superior
to ``20.04``. It is assumed that you are running an x86_64 version.

The following description is used to build the different target boards
including the emulated environment based upon QEMU.

According to the board and requirements of your configuration, all components
are not necessary such as OPTEE-OS or even U-boot if you use x86 boards.

Pre-requisites
**************

Shell
=====

The build system requires the **bash** shell.

.. warning::

   With Ubuntu 22.04, the default shell is now ``dash`` which does not
   have the same syntax as *bash*. Please have a look at 
   `this procedure <https://askubuntu.com/questions/1064773/how-can-i-make-bin-sh-point-to-bin-bash>`_ 
   to replace *dash* by *bash* 

Packages
========

The following packages need to be installed:

.. code:: bash


    sudo apt install make cmake gcc-arm-none-eabi libc-dev \
    bison flex bash patch mount dtc \
    dosfstools u-boot-tools net-tools \
    bridge-utils iptables dnsmasq libssl-dev \
    util-linux e2fsprogs
 
Since the documentation relies on `Sphinx <https://www.sphinx-doc.org>`_, 
the python environment is required as well as some additional extensions:

.. code:: bash

   sudo apt install python3
   pip install sphinxcontrib-openapi sphinxcontrib-plantuml

If OPTEE-OS is required, the following python packages are required:

.. code:: bash

   pip3 install pycryptodome
   sudo apt install python3-pyelftools


Toolchain
=========
 
The AArch-32 (ARM 32-bit) toolchain can be installed with the following commands:

.. code-block:: shell

   $ sudo mkdir -p /opt/toolchains && cd /opt/toolchains
   # Download and extract arm-none-linux-gnueabihf toolchain (gcc v9.2.1).
   $ sudo wget https://developer.arm.com/-/media/Files/downloads/gnu-a/9.2-2019.12/binrel/gcc-arm-9.2-2019.12-x86_64-arm-none-linux-gnueabihf.tar.xz
   $ sudo tar xf gcc-arm-9.2-2019.12-x86_64-arm-none-linux-gnueabihf.tar.xz
   $ sudo rm gcc-arm-9.2-2019.12-x86_64-arm-none-linux-gnueabihf.tar.xz
   $ sudo mv gcc-arm-9.2-2019.12-x86_64-arm-none-linux-gnueabihf arm-none-linux-gnueabihf_9.2.1
   $ sudo echo 'export PATH="${PATH}:/opt/toolchains/arm-none-linux-gnueabihf_9.2.1/bin"' | sudo tee -a /etc/profile.d/02-toolchains.sh

For the 64-bit version (virt64 & RPi4), we are using the `aarch64-none-linux-gnu toolchain version 12.1.rel1 <ARM_toolchain_>`_,
which is the official ARM toolchain. 

Configuration options
*********************

The main configuration of the project resides in the ``build/conf/local.conf`` file.

Be sure to check the default values for each variable and read the comments.

Platforms
=========

The ``IB_PLATFORM`` variable defines the target platform (also known as "machine").

The following values are possible target platforms:

+----------------+-------------------------------+
| Name           | Platform                      |
+================+===============================+
| *virt32*       | QEMU 32-bit emulated platform |
+----------------+-------------------------------+
| *virt64*       | QEMU 64-bit emulated platform |
+----------------+-------------------------------+
| *rpi4*         | Raspberry Pi 4 in 32-bit mode |
+----------------+-------------------------------+
| *rpi4_64*      | Raspberry Pi 4 in 64-bit mode |
+----------------+-------------------------------+
| *bbb*          | BeagleBone Black platform     |
+----------------+-------------------------------+
| *x86*          | x86 PC platform               |
+----------------+-------------------------------+
| *x86_qemu*     | x86 PC emulated platform      |
+----------------+-------------------------------+
| *imx8_colibri* | x86 PC emulated platform      |
+----------------+-------------------------------+

Execution of a *bitbake* task
*****************************

Tasks can be executed manually or automatically depending of the dependency scheme as 
defined for a specific recipe.

For manual execution, the task can be executed with the following command, 
from the ``build/`` directory:

.. code-block:: bash

   bitbake *<recipe>* -c *<task>*

Where *<task>* is the name **without** the ``do_`` prefix. For example, the *do_patch* task is
executed as follows:

.. code-block:: bash

   bitbake linux -c patch

Build script
************

Before using any :term:`standard script` environment variables must be set,
it can be achieved with the following command:

.. code-block:: bash

   $ source env.sh

Components are built using the ``build.sh`` standard script.

.. code-block:: text

   build.sh [-h] [-l] [-c] [-v] [-x] <recipe>

The **recipe name is a positional argument**. The ``-x`` flag is an optional,
no-op marker kept for explicitness/symmetry — ``build.sh bsp-linux`` and
``build.sh -x bsp-linux`` are equivalent. Options come *before* the recipe.

+--------+----------------------------------------------------------------+
| Option | Effect                                                         |
+========+================================================================+
| ``-l`` | List all available recipes (BSPs and components).              |
+--------+----------------------------------------------------------------+
| ``-c`` | Clean the recipe first (``-c clean``), then rebuild.           |
+--------+----------------------------------------------------------------+
| ``-v`` | Verbose build logs (``-vDDD``).                                |
+--------+----------------------------------------------------------------+
| ``-x`` | Optional "build this recipe" marker (recipe stays positional). |
+--------+----------------------------------------------------------------+
| ``-h`` | Print help.                                                    |
+--------+----------------------------------------------------------------+

A **BSP recipe** (e.g. ``bsp-linux``) pulls its whole dependency tree; a
**component** recipe (``uboot``, ``linux``, ``rootfs``, ``usr-linux``, ``qemu``,
``filesystem``, ``atf``, ``optee``) builds just itself.

.. code-block:: bash

   $ build.sh bsp-linux          # full Linux BSP (kernel + buildroot userspace + fs image)
   $ build.sh linux              # rebuild just the kernel
   $ build.sh -c uboot           # clean + rebuild u-boot
   $ build.sh -v -c bsp-linux    # clean + rebuild everything, verbose
   $ build.sh -l                 # list all recipes

.. note::

   ``bitbake`` itself runs **unprivileged**. Recipes that need root at build
   time (``bsp-linux`` loop-mounts the rootfs, ``filesystem`` creates the image)
   escalate individual commands via ``sudo -n`` against a sudo timestamp opened
   once by the script — you are prompted for your password at most once.

QEMU
****

The installation of *QEMU* depends on the necessity to have the emulated framebuffer or not.
Currently, the QEMU macine is ``virt`` and is referred as **virt32** for 32-bit and **virt64**
for 64-bit versions in *Infrabase*.

For the standard installation, QEMU can be installed via the standard ``apt-get`` command.
There are two possible versions of QEMU according to the architecture (32-/64-bit)

.. code-block:: shell

   $ sudo apt-get install qemu-system-arm      (for 32-bit version)
   $ sudo apt-get install qemu-system-aarch64  (for 64-bit version)

In the case of the patched version (with framebuffer enabled), QEMU can be built using the build system with
the following command:

.. code-block:: bash

   $ build.sh -x qemu

The script will invoke the build task of the QEMU recipe.

If you wish to compile QEMU using ``build.sh -x qemu``, the following packages are required:

.. code:: bash

   sudo apt install python3-pip ninja-build libglib2.0-dev libsdl2-dev

 
The following configurations are available:

+-----------------------+-------------------------------------+
| Name                  | Platform                            |
+=======================+=====================================+
| *vexpress_defconfig*  | Basic QEMU/vExpress 32-bit platform |
+-----------------------+-------------------------------------+
| *virt64_defconfig*    | QEMU/virt 64-bit platform           |
+-----------------------+-------------------------------------+
| *rpi_4_32b_defconfig* | Raspberry Pi 4 in 32-bit mode       |
+-----------------------+-------------------------------------+
| *rpi4_64_defconfig*   | Raspberry Pi 4 in 64-bit mode       |
+-----------------------+-------------------------------------+

(The last one is a custom configuration and is to be used as replacemenent
of rpi_4_defconfig)


Root filesystem (*rootfs*)
**************************

Main root filesystem (**rootfs**)
=================================

The main root filesystem (*rootfs*) contains all application and configuration files
required by the distribution. It actually refers to user space activities.

The storage image is ``filesystem/…/sdcard.img.<platform>``. To mount its
partitions (boot = ``p1``, rootfs = ``p2``) under the ``filesystem`` recipe
workdir:

.. code-block:: bash

   $ mount.sh

And to unmount:

.. code-block:: bash

   $ umount.sh

Both wrap the ``filesystem`` recipe tasks (``fs_mount`` / ``fs_umount``). In
``soft`` storage mode (the default for *virt64*) the image is attached via a
loop device. ``bitbake`` runs unprivileged; the mount/losetup calls escalate via
``sudo -n`` — you may be prompted for your password once. If the image does not
yet exist, create it first with:

.. code-block:: bash

   $ init_storage.sh          # partition + mkfs the storage image/device

.. warning::

   **Unmount before redeploying** — otherwise ``fs_mount`` sees ``p2`` already
   mounted and skips it. And with ``IB_STORAGE_MODE = "hard"`` the target is a
   *real* block device (``IB_STORAGE_DEVICE``): double-check ``local.conf``.

.. _user_guide_deployment:

Deployment
**********

Once the build is complete, one can deploy the results to an SD card image, a
directory or even a physical disk device. When using the latter, be sure to
double-check ``IB_STORAGE_MODE`` / ``IB_STORAGE_DEVICE`` in ``conf/local.conf``.

.. code-block:: text

   deploy.sh [-h] [-l] [-v] [-x] <recipe>

Like ``build.sh``, the recipe is a **positional argument** (``-x`` optional/no-op)
and ``deploy.sh`` inherits the build state left by the prior ``build.sh`` for the
same recipe. Deploying the BSP recipe writes the full image:

.. code-block:: bash

   $ deploy.sh bsp-linux         # full BSP: boot chain + .itb to p1, rootfs to p2

This creates the SD card image if it doesn't exist, mounts it (loop device in
``soft`` mode), copies the bootloader/``.itb`` to the boot partition and the
rootfs to the second partition.

Deployment can also be done per-component — e.g. after rebuilding only the
userspace, re-deploy just that part:

.. code-block:: bash

   $ deploy.sh usr-linux

``mount.sh`` / ``umount.sh`` let you inspect the image contents by browsing the
mounted ``pX`` directories.

``deploy.sh -l`` lists only recipes that define a ``do_deploy`` task (it is a bit
slow, as it queries *bitbake* per recipe).

.. note::

   ``bitbake`` runs **unprivileged**. The privileged deploy operations
   (``mount`` / ``losetup`` / ``mkfs`` / ``parted`` / …) escalate individually
   via ``sudo -n`` against a sudo timestamp opened once at the start of the
   deploy — you may be prompted for your password a single time. (Earlier
   versions ran *bitbake* itself as root; that is no longer the case.)

Running the emulated system (QEMU)
**********************************

For *virt64*, two standard scripts launch the freshly deployed image in the
patched QEMU (``qemu/build/qemu-system-aarch64``):

.. code-block:: bash

   $ st.sh        # headless: serial multiplexed on stdio, no display
   $ stg.sh       # graphical: adds virtio-gpu/keyboard/mouse + an SDL window

Both auto-detect the boot mode from ``filesystem/flash0.img``: present → ATF
chain (``-M virt,virtualization=on,secure=on`` + pflash), absent → bare U-Boot
(``-kernel u-boot/u-boot`` at EL1). User-mode networking forwards the guest SSH
to host port ``2222`` (``ssh -p 2222 …@localhost``), and a GDB stub is exposed on
``tcp::1234`` (offset by the number of running QEMU instances). Extra QEMU
arguments can be passed through (e.g. ``st.sh -S`` to freeze at reset for GDB).

User space applications
***********************

Custom user applications as well as kernel modules are located in
``linux/usr``.

The build system for user applications relies on *Cmake*.


.. _ARM_toolchain: https://developer.arm.com/-/media/Files/downloads/gnu/12.2.rel1/binrel/arm-gnu-toolchain-12.2.rel1-x86_64-aarch64-none-linux-gnu.tar.xz?rev=6750d007ffbf4134b30ea58ea5bf5223&hash=6C7D2A7C9BD409C42077F203DF120385AEEBB3F5

