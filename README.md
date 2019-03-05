# kubectl completion for fish shell

## Install

```fish
$ mkdir -p ~/.config/fish/completions
$ cd ~/.config/fish
$ git clone https://github.com/evanlucas/fish-kubectl-completions
$ ln -s ../fish-kubectl-completions/completions/kubectl.fish completions/
```

### Install using [Fisher](https://github.com/jorgebucaran/fisher)

`fisher add evanlucas/fish-kubectl-completions`

## Building

This was tested using go 1.11.1 on macOS.

```console
$ make build
```

## Environment Variables

### `FISH_KUBECTL_COMPLETION_TIMEOUT`

This is used to pass the `--request-timeout` flag to the `kubectl` command.
It defaults to `5s`.

> Non-zero values should contain a corresponding time unit (e.g. 1s, 2m, 3h).
> A value of zero means don't timeout requests.

### `FISH_KUBECTL_COMPLETION_COMPLETE_CRDS`

This can be used to prevent completing CRDs. Some users may have limited access
to resources.
It defaults to `1`. To disable, set to anything other than `1`.

## Author

Evan Lucas

## License

MIT
