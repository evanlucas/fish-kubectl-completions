build:
	go build
	./kcfishgen > completions/kubectl.fish
