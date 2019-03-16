/* This program should connect to the serial port given on the command
 * line, at 2000000 baud, 8-N-1, and print any output received.
 */

/*
 * Copyright (c) 2009 ThingMagic, Inc.
 * Copyright (c) 2019 Patrick Pelletier
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/select.h>
#include <fcntl.h>
#include <termios.h>
#include <unistd.h>
#include <errno.h>
#include <string.h>
#include <sys/ioctl.h>

#ifdef __APPLE__
#include <sys/ioctl.h>
#include <IOKit/serial/ioss.h>
#endif

/* Code in s_open() is derived from ThingMagic's Mercury API code:
 * http://www.thingmagic.com/images/Downloads/software/mercuryapi-1.29.3.34.zip
 */

static int
s_open(const char *devicename)
{
    int ret;
    struct termios t;
    int handle;

    handle = open(devicename, O_RDWR | O_NOCTTY);
    if (handle == -1)
        return -1;

    /*
     * Set 8N1, disable high-bit stripping, soft flow control, and hard
     * flow control (modem lines).
     */
    ret = tcgetattr(handle, &t);
    if (-1 == ret)
        return -1;
    t.c_iflag &= ~(ICRNL | IGNCR | INLCR | INPCK | ISTRIP | IXANY
                   | IXON | IXOFF | PARMRK);
    t.c_oflag &= ~OPOST;
    t.c_cflag &= ~(CRTSCTS | CSIZE | CSTOPB | PARENB);
    t.c_cflag |= CS8 | CLOCAL | CREAD | HUPCL;
    t.c_lflag &= ~(ECHO | ICANON | IEXTEN | ISIG);
    t.c_cc[VMIN] = 0;
    t.c_cc[VTIME] = 1;
    ret = tcsetattr(handle, TCSANOW, &t);
    if (-1 == ret)
        return -1;

    /* Set baud rate to 2000000 (baud rate used by LTO Flash!) */
#if defined(__APPLE__)
    {
        speed_t speed = 2000000;

        if (ioctl(handle, IOSSIOSPEED, &speed) == -1)
            return -1;
    }
#else
    {
        struct termios t;

        tcgetattr(handle, &t);

        cfsetispeed(&t,B2000000);
        cfsetospeed(&t,B2000000);

        if (tcsetattr(handle, TCSANOW, &t) != 0)
            return -1;
    }
#endif

    return handle;
}

/* Adapted from code posted by intvnut on AtariAge:
 * http://atariage.com/forums/topic/289194-using-serial-connection-on-lto-flash/#entry4238319
 */

int serial_recv_byte(int serial_fd)
{
    char    c = -1;
    ssize_t r;
    int     ready;

    for ( ; ; )
    {
        fd_set serial_fd_set;
        FD_ZERO( &serial_fd_set );
        FD_SET ( serial_fd, &serial_fd_set );

        ready = select( serial_fd + 1, &serial_fd_set, NULL, NULL, NULL );

        if ( !ready )
            continue;

        errno = 0;
        if ( ( r = read( serial_fd, &c, 1 ) ) == 1 )
            return c & 0xFF;

        if ( errno != 0 &&
             errno != EINTR && errno != EAGAIN && errno != EWOULDBLOCK )
        {
            return -1;
        }
    }
}

int main (int argc, char **argv) {
    int fd;
    const char *dev;
    int c;

    if (argc != 2) {
        fprintf (stderr, "Usage: show-serial device-file\n");
        return EXIT_FAILURE;
    }

    dev = argv[1];
    fd = s_open (dev);
    if (fd == -1) {
        perror (dev);
        return EXIT_FAILURE;
    }

    for ( ; ; ) {
        c = serial_recv_byte (fd);
        if (c < 0) {
            perror (dev);
            close (fd);
            return EXIT_FAILURE;
        } else {
            fputc (c, stdout);
            fflush (stdout);
        }
    }
}
