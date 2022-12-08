CC ?= clang
CFLAGS= -std=c99 -W -Wall
CFLAGS+= -O3
CFLAGS+=-I/Users/gowa/.vcpkg/installed/x64-osx/lib/pkgconfig/../../include 
#CFLAGS+= -g -fno-omit-frame-pointer -fsanitize=address

NAME=    uaparser
MAJVER=  0
MINVER=  2
RELVER=  0
VERSION= $(MAJVER).$(MINVER).$(RELVER)

SLIB= lib$(NAME).a
DLIB= lib$(NAME).$(VERSION).so
LUA = uaparser.so

SRC= $(wildcard src/*.c)
INCLUDES= $(wildcard include/*.h)

CFLAGS+= -Iinclude -I.build
LDFLAGS+= -lyaml -lpcre
LDFLAGS+=-L/Users/gowa/.vcpkg/installed/x64-osx/lib/pkgconfig/../../lib

OBJS= $(patsubst src/%.c,.build/%.o,$(wildcard src/*.c))

.PHONY: all
all: shared-lib static-lib uaparser $(LUA)

.build:
	@mkdir .build

.build/%.o: src/%.c .build
	$(CC) $(CFLAGS) -c -o $@ $<

$(SLIB): $(OBJS)
	$(AR) -cvq $(SLIB) $(OBJS)

$(LUA): LDFLAGS += -shared -L/usr/local/lib -llua -lm 
$(LUA): CFLAGS += -fPIC -I/usr/local/include/lua 
$(LUA): OBJS += lua_uaparser.c
$(DLIB): CFLAGS += -fPIC
$(DLIB): LDFLAGS += -shared
$(DLIB): $(OBJS)
	$(CC) $(LDFLAGS) $^ -o $@


.PHONY: shared-lib
shared-lib: $(DLIB) $(SRC) $(INCLUDES)

.PHONY: static-lib
static-lib: $(SLIB) $(SRC) $(INCLUDES)

.build/regexes.yaml.h:
	xxd -i ../uap-core/regexes.yaml > .build/regexes.yaml.h

uaparser: $(OBJS) .build/regexes.yaml.h util/uaparser.o
	$(CC) $(CFLAGS) $(OBJS) util/uaparser.o $(LDFLAGS) -o uaparser

$(LUA): $(OBJS) .build/regexes.yaml.h
	$(CC) -o $@ $(CFLAGS) $(OBJS) $(LDFLAGS) 

.PHONY: test
test: $(SLIB) spec/tests.o
	$(CC) $(CFLAGS) spec/tests.o -L. -l$(NAME) $(LDFLAGS) -o test
	./test

.PHONY: clean
clean:
	rm -rf .build test *.a *.so spec/*.o src/*.o util/*.o uaparser uaparser.so
