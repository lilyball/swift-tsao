.PHONY: test clean
.DEFAULT_GOAL := test

SWIFTC=xcrun swiftc -sdk $$(xcrun -show-sdk-path -sdk macosx)
SOURCE_FILES := tsao.swift

target:
	mkdir target

target/libTSAO.dylib: $(SOURCE_FILES) | target
	$(SWIFTC) -emit-library -emit-module -module-name TSAO -module-link-name TSAO -O -o target/libTSAO.dylib $(SOURCE_FILES)

target/test: target/libTSAO.dylib
	$(SWIFTC) -I target/ -L target/ -o target/test test.swift

.INTERMEDIATE: target/test

test: target/test
	./target/test

clean:
	rm -rf target/
