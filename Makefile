CC = gcc

CFLAGS = -fPIC -std=c99

all: dump.so sharpen.so transform.so

.c.o:
	@echo Compiling $@...
	@$(CC) $(CFLAGS) -c -o $@ $^

dump.o: dump.c dump.h
	@echo Compiling $@...
	@$(CC) $(CFLAGS) `pkg-config --cflags libpng` -c -o $@ $<

dump.so: dump.o
	@echo Linking $@...
	@$(CC) $(LDFLAGS) -shared -o $@ $^ `pkg-config --libs libpng`

sharpen.o: sharpen.c
	@echo Compiling $@...
	@$(CC) $(CFLAGS) `pkg-config --cflags imlib2` -c -o $@ $<

sharpen.so: sharpen.o
	@echo Linking $@...
	@$(CC) $(LDFLAGS) -shared -o $@ $< `pkg-config --libs imlib2` 

transform.o: transform.c transform.h
	@echo Compiling $@...
	@$(CC) $(CFLAGS) `pkg-config --cflags imlib2` -c -o $@ $<

transform.so: transform.o
	@echo Linking $@...
	@$(CC) $(LDFLAGS) -shared -o $@ $< `pkg-config --libs imlib2` 

tests:
	lunit.sh -i luajit test/*

clean:
	@rm -f dump.o sharpen.o transform.o

extraclean: clean
	@rm -f dump.so sharpen.so transform.so
