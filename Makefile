build-wildbits:
	mkdir -p builds/
	cd Wild-Bits/src-tauri && cargo build
	cp Wild-Bits/src-tauri/target/debug/wildbits.exe builds/wildbits-tools.exe

clean-wildbits:
	cd Wild-Bits/src-tauri && cargo clean

build: build-wildbits

clean: clean-wildbits
	rm -rf builds/
	rm -rf tmp/
