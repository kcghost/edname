.PHONY: all install check test

all:

install:
	install -Dm755 edname.bash /usr/local/bin/edname

check:
	shellcheck edname.bash

test:
	-rm -rf testdir
	mkdir -p "testdir/a/b/c"
	mkdir -p "testdir/Lorem Ip/Sum/AsDFg"
	mkdir -p "testdir/empty"
	touch "testdir/a/b/c/file_name"
	touch "testdir/this is a file"
	touch "testdir/this is another file"
	touch "testdir/Lorem Ip/Sum File Here"
	touch "testdir/Lorem Ip/Another"
	./edname.bash -r testdir
