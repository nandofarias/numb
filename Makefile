build:
	luarocks build
test: build
	busted tests
