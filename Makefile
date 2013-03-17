all: date time

date: Elixir-Date.beam
Elixir-Date.beam: date.ex
	elixirc date.ex

time: Elixir-Time.beam Elixir-Time-Helpers.beam
Elixir-Time.beam: time.ex
	elixirc time.ex

Elixir-Time-Helpers.beam: time.ex
	elixirc time.ex

.PHONY: test docs
test: all
	elixir -r 'test/test_helper.ex' -pr 'test/*_test.ex'

docs:
	mkdir -p ebin
	rm -rf docs
	cp *.beam ./ebin
	elixir ~/Documents/git/exdoc/bin/exdoc "DateTime" "0.1" -m Date -u "https://github.com/alco/elixir-datetime/blob/master/%{path}#L%{line}"
	rm -rf ebin
