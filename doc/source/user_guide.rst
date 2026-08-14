.. _user_guide:

User Guide
##########

This chapter is the day-to-day reference: how to get a build environment, how to
configure the target, and how to build, deploy and run a system. The concepts
behind the build system (layers, recipes, tasks, patchsets) are described in the
:ref:`build system chapter <build_system>`.

Everything below assumes an x86_64 Linux host. Ubuntu 24.04 is what the build is
validated on, but the :ref:`container <container>` makes the host distribution
mostly irrelevant.

Getting a build environment
***************************

There are two ways to get one, and they are interchangeable: the tree is built at
its own absolute path in both cases, so you can switch back and forth without
invalidating BitBake stamps or CMake caches.

Using the container (recommended)
=================================

The container carries the *environment* — cross toolchains, host packages,
Python — and no project source. The repository stays on the host, bind-mounted at
its own path, and the build runs as your own user, so nothing comes back
root-owned.

.. code-block:: bash

   $ scripts/dbuild.sh --build              # build the image, once
   $ scripts/dbuild.sh build.sh bsp-linux   # run a build inside it
   $ scripts/dbuild.sh                      # interactive shell, env.sh sourced

See the :ref:`container chapter <container>` for the details, including what
cannot be done from inside (running the emulator's GUI, mounts outliving the
command).

.. note::

   The container also solves a class of host problems for good: it carries its
   own ``sudo`` configuration, so a host whose PAM stack interferes with
   ``sudo -v`` (a fingerprint reader, for instance) can still run
   ``build.sh bsp-linux`` and ``deploy.sh``.

Building on the host
====================

The build requires the **bash** shell.

.. warning::

   On Ubuntu, ``/bin/sh`` points at ``dash``, which does not share bash's
   syntax. If you invoke the scripts through ``sh``, see
   `this procedure <https://askubuntu.com/questions/1064773/how-can-i-make-bin-sh-point-to-bin-bash>`_.

The authoritative list of host packages is
``docker/build-env/packages.txt`` — the same file the container image installs,
one package per line with comments explaining why each group is there. Install it
with:

.. code-block:: bash

   $ sed -e 's/#.*//' -e '/^[[:space:]]*$/d' docker/build-env/packages.txt \
       | xargs sudo apt install -y

That list covers BitBake, the boot images, the storage tooling, the rootfs
pipeline, CMake for the user space, QEMU (building *and* running it) and Sphinx
for this documentation.

Toolchains
----------

The 32-bit cross toolchain comes from apt and is in the list above
(``gcc-arm-linux-gnueabihf``, matching ``IB_TOOLCHAIN:arm``). The 64-bit one is
**not** interchangeable with Ubuntu's: the recipes pin the prefix
``aarch64-none-linux-gnu-``, while ``gcc-aarch64-linux-gnu`` installs
``aarch64-linux-gnu-``. Install the official Arm toolchain (12.3.rel1 is the
version the build is validated with, and the one the container ships):

.. code-block:: shell

   $ sudo mkdir -p /opt/toolchains && cd /opt/toolchains
   $ sudo curl -fSLO "https://developer.arm.com/-/media/Files/downloads/gnu/12.3.rel1/binrel/arm-gnu-toolchain-12.3.rel1-x86_64-aarch64-none-linux-gnu.tar.xz"
   $ sudo tar xf arm-gnu-toolchain-12.3.rel1-x86_64-aarch64-none-linux-gnu.tar.xz
   $ sudo mv arm-gnu-toolchain-12.3.rel1-x86_64-aarch64-none-linux-gnu aarch64-none-linux-gnu
   $ echo 'export PATH="${PATH}:/opt/toolchains/aarch64-none-linux-gnu/bin"' \
       | sudo tee /etc/profile.d/02-toolchains.sh

If the toolchain lives somewhere else, point ``IB_TOOLCHAIN_PATH`` at its
``bin/`` directory instead; ``env.sh`` appends it to ``PATH``.

The environment — ``env.sh``
****************************

Sourcing ``env.sh`` from the top of the tree is required before anything else:

.. code-block:: bash

   $ . ./env.sh

It exports ``IB_ROOT_DIR`` and ``BUILDDIR``, and puts ``scripts/`` and the
bundled ``bitbake`` on your ``PATH`` — which is what lets you invoke a
:term:`standard script` from anywhere inside the tree. It also *removes* the
previous tree's entries, so moving between two checkouts leaves no stale paths.

