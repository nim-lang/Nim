# setup.py - Builds and installs the TRE Python language bindings module
#
# Copyright (c) 2004-2006 Nikolai SAOUKH <nms+python@otdel-1.org>
#
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA

from distutils.core import setup, Extension
import sys
from glob import glob
from os.path import normpath
import re

def ospath(fl):
    return [normpath(f) for f in fl]

VERSION = "0.7.5"

SOURCES = ["tre-python.c"]

INCDIRS = ospath(["..", "../lib"])

setup(
    name = "tre",
    version = VERSION,
    description = "Python module for TRE",
    author = "Nikolai SAOUKH",
    author_email = "nms+python@otdel-1.org",
    license = "LGPL",
    url = "http://laurikari.net/tre/",
    ext_modules = [
        Extension(
            "tre",
	    SOURCES,
	    include_dirs = INCDIRS,
            define_macros = [("HAVE_CONFIG_H", None)],
	    libraries=["tre"]
	),
    ],
)
