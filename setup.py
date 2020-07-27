#!/usr/bin/python3 

import os
from setuptools import setup, find_packages, Extension
try:
    from Cython.Build import cythonize
except ImportError:
    cythonize = None


# https://cython.readthedocs.io/en/latest/src/userguide/source_files_and_compilation.html#distributing-cython-modules
def no_cythonize(extensions, **_ignore):
    for extension in extensions:
        sources = []
        for sfile in extension.sources:
            path, ext = os.path.splitext(sfile)
            if ext in (".pyx", ".py"):
                if extension.language == "c++":
                    ext = ".cpp"
                else:
                    ext = ".c"
                sfile = path + ext
            sources.append(sfile)
        extension.sources[:] = sources
    return extensions


extensions = [
    Extension("fatfs", ["src/fatfs.pyx", "src/diskiocheck.c", "fatfs/source/ff.c", "fatfs/source/ffsystem.c", "fatfs/source/ffunicode.c"], include_dirs=["fatfs/source"]),
]

CYTHONIZE = bool(int(os.getenv("CYTHONIZE", 0))) and cythonize is not None

if CYTHONIZE:
    compiler_directives = {"language_level": 3, "embedsignature": True}
    extensions = cythonize(extensions, compiler_directives=compiler_directives)
else:
    extensions = no_cythonize(extensions)

setup(
    version="0.0.1",
    name='fatfs',
    ext_modules=extensions,
    packages=['pyfatfs', 'pyfatfs.tests'],
    install_requires=['cython'],
    zip_safe=False,
)
    #package_data=["fatfs/source/ff.h"],
