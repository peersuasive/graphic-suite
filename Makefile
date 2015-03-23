CC = gcc

CFLAGS = `pkg-config --cflags libpng`
LIBS = `pkg-config --libs libpng`

all: dump.so

.c.o:
	@$(CC) -fPIC -c -o $@ $^

dump.o: dump.c dump.h
	@echo Compiling $@...
	@$(CC) -fPIC $(CFLAGS) -c -o $@ $<

dump.so: dump.o
	@echo Linking $@...
	@$(CC) -shared -o $@ $^ $(LIBS)

tests:
	lunit.sh -i luajit test/*

clean:
	@rm -f dump.o

extraclean: clean
	@rm -f dump.so
