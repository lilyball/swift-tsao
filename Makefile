.PHONY: test

SWIFT=xcrun swift -sdk $$(xcrun -show-sdk-path -sdk macosx)

.INTERMEDIATE: exec-test

test: exec-test
	./exec-test

exec-test: test.swift tsao.swift
	$(SWIFT) -o exec-test tsao.swift test.swift
