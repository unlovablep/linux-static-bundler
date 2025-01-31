app: zig-out/bin/app
	cp zig-out/bin/app app
zig-out/bin/app: src/App.txz
	zig build

src/App.txz:
	@pushd AppDir && make && popd

clean: cleannodl 
	@pushd AppDir && make clean && popd
cleannodl:
	@# Clean without deleting any downloaded files
	rm src/App.txz
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
