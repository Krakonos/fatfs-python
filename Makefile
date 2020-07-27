all:
	CYTHONIZE=1 python setup.py build_ext --inplace

clean:
	rm fatfs.cpython-38-x86_64-linux-gnu.so

test:	all
	tox
