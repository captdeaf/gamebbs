// Chrootit.c

#include <stdlib.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <stdio.h>

extern char **environ;

int main(int argc,char *argv[]) {
  int fd;
  char *args[] = {  NULL };

  /* Become root */
  setuid(0);
  setgid(0);

  if (chdir("/home/nethack")) {
    perror("chdir");
  }
  if (chroot("/home/nethack")) {
    perror("chroot");
    return 1;
  }
  if (chdir("/")) {
    perror("chdir");
  }
  umask(0022);
  setgid(GAMEBBS_GROUP);
  setuid(GAMEBBS_USER);
  printf("Welcome to GameBBS!\n");
  execve("/gamebbs/launch.rb",args,environ);
  printf("... Terribly sorry, but I cannot start the GameBBS environment.\n");
  printf("Goodbye!\n");
  return 1;
}
