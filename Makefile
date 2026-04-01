.PHONY: fmt
fmt:
	stylua -g '*.lua' -- .
	dprint fmt

.PHONY: lint
lint:
	typos

.PHONY: check
check: lint fmt