Every script prints a banner on stderr naming the tree and the platform it is
about to act on:

.. code-block:: text

   [infrabase] bsp-linux  root=/home/user/infrabase  platform=virt64

It is worth a glance: the scripts resolve the *target tree* from the current
directory (falling back to their own location), so running a script from another
checkout prompts you before switching, and refuses outright when
non-interactive.

Configuration
*************

The project configuration lives in ``build/conf/local.conf``. All project
variables use the ``IB_`` prefix, and BitBake's override syntax
``VAR:<override>`` scopes a value to a platform or a component. Read the comments
in the file — they carry the reasoning behind each default.

A second, **untracked** file is read *after* it: ``build/conf/site.conf``. That is
where a single machine deviates from the tracked defaults, without dirtying the
repository. It is absent on most machines.

Platforms
=========

``IB_PLATFORM`` selects the target platform (BitBake calls it the *machine*):

.. list-table::
   :header-rows: 1
   :widths: 20 80

   * - Name
     - Platform
   * - *virt64*
     - QEMU ``virt``, 64-bit (aarch64) — **the default**
   * - *virt32*
     - QEMU ``virt``, 32-bit (arm)
   * - *rpi4_64*
     - Raspberry Pi 4 in 64-bit mode
   * - *rpi4*
     - Raspberry Pi 4 in 32-bit mode
   * - *x86-qemu*
     - QEMU x86 platform

``verdin-imx8mp`` (Toradex Verdin iMX8M Plus) is configured in ``local.conf`` —
kernel recipe, toolchain, U-Boot 2024.07 and the TEZI network install — but has
no BSP include in this tree yet, so it cannot be built as it stands.

.. note::

   After changing ``IB_PLATFORM``, rebuild *and* redeploy. Component trees are
   attached in place, so a stale kernel or buildroot ``.config`` from the previous
   platform can survive; ``build.sh -c <recipe>`` forces a clean re-attach.

Key variables
=============

.. list-table::
   :header-rows: 1
   :widths: 34 66

   * - Variable
     - Meaning
   * - ``IB_PLATFORM``
     - Target platform, see above.
   * - ``IB_CONFIG:linux:<plat>``
     - Kernel defconfig, e.g. ``virt64_defconfig``.
   * - ``IB_TARGET_ITS:linux:<plat>``
     - ITS basename used to build the FIT image (``<name>.itb``).
   * - ``IB_BOOT_CHAIN``
     - ``""`` bare U-Boot (default), ``atf+uboot``, or ``full`` (adds OP-TEE).
   * - ``IB_STORAGE_MODE:<plat>``
     - Where a deploy writes: ``soft`` loopback image, ``hard`` real device,
       ``http`` network install; ``remote``/``local`` also exist.
   * - ``IB_STORAGE_DEVICE:<plat>``
     - Device for ``hard`` mode, without ``/dev/``. **No default on purpose** —
       a wrong one could overwrite a host disk.
   * - ``IB_ROOTFS_METHOD``
     - ``buildroot`` (default) or ``debootstrap``.
   * - ``IB_ROOTFS_SIZE``
     - Storage image size, default ``2G``.
   * - ``IB_ROOTFS_PARTITION:<plat>``
     - Partition holding the rootfs (``p2`` on ARM, ``p1`` on *x86-qemu*).
   * - ``IB_PLAT_CPU``, ``IB_TOOLCHAIN``
     - Architecture and cross-compiler prefix per platform.
   * - ``IB_BUILD_QEMU``
     - Set to ``"0"`` to stop a BSP build from bootstrapping QEMU.
   * - ``IB_HTTP_DEPLOY_PATH``
     - Where an ``http`` deploy publishes its files; defaults inside the tree
       (``build/deploy/tezi/<plat>``).
   * - ``IB_HTTP_FEED_PORT``
     - Port ``tezi-feed-serve.sh`` listens on, default ``8080``.
   * - ``IB_FORCE_ATTACH``
     - ``1`` overrides the dirty-tree guard on ``do_attach_infrabase``.

Building
********

Components are built with the ``build.sh`` :term:`standard script`:

.. code-block:: text

   build.sh [-h] [-l] [-c] [-v] [-x] <recipe>

