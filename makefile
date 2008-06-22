# Dummy makefile for people who don't read "readme" files, or automated
# installations
# (c) 2007  Andreas Rumpf

.PHONY : all
all:
	python koch.py all

.PHONY : install
install:
	python koch.py install

.PHONY : clean
clean:
	python koch.py clean
