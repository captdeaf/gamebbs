# For gamebbs_launch
GAMEBBS_GROUP = 1004
GAMEBBS_USER  = 1004

CFLAGS = -DSVR4 -DHAVE_openpty -m64 -g
LDFLAGS = -lncurses -lutil -m64 -g

RECLIBS=\
	io.o \
	gttyrec.o \
	$(NULL)

SPLAYLIBS=\
	io.o \
	sttyplay.o \
	stripgfx.o \
	$(NULL)

PLAYLIBS=\
	io.o \
	gttyplay.o \
	stripgfx.o \
	$(NULL)

all: gttyrec gttyplay sttyplay gamebbs_launch

gttyrec: $(RECLIBS)
	gcc $(RECLIBS) -o gttyrec $(LDFLAGS)

gttyplay: $(PLAYLIBS)
	gcc $(PLAYLIBS) -o gttyplay $(LDFLAGS)

sttyplay: $(SPLAYLIBS)
	gcc $(SPLAYLIBS) -o sttyplay $(LDFLAGS)

launchit_ruby.o:
	gcc -c launchit_ruby.c -DGAMEBBS_GROUP=$(GAMEBBS_GROUP) -DGAMEBBS_USER=$(GAMEBBS_USER)

gamebbs_launch: launchit_ruby.o
	gcc launchit_ruby.o -o gamebbs_launch 
	@echo "Don't forget to chown gamebbs_launch to root"
	@echo "and chmod it u+s, so it can drop uid privs and"
	@echo "chusr/group to nethack."

clean:
	rm *.o gttyrec gttyplay
