/*
 * Copyright (c) 1980 Regents of the University of California.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. All advertising materials mentioning features or use of this software
 *    must display the following acknowledgement:
 *	This product includes software developed by the University of
 *	California, Berkeley and its contributors.
 * 4. Neither the name of the University nor the names of its contributors
 *    may be used to endorse or promote products derived from this software
 *    without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE REGENTS AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */

/* 1999-02-22 Arkadiusz Mi¶kiewicz <misiek@misiek.eu.org>
 * - added Native Language Support
 */

/* 2000-12-27 Satoru Takabayashi <satoru@namazu.org>
 * - modify `script' to create `ttyrec'.
 */

/*
 * script
 */
#include <sys/types.h>
#include <sys/stat.h>
#include <termios.h>
#include <sys/ioctl.h>
#include <sys/time.h>
#include <sys/file.h>
#include <sys/signal.h>
#include <stdio.h>
#include <unistd.h>
#include <string.h>

#define _XOPEN_SOURCE
#define _GNU_SOURCE
#include <stdlib.h>
#include <fcntl.h>
#include <stropts.h>

#include <sys/time.h>
#include "gttyrec.h"

#define HAVE_inet_aton
#define HAVE_scsi_h
#define HAVE_kd_h

#define _(FOO) FOO

#ifdef HAVE_openpty
#include <pty.h>
#include <utmp.h>
#endif

#if defined(SVR4) && !defined(CDEL)
#if defined(_POSIX_VDISABLE)
#define CDEL _POSIX_VDISABLE
#elif defined(CDISABLE)
#define CDEL CDISABLE
#else				/* not _POSIX_VISIBLE && not CDISABLE */
#define CDEL 255
#endif				/* not _POSIX_VISIBLE && not CDISABLE */
#endif				/* SVR4 && ! CDEL */

#define STDIN 0

void fail(void);
void fixtty(void);
void getmaster(void);
void getslave(void);
void doinput(void);
void dooutput(void);
void doshell(char *[]);
void doquit();
void dochld();
void done();

char *shell;
FILE *fscript;
int master;
int slave;
int child;
int shellchild;
char *fname;

struct termios tt;
struct winsize win;
int lb;
int l;
#if !defined(SVR4)
#ifndef HAVE_openpty
char line[] = "/dev/ptyXX";
#endif
#endif				/* !SVR4 */
int aflg;

extern char **environ;

int
main(int argc, char *argv[]) {
  extern int optind;
  int ch;
  int myargc = 0;
  char **myargv;
  int i;

  shellchild = child = 0;

  myargv = malloc(sizeof(char *) * argc);

  for (i = 1; i < argc; i++) {
    if (!strcmp(argv[i], "-a")) {
      aflg++;
    } else if (!strcmp(argv[i], "-o")) {
      i++;
      if (i < argc)
        fname = argv[i];
    } else if (argv[i][0] == '-') {
      fprintf(stderr, _("usage: %s [-a] [-o file] command [args]\n"), argv[0]);
      exit(1);
    } else {
      /* Start of command */
      break;
    }
  }

  for (; i < argc; i++) {
    myargv[myargc++] = argv[i];
  }
  myargv[myargc] = NULL;

  if (!myargc) {
    myargv[0] = getenv("SHELL");
    if (!myargv[0])
      myargv[0] = "/bin/sh";
    myargv[1] = "-i";
  }

  if (!fname)
    fname = "ttyrecord";

  if ((fscript = fopen(fname, aflg ? "a" : "w")) == NULL) {
    perror(fname);
    fail();
  }
  setbuf(fscript, NULL);

  shell = getenv("SHELL");
  if (shell == NULL)
    shell = "/bin/sh";

  getmaster();
  fixtty();

  child = fork();
  if (child < 0) {
    perror("fork");
    fail();
  }
  if (child == 0) {
    strcpy(argv[0],"child");
    shellchild = fork();
    if (shellchild < 0) {
      perror("fork");
      fail();
    }
    if (shellchild == 0) {
      strcpy(argv[0],"subchild");
      doshell(myargv);
    } else {
      signal(SIGPIPE, dochld);
      signal(SIGTERM, dochld);
      signal(SIGCHLD, dochld);
      signal(SIGHUP,  dochld);
      dooutput();
    }
  } else {
    strcpy(argv[0],"gttyrec master");
    signal(SIGPIPE, doquit);
    signal(SIGTERM, doquit);
    signal(SIGCHLD, doquit);
    signal(SIGHUP,  doquit);
    doinput();
  }
  return 0;
}

