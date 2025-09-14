.PHONY: all clean
.SUFFIXES:

CC       := i586-w64-mingw32-gcc
CXX      := i586-w64-mingw32-g++
STRIP    := i586-w64-mingw32-strip
CFLAGS   := 
CXXFLAGS := 
LDFLAGS  :=

all: console.exe win32.exe cppconsole.exe threads.exe exceptions.exe

console.exe: console.c
	$(CC) -o $@ $<
	$(STRIP) -s $@

win32.exe: win32.c
	$(CC) -o $@ $<
	$(STRIP) -s $@

cppconsole.exe: cppconsole.cpp
	$(CXX) -o $@ $<
	$(STRIP) -s $@

threads.exe: threads.cpp
	$(CXX) -o $@ $<
	$(STRIP) -s $@

exceptions.exe: exceptions.cpp
	$(CXX) -o $@ $<
	$(STRIP) -s $@

clean:
	rm -rf *.exe

