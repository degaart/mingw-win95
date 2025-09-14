.PHONY: all clean
.SUFFIXES:

CC       := i586-w64-mingw32-gcc
CXX      := i586-w64-mingw32-g++
STRIP    := i586-w64-mingw32-strip
CFLAGS   := -Os -DWINVER=0x0400 -D_WIN32_IE=0x0400 -D_WIN32_WINDOWS=0x0400 -D_WIN32_WINNT=0x0400 -DWIN32_LEAN_AND_MEAN
CXXFLAGS := -Os -DWINVER=0x0400 -D_WIN32_IE=0x0400 -D_WIN32_WINDOWS=0x0400 -D_WIN32_WINNT=0x0400 -DWIN32_LEAN_AND_MEAN
LDFLAGS  :=

all: \
	console.exe \
	win32.exe \
	cppconsole.exe \
	threads.exe \
	exceptions.exe \
	chrono.exe

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
	$(CXX) -o $@ -pthread $<
	$(STRIP) -s $@

exceptions.exe: exceptions.cpp
	$(CXX) -o $@ $<
	$(STRIP) -s $@

chrono.exe: chrono.cpp
	$(CXX) -o $@ $<
	$(STRIP) -s $@

clean:
	rm -rf *.exe

