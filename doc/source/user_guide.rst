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

The script ``build.sh`` has two kind options, 'component options' ``[-a|-b|-x|-k|-f|-r]``
and 'global behaviour' options. All component options may have an optional argument which is
the name of a specific recipe to execute.

.. code-block:: bash

   $ build.sh -a bsp-linux

This builds everything needed to produce a system
with a Linux kernel and the user space system utilities provided by Buildroot.


It is also to build a specific component, for example, to build the kernel
use the following command: ``build.sh -k linux``

To see all the recipes that are provided by the ``meta-kernel`` layer,
one can use the ``-l`` option combined with the ``-k`` option.

.. code-block::

   $ build.sh -l -k
   linux
   avz
   so3

The other global options are ``-v`` which outputs verbose logs,
``-c`` which allows to build the task from scratch and finally ``-h`` which prints
the help menu. The order in which the options are specified is important.

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

To mount the rootfs, the following command can be executed:

.. code-block:: bash

   $ mount.sh rootfs

The mounting point is the directory ``filesystem/pX``.

And to unmount:

.. code-block:: bash

   $ umount.sh rootfs

To mount, un-mount and access loop devices, root privileges are required -
you will be prompted to enter your password.

Initial ramfs (initrd) filesystem
=================================

The initial rootfs filesystem, aka *ramfs* (or *initrd*) is loaded in RAM during the kernel
boot. It aims at starting user space applications dedicated to initialization; firmware loading
and mounting specific storage can be achieved at this moment.

To mount the ramfs, the following command can be executed:

.. code-block:: bash

   $ mount.sh ramfs

The mounting point is the directory ``fs/``.

And to unmount:

.. code-block:: bash

   $ umount.sh ramfs

Running ``mount.sh`` without arguments mounts all partitions.

.. _user_guide_deployment:

Deployment
**********

Once the build is complete, one can deploy the results to a SD card image, a directory or even a physical disk device.
When using the later method - be sure to double check the configuration in ``conf/local.conf``.

Most commonly, deployment is achieved by running ``deploy.sh -a <name_of_bsp_recipe>`` e.g: ``deploy.sh -a bsp-linux``,

This invocation will create an SD card image if it doesn't exist, then mount it on a ``/dev/loopXX`` device
The bootloader and `.itb` will then be copied to the first partition and the rootfs to the second partition.

``deploy.sh`` follows the same usage convention as ``build.sh``

A deployment can be done on a per-component basis, for example if one makes changes
to a recipe provided by the ``meta-rootfs`` layer
and rebuilds it. It is then possible to re-deploy the updated rootfs to the second partition
like so: ``deploy.sh -r rootfs-linux``

``mount.sh`` and ``unmount.sh`` can mount/unmount the file system image, this allows to inspect the contents
simply by browsing the ``filesystem/pX`` directories.

To get the exact name of a deployable recipe use the ``-l`` option combined with the ``-a``, ``-b``, ``-x`` or ``-r``
component type options.

The ``-l`` option is currently quite slow, because it re-executes *bitbake* for each recipe
to check if recipe defines a ``do_deploy`` task.

.. note::

   ``deploy.sh`` requires root priviledges to be able to mount the disk image on the ``/dev/loopXX`` devices -
   you may be prompted for your password. 

   Moreover, during deployment *bitbake* is invoked with root
   priviledges. This is not the case with Yocto, recent versions will complain about running *bitbake* as root.
   Unfortunately, the use *fakeroot* commands does not allow to use ``losetup`` correctly.

User space applications
***********************

Custom user applications as well as kernel modules are located in
``linux/usr``.

The build system for user applications relies on *Cmake*.


.. _ARM_toolchain: https://developer.arm.com/-/media/Files/downloads/gnu/12.2.rel1/binrel/arm-gnu-toolchain-12.2.rel1-x86_64-aarch64-none-linux-gnu.tar.xz?rev=6750d007ffbf4134b30ea58ea5bf5223&hash=6C7D2A7C9BD409C42077F203DF120385AEEBB3F5

