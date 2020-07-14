from setuptools import setup
from setuptools.extension import Extension
from Cython.Build import cythonize

setup(
    name='fatfs',
    ext_modules=cythonize([
        Extension("fatfs", ["src/fatfs.pyx", "src/diskiocheck.c", "fatfs/source/ff.c", "fatfs/source/ffsystem.c", "fatfs/source/ffunicode.c"], include_dirs=["fatfs/source"]),
    ]),
    zip_safe=False,
)
