/*
 * Copyright (C) 2014-2025 Daniel Rossier <daniel.rossier@heig-vd.ch>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 as
 * published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 *
 */

#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <assert.h>
#include <stdio.h>

#include <sys/ioctl.h>

#include <soo/uapi/soo.h>

#include <zip.h>

int fd_core;

int main(int argc, char *argv[]) {
	int ret;
	struct zip_t *zip;
        struct agency_ioctl_args args;
       
        printf("*** SOO - Mobile Entity snapshot saver ***\n");

	if (argc != 2) {
		printf("## Usage is : saveme <filename> where <filename> is the file containing the ME snapshot.\n");
		exit(-1);
	}

	printf("** Now taking the memory snapshot.\n");

	fd_core = open("/dev/soo/core", O_RDWR);
	assert(fd_core > 0);

        args.slotID = 2;
        args.value = 0; /* To get the size of the snapshot */

	/* Get the size of the snapshot */
        ret = ioctl(fd_core, AGENCY_IOCTL_READ_SNAPSHOT, &args);
        assert(ret == 0);

	/* The use of %zu formatter enables to print a size_t variable regardless the underlying architecture. */
        printf("  * Size of the snapshot: %zu bytes.\n", args.value);
        
	/* Get the snapshot */
	args.buffer = malloc(args.value);
	assert(args.buffer != NULL);

	/* Get the size of the snapshot */
        ret = ioctl(fd_core, AGENCY_IOCTL_READ_SNAPSHOT, &args);
        assert(ret == 0);

        printf("  * Saving to the file...");
        fflush(stdout);

        /* Compress the snapshot */
	zip = zip_open(argv[1], ZIP_DEFAULT_COMPRESSION_LEVEL, 'w');

	zip_entry_open(zip, "me");
	zip_entry_write(zip, args.buffer, args.value);
	zip_entry_close(zip);

	zip_close(zip);

	close(fd_core);

	printf("done.\n\n");
	printf("  * snapshot saved successfully\n");

	return 0;
}