The **recipe name is a positional argument**. The ``-x`` flag is an optional,
no-op marker kept for explicitness — ``build.sh bsp-linux`` and
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

A **BSP recipe** (``bsp-linux``) pulls its whole dependency tree; a **component**
recipe (``uboot``, ``linux``, ``rootfs-linux``, ``buildroot``, ``usr-linux``,
``qemu``, ``filesystem``, ``atf``, ``optee``) builds just itself.

.. code-block:: bash

   $ build.sh bsp-linux          # full Linux BSP (kernel + rootfs + user space + FIT)
   $ build.sh linux              # rebuild just the kernel
   $ build.sh -c uboot           # clean + rebuild u-boot
   $ build.sh -v -c bsp-linux    # clean + rebuild everything, verbose
   $ build.sh -l                 # list all recipes

On the QEMU platforms (*virt32*, *virt64*), a BSP build also **builds the
emulator when its binary is missing**, so a fresh tree is runnable with ``st.sh``
right away. This is a bootstrap only: an already-built emulator is left
untouched, and the QEMU-hacking loop stays the explicit ``build.sh qemu``. Set
``IB_BUILD_QEMU = "0"`` in ``local.conf`` to skip it — useful in CI, which builds
and deploys but never runs the emulator.

.. note::

   ``bitbake`` itself runs **unprivileged**. The build steps that need root
   (``filesystem`` creating the image, ``bsp-linux`` loop-mounting the rootfs)
   escalate individual commands via ``sudo -n`` against a timestamp the script
   opens once — you are prompted for your password at most once per invocation.

Running a task by hand
======================

Tasks normally run through the dependency graph, but any single one can be
invoked from the ``build/`` directory, *without* the ``do_`` prefix:

.. code-block:: bash

   $ bitbake linux -c patch
   $ bitbake linux -c updiff        # regenerate the patchset, see the build system chapter

Storage
*******

``IB_STORAGE_MODE`` decides where a deploy writes: a loopback image
(``soft``, the default on *virt64*), a real block device (``hard``), or an HTTP
feed for a network install (``http``).

The storage image is ``filesystem/sdcard.img.<platform>``. A deploy creates it
when it is missing, so the explicit step below is rarely needed:

.. code-block:: bash

   $ init_storage.sh          # partition + mkfs the storage image/device

To inspect or edit its contents, mount the two partitions — boot (FAT) as
``filesystem/p1``, rootfs (ext4) as ``filesystem/p2``:

.. code-block:: bash

   $ mount.sh                 # mount p1 + p2
   $ umount.sh                # unmount them

Both wrap the ``filesystem`` recipe tasks (``fs_mount`` / ``fs_umount``); the
``losetup``/``mount`` calls escalate via ``sudo -n``.

.. warning::

   **Unmount before redeploying** — ``deploy.sh`` reuses an existing mount
   instead of making a fresh one. And with ``IB_STORAGE_MODE = "hard"`` the
   target is a *real* block device named by ``IB_STORAGE_DEVICE``: double-check
   ``local.conf``.

Editing an archive instead of the storage
=========================================

The same two scripts also open the **cpio archives**, which is what you want when
the target is the initrd rather than the SD card:

.. code-block:: bash

   $ mount.sh -i              # extract board/<plat>/initrd.cpio into filesystem/p1
   $ umount.sh -i             # repack it

A cpio archive is not a block image, so there is nothing to loop-mount:
"mounting" it means extracting it into a tree you can edit, and unmounting means
repacking. Both run under ``fakeroot``, so the archive keeps its root ownership
and modes **without sudo and without bitbake** — the fake-ownership database is
saved on mount and replayed on umount.

For the cases that need real root (``cpio -id`` restoring device nodes) the
bitbake path is still there, unpacking into the recipe's own workdir:

.. code-block:: bash

   $ mount.sh ramfs                    # rootfs-linux's initrd.cpio
   $ mount.sh rootfs rootfs-linux      # ... or its rootfs.cpio
   $ umount.sh ramfs                   # repack with the matching call

``mount.sh -h`` and ``umount.sh -h`` spell out all of it.

.. _user_guide_deployment:

Deployment
**********

.. code-block:: text

   deploy.sh [-h] [-l] [-v] [-x] <recipe>