void
doinput() {
  ssize_t cc = 0;
  char ibuf[BUFSIZ];

  (void) fclose(fscript);
  fscript = NULL;

  while ((cc = read(STDIN, ibuf, BUFSIZ)) > 0) {
    if (write(master, ibuf, cc) < 0) {
      perror("write");
    }
  }
  if (cc < 0) {
    perror("read");
  }
  done();
}

#include <sys/wait.h>

void
dochld() {
  if (shellchild)
    kill(shellchild,SIGHUP);
  exit(1);
}

void
doquit() {
  if (child) {
    kill(child,SIGTERM);
  }
  tcsetattr(STDIN, TCSAFLUSH, &tt);
  done();
}

void
dooutput() {
  int cc;
  char obuf[BUFSIZ];

  setbuf(stdout, NULL);
  /* close(STDIN); */
  for (;;) {
    Header h;

    cc = read(master, obuf, BUFSIZ);
    if (cc <= 0)
      break;
    h.len = cc;
    gettimeofday(&h.tv, NULL);
    (void) write(1, obuf, cc);
    (void) write_header(fscript, &h);
    (void) fwrite(obuf, 1, cc, fscript);
  }
  done();
}

void
doshell(char *myargv[]) {
  char *cmd;
	/***
	int t;

	t = open(_PATH_TTY, O_RDWR);
	if (t >= 0) {
		(void) ioctl(t, TIOCNOTTY, (char *)0);
		(void) close(t);
	}
	***/
  getslave();
  (void) close(master);
  fclose(fscript);
  fscript = NULL;
  /* close(0); */
  close(1);
  close(2);
  dup2(slave, 0);
  dup2(slave, 1);
  dup2(slave, 2);
  close(slave);

  cmd = myargv[0];
  myargv[0] = strrchr(myargv[0], '/') + 1;
  if (!myargv[0]) {
    myargv[0] = cmd;
  }
  myargv[0] = strdup(myargv[0]);
  execvp(cmd, myargv);
  perror(cmd);
  fail();
}

void
fixtty() {
  struct termios rtt;
  rtt = tt;

  rtt.c_iflag = 0;
  rtt.c_lflag &= ~(ISIG|ICANON|XCASE|ECHO|ECHOE|ECHOK|ECHONL);
  rtt.c_oflag = OPOST;
  rtt.c_cc[VINTR] = CDEL;
  rtt.c_cc[VQUIT] = CDEL;
  rtt.c_cc[VERASE] = CDEL;
  rtt.c_cc[VKILL] = CDEL;
  rtt.c_cc[VEOF] = 1;
  rtt.c_cc[VEOL] = 0;

  (void) tcsetattr(STDIN, TCSAFLUSH, &rtt);
}

void
fail() {

  // (void) kill(0, SIGTERM);
  done();
}

void
done() {
  if (fscript) {
    fclose(fscript);
    fscript = NULL;
  }
  fixtty();
  exit(0);
}

void
getmaster() {
  (void) tcgetattr(STDIN, &tt);
  (void) ioctl(STDIN, TIOCGWINSZ, (char *) &win);

  master = open("/dev/ptmx", O_RDWR);

  if (master < 0) {
    fprintf(stderr,"Unable to open master PTY\n");
    exit(1);
  }
}

char *ptsname(int fd);

void
getslave() {
  (void) setsid();
  grantpt(master);
  unlockpt(master);
  if ((slave = open((const char *) ptsname(master), O_RDWR)) < 0) {
    perror("open(fd, O_RDWR)");
    fail();
  }
  if (isastream(slave)) {
    if (ioctl(slave, I_PUSH, "ptem") < 0) {
      perror("ioctl(fd, I_PUSH, ptem)");
      fail();
    }
    if (ioctl(slave, I_PUSH, "ldterm") < 0) {
      perror("ioctl(fd, I_PUSH, ldterm)");
      fail();
    }
    if (ioctl(slave, I_PUSH, "ttcompat") < 0) {
      perror("ioctl(fd, I_PUSH, ttcompat)");
      fail();
    }
  }
  tcsetattr(slave, TCSAFLUSH, &tt);
  ioctl(STDIN, TIOCGWINSZ, &win);
  ioctl(slave, TIOCSWINSZ, &win);
}
