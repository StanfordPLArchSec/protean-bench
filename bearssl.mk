# TODO: Move to rules/?

BUILD = build

E =

O = .o

LP = lib

L = .a

DP = lib

D = .so

RM = rm -f

MKDIR = mkdir -p

CC = ${CC}
CFLAGS = -Wall ${CFLAGS} -fPIC -Os -fPIC
CCOUT = -c -o

AR = ar
ARFLAGS = -rcs
AROUT =

LD = $(CC)
LDFLAGS = -static ${LDFLAGS} -fuse-ld=lld -Wl,--allow-multiple-definition
LDOUT = -o

DLL = no
