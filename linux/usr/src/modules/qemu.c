
/**
 * uio_evl.c
 *
 * Copyright (c) 2023 Speedgoat GmbH
 * Author: Daniel Rossier, David Truan {daniel.rossier}{david.truan}@edgemtech.ch
 *
 * This driver enables EVL/Xenomai 4 processing along the UIO driver path.
 */
#include <linux/module.h>
#include <linux/slab.h>
#include <linux/init.h>
#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/printk.h>
#include <linux/cdev.h>
#include <linux/interrupt.h>
#include <linux/pci.h>
#include <linux/slab.h>
#include <linux/uio_driver.h>

#include <linux/delay.h>

#include <linux/sched.h>

/* File operations */
#include <linux/fs.h>
#include <asm/segment.h>
#include <asm/uaccess.h>
#include <linux/buffer_head.h>

#include <asm/io.h>

#include <linux/slab.h>

#define DRIVER_VERSION	"0.1"
#define DRIVER_AUTHOR	"Daniel Rossier <daniel.rossier@edgemtech.ch>"
#define DRIVER_DESC	"Speedgoat UIO out-of-band EVL driver"

extern int ____irq, ____prev_irq;

extern struct task_struct *__last_task;
/**
 *
 * @param f
 * @param cmd
 * @param arg
 */
extern int __noresched;
extern void disable_local_APIC(void);
extern void apic_ap_setup(void);

extern void tick_resume_oneshot(void);

long uio_evl_ioctl(struct file *f, unsigned int cmd, unsigned long arg) {

	printk("## Entering ioctl...\n");

	if (irqs_disabled())
		printk("%s: IRQs are disabled\n", __func__);
	else
		printk("%s: IRQs are enabled\n", __func__);

	/* Full disabling LAPIC timer interrupt */
	//disable_local_APIC();

	/* Prevent IPI to be received on CPU #1 */
	__noresched = 1;

	udelay(1000);

	while (1);

	__noresched = 0;

	//apic_ap_setup();

	return 0;
}

/**
 * Open callback to set-up the EVL channel
 *
 * @param inode	- VFS inode bound to the /dev entry
 * @param filp - Reference to the general file structure
 *
 * @return 0 - Success
 */
static int uio_evl_open(struct inode *inode, struct file *filp)
{
	int ret;

	printk("%s: opening QEMU channel...\n", __func__);

	return 0;

}

static int uio_evl_release(struct inode *inode, struct file *filp)
{

	pr_info("Closing qemu channel...\n");

	return 0;
}

/**
 * Our driver callbacks
 */
static struct file_operations uio_dev_fops = {
    .owner = THIS_MODULE,
    .open = uio_evl_open,
    .release = uio_evl_release,
    .unlocked_ioctl = uio_evl_ioctl,

};

static int qemu_mod_init(void) {

	int ret;
	struct cdev __cdev;
	dev_t __dev;
	struct class *__class;
	struct device *__device;

	pr_info("%s: out-of-band EVL UIO initialization..\n", __func__);

	/* Dynamically allocate a major number */

	__dev = register_chrdev(0, "qemu", &uio_dev_fops);

	__class = class_create(THIS_MODULE, "qemu_class");

	device_create(__class, NULL, MKDEV(__dev, 0), NULL, "qemu");

	pr_info("Character device registered with major number %d\n", MAJOR(__dev));


	return 0;
}


module_init(qemu_mod_init)
MODULE_LICENSE("GPL");
MODULE_AUTHOR(DRIVER_AUTHOR);