Like ``build.sh``, the recipe is a **positional argument** (``-x`` optional and
no-op), and ``deploy.sh`` inherits the state left by the prior ``build.sh``.
Deploying the BSP recipe writes the full image:

.. code-block:: bash

   $ deploy.sh bsp-linux         # boot chain + FIT to p1, rootfs to p2

It creates the storage image if needed, mounts it, then copies the bootloader and
the ``.itb`` to the boot partition and the root filesystem to the second one.
Deployment can also be done per component — after rebuilding only the user space,
redeploy just that:

.. code-block:: bash

   $ deploy.sh usr-linux

``deploy.sh -l`` lists the recipes that define a ``do_deploy`` task (it is a
little slow: it queries *bitbake* per recipe).

.. note::

   As with the build, ``bitbake`` runs **unprivileged** and the privileged
   operations (``mount``, ``losetup``, ``mkfs``, ``parted``, …) escalate via
   ``sudo -n`` against a timestamp opened once at the start of the deploy.

Network install (``http`` mode)
===============================

On a platform whose ``IB_STORAGE_MODE`` is ``http``, the deploy does not write a
storage device at all: it publishes a file set the board downloads and installs
over the network. The files land in ``IB_HTTP_DEPLOY_PATH``, which defaults
**inside the tree** (``build/deploy/tezi/<platform>``) — no web-server document
root to arrange, no root privilege, and nothing written outside the tree.

``deploy.sh`` then starts a server for it, so a deploy leaves a working feed
behind with no manual step:

.. code-block:: bash

   $ tezi-feed-serve.sh              # serve in the foreground
   $ tezi-feed-serve.sh --status     # is it running, and on which URL?
   $ tezi-feed-serve.sh --stop       # stop a detached server

It is a plain ``python3 -m http.server`` on ``IB_HTTP_FEED_PORT`` (8080 by
default, so it runs as your user), rooted at the feed directory. ``--status``
prints the URL to hand to the board. To publish somewhere else on one machine —
a real web server's document root, say — override ``IB_HTTP_DEPLOY_PATH`` in
``build/conf/site.conf`` rather than in the tracked ``local.conf``.

Running the emulated system
***************************

``st.sh`` launches the freshly deployed image in the patched QEMU built by the
``qemu`` recipe:

.. code-block:: bash

   $ st.sh        # headless: serial multiplexed on stdio, no display
   $ st.sh -d     # graphical: adds virtio-gpu/keyboard/mouse and an SDL window

It handles *virt64* and *virt32*, picking the emulator binary from
``IB_PLATFORM`` (``qemu-system-aarch64`` / ``qemu-system-arm``). The serial
console stays on stdio in graphical mode too, so a run with ``-d`` remains
scriptable. Any argument other than ``-d`` and ``-h`` is passed through to
QEMU — ``st.sh -S`` freezes the machine at reset, waiting for a debugger.

The boot mode is picked from ``filesystem/flash0.img``: present means the ATF
chain (``-M virt,virtualization=on,secure=on`` plus the pflash image), absent
means bare U-Boot loaded with ``-kernel u-boot/u-boot`` at EL1.

Networking is user-mode (slirp): the guest gets its address immediately, needs no
``sudo`` and no ``tap`` device, and guest SSH is forwarded to host port ``2222``
(``ssh -p 2222 root@localhost``). A GDB stub listens on ``tcp::1234``, offset by
the number of emulators already running so two instances never collide.

User space applications
***********************

Custom applications and out-of-tree kernel modules live in ``linux/usr`` and are
built with CMake by the ``usr-linux`` recipe. See
:ref:`Linux user applications <linux_usr>` for how they are installed into the
root filesystem.

For a tight edit-compile loop, ``makeusr.sh`` reproduces what the recipe does in
``do_build`` — CMake plus ``make``, and the kernel modules — without going
through bitbake. Run it from inside ``linux/usr``:

.. code-block:: bash

   $ cd linux/usr && makeusr.sh
   $ makeusr.sh -M               # skip the kernel modules
   $ makeusr.sh -C               # remove build/ and exit
   $ makeusr.sh -h               # all options

It needs the buildroot toolchain to have been built once (it takes the CMake
toolchain file from ``linux/rootfs/host``), and it deploys locally into
``linux/usr/build/deploy``. A full ``deploy.sh usr-linux`` is still what puts the
result into the target rootfs.
