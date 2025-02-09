# linux-static-bundler
A fully static bundler for linux programs. It's like AppImage, but far worse!

---

Bundles a tar.xz file into a statically linked executable, which when run will get extracted into a temporary directory in /tmp, and the script `AppRun` will be executed.

Modify `AppDir/Makefile` to suit your needs, all files to be built into the final archive should be contained in `AppDir` and your entrypoint program should be run by `AppRun`. The example `AppRun` shows how to run a dynamic executable using the shared libraries bundled inside your `AppDir`.

The temporary directory is exposed to `AppRun` as the environment variable `$APPDIR`.

The user's current directory from `pwd` is exposed as `$TOPDIR`.

Command line arguments argv[1..] are exposed as `$ARGS` (space-separated), while argv[0] is exposed as `$SELF`.

I wouldn't trust my own code with root permissions, so you shouldn't either.
