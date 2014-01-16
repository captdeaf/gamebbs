#ifndef __TTYREC_IO_H__
#define __TTYREC_IO_H__

typedef struct header
{
  struct timeval tv;
  size_t len;
} Header;

int read_header (FILE * fp, Header * h);
int write_header (FILE * fp, Header * h);
FILE *efopen (const char *path, const char *mode);

#endif
