.PHONY: all clean
.SUFFIXES:

CC       := i586-w64-mingw32-gcc
CXX      := i586-w64-mingw32-g++
STRIP    := i586-w64-mingw32-strip
CFLAGS   := 
CXXFLAGS := 
LDFLAGS  :=

all: cconsole.exe cwin32.exe cppconsole.exe

cconsole.exe: cconsole.c
	$(CC) -o $@ $<
	$(STRIP) -s $@

cwin32.exe: cwin32.c
	$(CC) -o $@ $<
	$(STRIP) -s $@

cppconsole.exe: cppconsole.cpp
	$(CXX) -o $@ $<
	$(STRIP) -s $@

clean:
	rm -rf *.exe

