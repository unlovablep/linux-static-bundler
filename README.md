# linux-static-bundler
A fully static bundler for linux programs. It's like AppImage, but far worse!

---

Bundles a zip file into a statically linked executable, which when run will get unzipped into a temporary directory in /tmp, and the script `AppRun` will be executed.

Tested on Arch Linux, makefile may need tweaking for building on other systems with different library directories.

The default makefile will build `AppDir` into our zip file. `AppRun` will be run with `./sh`, which is busybox's `ash`, as provided by our makefile. The makefile will also copy your `/usr/lib64/ld-linux-x86-64.so.2` and `/usr/lib/libc.so.6`, and will run `/usr/bin/main` which is a simple hello world program, which itself is dynamically linked. It gets run with the copied ld-linux and libc, meaning it is fully self contained.

The makefile contains the step `test-chroot` which will test the program in a chroot which contains next to nothing at all.
