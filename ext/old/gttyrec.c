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

#if defined(SVR4)
#define _GNU_SOURCE
#include <stdlib.h>
#include <fcntl.h>
#include <stropts.h>
#endif				/* SVR4 */

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

void fail(void);
void fixtty(void);
void getmaster(void);
void getslave(void);
void doinput(void);
void doinout(void);
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
  if (1) {
    /* This is my change for select() */
    shellchild = child;
    child = 0;
    if (shellchild == 0) {
      // printf("Starting shell...\r\n");
      doshell(myargv);
    }
    signal(SIGCHLD, dochld);
    signal(SIGINT, dochld);
    signal(SIGPIPE, dochld);
    signal(SIGTERM, dochld);
    signal(SIGHUP,  dochld);
    // printf("Starting inout...\r\n");
    sleep(1);
    doinout();
  } else {
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
        signal(SIGCHLD, dochld);
        signal(SIGPIPE, dochld);
        signal(SIGTERM, dochld);
        signal(SIGHUP,  dochld);
        dooutput();
      }
    } else {
      strcpy(argv[0],"gttyrec master");
      signal(SIGCHLD, doquit);
      signal(SIGPIPE, doquit);
      signal(SIGTERM, doquit);
      signal(SIGHUP,  doquit);
      doinput();
    }
  }
  return 0;
}

void
doinput() {
  register int cc;
  static char ibuf[BUFSIZ];

  (void) fclose(fscript);
  fscript = NULL;
#ifdef HAVE_openpty
  (void) close(slave);
#endif
  while ((cc = read(0, ibuf, BUFSIZ)) > 0)
    (void) write(master, ibuf, cc);
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
  tcsetattr(0, TCSAFLUSH, &tt);
  done();
}

void
doinout() {
  int cc;
  char obuf[BUFSIZ];
  char ibuf[BUFSIZ];
  int fdmax;
  fd_set activefds;

  fdmax = master + 1;
  /* fcntl(0, F_SETFL, O_NONBLOCK); */
  /* fcntl(master, F_SETFL, O_NONBLOCK); */

  /* setbuf(stdout, NULL); */

#ifdef  HAVE_openpty
  (void) close(slave);
#endif
  for (;;) {
    FD_ZERO(&activefds);
    FD_SET(master, &activefds);
    FD_SET(0, &activefds);

    // printf("Hitting select() ...\r\n");
    select(fdmax, &activefds, NULL, NULL, NULL);
    // printf("Done with select() ...\r\n");

    /* Pass from the process to the user, while recording it */
    if (FD_ISSET(master, &activefds)) {
      // printf("  Activity on master ...\r\n");
      Header h;

      if (cc = read(master, obuf, BUFSIZ) >= 0) {
	h.len = cc;
	gettimeofday(&h.tv, NULL);
	(void) write(1, obuf, cc);
	// (void) write_header(fscript, &h);
	// (void) fwrite(obuf, 1, cc, fscript);
	// } else  {
	// break;
      }
    }

    /* Pass from the user to the process */
    if (FD_ISSET(0, &activefds)) {
      // printf("  Activity on stdin ...\r\n");
      if ((cc = read(0, ibuf, BUFSIZ)) >= 0) {
	write(master, ibuf, cc);
      }
    }
  }
}

void
dooutput() {
  int cc;
  char obuf[BUFSIZ];

  setbuf(stdout, NULL);
  (void) close(0);
#ifdef HAVE_openpty
  (void) close(slave);
#endif
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
#if defined(SVR4)
  rtt.c_iflag = 0;
  rtt.c_lflag &= ~(ISIG | ICANON | XCASE | ECHO | ECHOE | ECHOK | ECHONL);
  rtt.c_oflag = OPOST;
  rtt.c_cc[VINTR] = CDEL;
  rtt.c_cc[VQUIT] = CDEL;
  rtt.c_cc[VERASE] = CDEL;
  rtt.c_cc[VKILL] = CDEL;
  rtt.c_cc[VEOF] = 1;
  rtt.c_cc[VEOL] = 0;
#else				/* !SVR4 */
  cfmakeraw(&rtt);
  rtt.c_lflag &= ~ECHO;
#endif				/* !SVR4 */
  (void) tcsetattr(0, TCSAFLUSH, &rtt);
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
#if defined(SVR4)
  (void) tcgetattr(0, &tt);
  (void) ioctl(0, TIOCGWINSZ, (char *) &win);
  if ((master = open("/dev/ptmx", O_RDWR)) < 0) {
    perror("open(\"/dev/ptmx\", O_RDWR)");
    fail();
  }
#else				/* !SVR4 */
#ifdef HAVE_openpty
  (void) tcgetattr(0, &tt);
  (void) ioctl(0, TIOCGWINSZ, (char *) &win);
  if (openpty(&master, &slave, NULL, &tt, &win) < 0) {
    fprintf(stderr, _("openpty failed\n"));
    fail();
  }
#else
  char *pty, *bank, *cp;
  struct stat stb;

  pty = &line[strlen("/dev/ptyp")];
  for (bank = "pqrs"; *bank; bank++) {
    line[strlen("/dev/pty")] = *bank;
    *pty = '0';
    if (stat (line, &stb) < 0)
      break;
    for (cp = "0123456789abcdef"; *cp; cp++) {
      *pty = *cp;
      master = open(line, O_RDWR);
      if (master >= 0) {
	char *tp = &line[strlen("/dev/")];
	int ok;

	/* verify slave side is usable */
	*tp = 't';
	ok = access(line, R_OK | W_OK) == 0;
	*tp = 'p';
	if (ok) {
	  (void) tcgetattr(0, &tt);
	  (void) ioctl(0, TIOCGWINSZ, (char *) &win);
	  return;
	}
	(void) close(master);
      }
    }
  }
  fprintf(stderr, _("Out of pty's\n"));
  fail();
#endif				/* not HAVE_openpty */
#endif				/* !SVR4 */
}

char *ptsname(int fd);

void
getslave() {
#if defined(SVR4)
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
#ifndef _HPUX_SOURCE
    if (ioctl(slave, I_PUSH, "ttcompat") < 0) {
      perror("ioctl(fd, I_PUSH, ttcompat)");
      fail();
    }
#endif
    (void) ioctl(0, TIOCGWINSZ, (char *) &win);
  }
#else				/* !SVR4 */
#ifndef HAVE_openpty
  line[strlen("/dev/")] = 't';
  slave = open(line, O_RDWR);
  if (slave < 0) {
    perror(line);
    fail();
  }
  (void) tcsetattr(slave, TCSAFLUSH, &tt);
  (void) ioctl(slave, TIOCSWINSZ, (char *) &win);
#endif
  (void) setsid();
  (void) ioctl(slave, TIOCSCTTY, 0);
#endif				/* SVR4 */
}
