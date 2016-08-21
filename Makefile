all:
	g++ genmask.cpp -o genmask
	./genmask
	fasm emails.asm