app: zig-out/bin/app
	cp zig-out/bin/app app
zig-out/bin/app: src/App.zip src/unzip
	zig build

src/App.zip:
	@pushd AppDir && make && popd

src/unzip: unzip60
	@# Make it static:
	sed -i 's/^CC = cc/CC = musl-gcc -static/' ./unzip60/unix/Makefile
	@pushd unzip60/ && make -f unix/Makefile unzips && popd
	cp unzip60/unzip src/unzip
unzip60: unzip60.tar.gz
	tar -xf unzip60.tar.gz
unzip60.tar.gz:
	wget https://downloads.sourceforge.net/infozip/unzip60.tar.gz

clean: cleannodl 
	rm unzip60.tar.gz
	@pushd AppDir && make clean && popd
cleannodl:
	@# Clean without deleting any downloaded files
	rm -r unzip60 src/unzip
	rm src/App.zip
	rm -r .zig-cache zig-out
	rm app

test: app
	LD_DEBUG=libs ./zig-out/bin/app
test-chroot: app
	mkdir test-chroot
	mkdir test-chroot/tmp
	cp zig-out/bin/app test-chroot
	sudo chroot ./test-chroot /app
	@#cleanup
	sudo rm -r ./test-chroot
