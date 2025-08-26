/*
 * Copyright (C) 2023 Jean-Pierre Miceli <jean-pierre.miceli@heig-vd.ch>
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

#include <chrono>
#include <cstdlib>
#include <fcntl.h>
#include <fstream>
#include <iostream>

#include <string.h>
#include <unistd.h>

#include <zip.h>

#include <sys/ioctl.h>

#include <soo/uapi/soo.h>

#include "container.hpp"

using namespace std;

#define EMISO_IMAGE_PATH "/mnt/ME/"
#define EMISO_CAPSULE_CACHE_DIR "/mnt/capsule/cache"

#define SOO_CORE_DRV_PATH "/dev/soo/core"

#define LOG_PREFIX "[EMISO:DAEMON] "

/* Create an emiso namespace (but why actually?) */
namespace emiso {

map<int, ContainerId> Container::_containersId;

Container::Container(){};

Container::~Container(){};

// Convert a ME state into the Docker Container state
//      valid container states are: running, paused, exited, restarting, dead
string Container::meToDockerState(int meState) {

        printf(LOG_PREFIX "Docker state: %d\n", meState);

        switch (meState) {
        case ME_state_stopped:
                return "created";

        case ME_state_living:
                return "running";

        case ME_state_suspended:
                return "paused";

        case ME_state_killed:
                return "dead";

        case ME_state_terminated:
                return "exited";

        case ME_state_dead:
                return "dead";
        }

        return "(n/a)";
}

uint64_t Container::createdTime() {
        const auto now = chrono::system_clock::now();
        const auto epoch = chrono::duration_cast<chrono::seconds>(now.time_since_epoch()).count();

        return epoch;
}

void Container::info(map<int, ContainerInfo> &containerList) {
        int i, fd;
        ME_id_t id_array[MAX_ME_DOMAINS];
        agency_ioctl_args_t args;
        int ME_size;
        unsigned char *ME_buffer;

        fd = open(SOO_CORE_DRV_PATH, O_RDWR);
        if ((fd < 0)) {
                printf(LOG_PREFIX "Failed to open soo /dev entry...\n");
                exit(EXIT_FAILURE);
        }

        args.buffer = &id_array;
        ioctl(fd, AGENCY_IOCTL_GET_ME_ID_ARRAY, (unsigned long) &args);

        close(fd);
        printf("info 0\n");

        for (i = 0; i < MAX_ME_DOMAINS; i++) {
                if (id_array[i].state != ME_state_dead) {
                        ContainerInfo info;
                        int slotID = i + 2;
                        
                        printf("info 1 %d\n", slotID);
                        info.id = slotID;
                        info.name = _containersId[slotID].name;
                        info.image = _containersId[slotID].image;
                        info.created = _containersId[slotID].created;
                        info.state = this->meToDockerState(id_array[i].state);

                        containerList[i] = info;
                }
        }
}

/**
 * @brief Get ??
 * 
 * @param info 
 */
void Container::info(ContainerInfo &info) {
        int i, fd;
        ME_id_t id_array[MAX_ME_DOMAINS];
        agency_ioctl_args_t args;
        int ME_size;
        unsigned char *ME_buffer;

        fd = open(SOO_CORE_DRV_PATH, O_RDWR);
        if ((fd < 0)) {
                printf(LOG_PREFIX "Failed to open soo /dev entry...\n");
                exit(EXIT_FAILURE);
        }

        args.buffer = &id_array;
        ioctl(fd, AGENCY_IOCTL_GET_ME_ID_ARRAY, (unsigned long) &args);

        close(fd);

        if (id_array[i].state != ME_state_dead) {
                int slotID = i + 2;

                info.id = slotID;
                info.name = _containersId[slotID].name;
                info.image = _containersId[slotID].image;
                info.created = _containersId[slotID].created;
                info.state = this->meToDockerState(id_array[i].state);
        }
}

/**
 * @brief  The create() method of Container leads to the injection of a capsule, but
 *         without starting its execution. It will perform a snapshot, write it to
 *         a specific location and shutdown the stopped capsule.
 *
 * @param imageName    Name of the capsule (without .itb suffix)
 * @param containerName
 * @param slotID
 * @return int
 */
int Container::create(string imageName, string containerName) {
        int fd;
        int ret;
        struct agency_ioctl_args args;
        struct stat filestat;
        char *containerBuf;
        int nread;
        streampos containerSize;
        char filename[80];
        struct zip_t *zip;

        cout << LOG_PREFIX "Create container " << containerName << " from image " << imageName << endl;

        sprintf(filename, EMISO_IMAGE_PATH "%s.itb", imageName.c_str());

        ifstream image(filename, ios::in | ios::binary | ios::ate);

        if (!image.is_open()) {
                cerr << LOG_PREFIX "Error: Failed to open image file '" << filename << "'" << endl;
                return EXIT_FAILURE;
        }

        containerSize = image.tellg();

        containerBuf = new char[containerSize];

        image.seekg(0, ios::beg);
        image.read(containerBuf, containerSize);

        image.close();

        args.buffer = containerBuf;
        args.value = containerSize;

        args.slotID = -1; /* Wherever */

        fd = open(SOO_CORE_DRV_PATH, O_RDWR);
        if (fd < 0) {
                printf("[EMISO:DAEMON] Failing to open /dev soo entry ...\n");
                exit(EXIT_FAILURE);
        }

        /* Inject the capsule - which will be stopped after being loaded in memory */
        ret = ioctl(fd, AGENCY_IOCTL_INJECT_CAPSULE, &args);

        if ((ret < 0) || (args.slotID == -1)) {
                printf("[EMISO:DAEMON] No available ME slot further...\n");
                exit(EXIT_FAILURE);
        }

        ContainerId id;
        id.name = containerName;
        id.image = imageName;
        id.created = this->createdTime();

        _containersId[args.slotID] = id;

        delete[] containerBuf;

        /* Save the snapshot to the capsule cache directory */

        args.value = 0; /* To get the size of the snapshot */

        /* Get the size of the snapshot */
        ret = ioctl(fd, AGENCY_IOCTL_READ_SNAPSHOT, &args);
        if (ret < 0) {
                printf(LOG_PREFIX "Get the size with IOCTL_READ_SNAPSHOT failed.\n");
                return EXIT_FAILURE;
        }

        args.buffer = new char[args.value];

        ret = ioctl(fd, AGENCY_IOCTL_READ_SNAPSHOT, &args);
        if (ret < 0) {
                printf(LOG_PREFIX "Read the snapshot IOCTL_READ_SNAPSHOT failed.\n");
                return EXIT_FAILURE;
        }

        strcat(strcat(strcpy(filename, EMISO_CAPSULE_CACHE_DIR), "/"), containerName.c_str());

        /* Compress the snapshot */
        zip = zip_open(filename, ZIP_DEFAULT_COMPRESSION_LEVEL, 'w');
        if (!zip) {
                printf(LOG_PREFIX "Failed to open the zip file. Is there a bad sync after saving the snapshot?...\n");
                perror("");
                return EXIT_FAILURE;
        }
        zip_entry_open(zip, "me");
        zip_entry_write(zip, args.buffer, args.value);
        zip_entry_close(zip);

        zip_close(zip);

        /* Shutdown the capsule so that it will be removed from the memory */

        ret = ioctl(fd, AGENCY_IOCTL_SHUTDOWN, &args);
        if (ret < 0) {
                printf(LOG_PREFIX "Read the snapshot IOCTL_READ_SNAPSHOT failed.\n");
                return EXIT_FAILURE;
        }

        close(fd);

        return args.slotID;
}

/**
 * @brief Start an existing container, i.e. a container which has ben previously saved
 *        right after its injection.
 *
 * @param containerName
 * @param containerId
 * @return
 */
int Container::start(string containerName) {
        int fd;
        int ret;
        struct agency_ioctl_args args;
        void *buffer = NULL;
        size_t buffer_size;
        struct zip_t *zip;
        char filename[80];

        cout << LOG_PREFIX "Start container " << containerName << endl;

        /* Open the channel to the kernel soo submodule. */
        fd = open(SOO_CORE_DRV_PATH, O_RDWR);
        if ((fd < 0)) {
                printf(LOG_PREFIX "Failed to open soo /dev entry...\n");
                exit(EXIT_FAILURE);
        }

        strcat(strcat(strcpy(filename, EMISO_CAPSULE_CACHE_DIR), "/"), containerName.c_str());

        zip = zip_open(filename, 0, 'r');
        if (!zip) {
                printf(LOG_PREFIX "Failed to open the zip file. Is there a bad sync after saving the snapshot?...\n");
                return EXIT_FAILURE;
        }

        zip_entry_open(zip, "me");
        zip_entry_read(zip, &args.buffer, &buffer_size);
        zip_entry_close(zip);

        zip_close(zip);

        /* Restore the snapshot which is in <stopped> stated */
        cout << LOG_PREFIX "Re-implementing snapshot of size " << buffer_size << " bytes." << endl;
        args.slotID = -1;

        ret = ioctl(fd, AGENCY_IOCTL_WRITE_SNAPSHOT, &args);
        if (ret < 0) {
                printf("Failed to initialize migration (%d)\n", ret);
        }

        free(buffer);

        close(fd);

        return ret;
}

int Container::stop(unsigned containerId) {
        int ret;
        int fd;
        struct agency_ioctl_args args;

        // == Shutdown a capsule ==
        args.slotID = containerId;

        printf("** Perform a shutdown of capsule #%d (slotID %d)...", containerId, containerId + 1);
        fflush(stdout);

        fd = open(SOO_CORE_DRV_PATH, O_RDWR);
        if ((fd < 0)) {
                printf("[EMISO:DAEMON] Failed to open soo /dev entry...\n");
                exit(EXIT_FAILURE);
        }

        ret = ioctl(fd, AGENCY_IOCTL_SHUTDOWN, &args);
        if (ret < 0) {
                printf("Failed to force termination (%d)\n", ret);
        }

        close(fd);

#if 0
    string imageName;
    string containerName;

    // 1. Retrieve the image file
    auto it = _containersId.find(containerId);

    if (it != _containersId.end()) {
        imageName     = it->second.image;
        containerName = it->second.name;

    } else {
        // BUG - the ME has to be in _containersId MAP
    }

    // experiment - let time to free the slot memory !
    sleep(0.5);

    int slotId = this->create(imageName, containerName);
#endif

        return ret;
}

int Container::restart(unsigned containerId) {
#if 0
    cout << "[DAEMON] Restart cmd - stop" << endl;
    this->stop(containerId);
    
    cout << "[DAEMON] Restart cmd - start" << endl;
    
    this->start(containerId);

    cout << "[DAEMON] Restart cmd - completed" << endl;
#endif
        return 0;
}

int Container::pause(unsigned containerId) {
        int fd;
        int ret;
        struct agency_ioctl_args args;

        args.slotID = containerId;

        fd = open(SOO_CORE_DRV_PATH, O_RDWR);
#if 0
    ret = ioctl(fd, AGENCY_IOCTL_INIT_MIGRATION, &args);
#endif
        if (ret < 0) {
                printf("Failed to initialize migration (%d)\n", ret);
        }

        return ret;
}

int Container::unpause(unsigned containerId) {
        int fd;
        int ret;
        struct agency_ioctl_args args;

        args.slotID = containerId;

        fd = open(SOO_CORE_DRV_PATH, O_RDWR);
#if 0
    ret = ioctl(fd, AGENCY_IOCTL_FINAL_MIGRATION, &args);
#endif
        if (ret < 0) {
                printf("Failed to initialize migration (%d)\n", ret);
        }

        close(fd);

        return ret;
}

/**
 * @brief Shutdown a container
 * 
 * @param containerId 
 * @return 
 */
int Container::remove(unsigned containerId) {
        int ret;
        int fd;
        struct agency_ioctl_args args;

        // == Force ME termination ==
        args.slotID = containerId;

        fd = open(SOO_CORE_DRV_PATH, O_RDWR);
        ret = ioctl(fd, AGENCY_IOCTL_SHUTDOWN, &args);
        if (ret < 0) {
                printf("Failed to shutdown (%d)\n", ret);
        }

        return ret;
}

vector<string> Container::retrieveLogs(unsigned containerId, unsigned lineNr) {
        vector<string> lines;

        // Create the file path
        string fileName = "/var/log/soo/me_" + to_string(containerId) + ".log";

        cout << "[DEBUG] Logfile name: " << fileName << endl;

        // Read the file
        ifstream file(fileName);

        if (!file.is_open()) {
                cerr << "Error opening file: " << fileName << endl;
                return lines; // return empty vector if file couldn't be opened
        }

        string line;
        while (getline(file, line) && lineNr-- > 0) {
                lines.push_back(line);
        }

        file.close();
        return lines;
}

} // namespace emiso
