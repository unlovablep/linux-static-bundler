LIBS=usr/lib/libc.so.6 usr/lib64/ld-linux-x86-64.so.2

../App.zip: sh all_libs usr/bin/main
	chmod +x AppRun
	zip -9 -r ../src/App.zip ./
all_libs: $(LIBS)
	mkdir -p usr/lib usr/lib64
$(LIBS):
	cp "/$@" "$@"
usr/bin/main:
	mkdir -p usr/bin
	gcc -o usr/bin/main src/main.c
sh:
	wget https://busybox.net/downloads/binaries/1.35.0-x86_64-linux-musl/busybox_ASH
	mv busybox_ASH sh
	chmod +x sh

clean: 
	rm sh
	rm usr/bin/main
	rm $(LIBS)
	rm -r usr
