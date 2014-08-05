.PHONY: test

SWIFTC=xcrun swiftc -sdk $$(xcrun -show-sdk-path -sdk macosx)

.INTERMEDIATE: exec-test

test: exec-test
	./exec-test

exec-test: test.swift tsao.swift
	$(SWIFTC) -o exec-test tsao.swift test.swift
