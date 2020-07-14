all:
	python Setup.py build_ext --inplace

clean:
	rm diskio.cpython-38-x86_64-linux-gnu.so

test:	all
	python run_check.py
