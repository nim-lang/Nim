# Dummy makefile for people who don't read "readme" files, or for automated
# installations

.PHONY : all
all:
	python koch.py boot -d:release

.PHONY : install
install:
	sh build.sh

.PHONY : clean
clean:
	python koch.py clean
