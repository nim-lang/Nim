DESTDIR?=pkg

all:
	sh build.sh

install:
	PATH="$(shell pwd)/bin:${PATH}" ./koch install "${DESTDIR}"
	install -d "${DESTDIR}/usr/share/nimrod/doc"
	install -d "${DESTDIR}/usr/lib/nimrod"
	install -d "${DESTDIR}/etc"
	install -d "${DESTDIR}/usr/bin"
	mv "${DESTDIR}/nimrod/lib/"* "${DESTDIR}/usr/lib/nimrod/"
	mv "${DESTDIR}/nimrod/config/"* "${DESTDIR}/etc/"
	cp -a "lib/packages" "${DESTDIR}/usr/lib/nimrod/"
	mv "${DESTDIR}/nimrod/doc/"* "${DESTDIR}/usr/share/nimrod/doc/"
	mv "${DESTDIR}/nimrod/bin/"* "${DESTDIR}/usr/bin/"
	rm -r "${DESTDIR}/nimrod"
	cp -r examples web "${DESTDIR}/usr/share/nimrod/doc/"
	install -m755 "compiler/c2nim/c2nim" "${DESTDIR}/usr/bin/"
	install -m755 "compiler/pas2nim/pas2nim" "${DESTDIR}/usr/bin/"
	install -m644 "lib/libnimrtl.so" "${DESTDIR}/usr/lib/libnimrtl.so"
	install -m755 "tools/nimgrep" "${DESTDIR}/usr/bin/"
	install -Dm644 "copying.txt" "${DESTDIR}/usr/share/licenses/nimrod/LICENSE"

clean:
	cp Makefile Makefile.backup
	./koch clean
	mv Makefile.backup Makefile
	rm -f koch
	rm -rf build
