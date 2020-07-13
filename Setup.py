from distutils.core import setup
from distutils.extension import Extension
from Cython.Build import cythonize

setup(
  name = 'diskio',
  ext_modules=cythonize([
    Extension("diskio", ["src/diskio_wrapper.pyx", "src/diskiocheck.c", "fatfs/source/ffsystem.c", "fatfs/source/ffunicode.c"], include_dirs=["fatfs/source"]),
    ]),
)
