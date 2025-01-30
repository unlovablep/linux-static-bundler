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

clean: cleannodl cleanappdir
	rm unzip60.tar.gz
cleannodl: cleanappdirnodl
	@# Clean without deleting any downloaded files
	rm -r unzip60 src/unzip
	rm src/App.zip
	rm -r .zig-cache zig-out
	rm app
cleanappdir: cleanappdirnodl
	rm AppDir/sh
cleanappdirnodl:
	rm AppDir/usr/bin/main
	rm AppDir/usr/lib/libc.so.6 AppDir/usr/lib64/ld-linux-x86-64.so.2
	rm -r AppDir/usr

test: zig-out/bin/app
	LD_DEBUG=libs ./zig-out/bin/app
test-chroot: zig-out/bin/app
	mkdir test-chroot
	mkdir test-chroot/tmp
	cp zig-out/bin/app test-chroot
	sudo chroot ./test-chroot /app
	@#cleanup
	sudo rm -r ./test-chroot
