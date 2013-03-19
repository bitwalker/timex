all: date time date_proto

date_proto: Elixir-DateRec.beam
Elixir-DateRec.beam: date_proto.ex
	deps/elixir/bin/elixirc date_proto.ex

date: Elixir-Date.beam
Elixir-Date.beam: date.ex
	deps/elixir/bin/elixirc date.ex

time: Elixir-Time.beam Elixir-Time-Helpers.beam
Elixir-Time.beam: time.ex
	deps/elixir/bin/elixirc time.ex

Elixir-Time-Helpers.beam: time.ex
	deps/elixir/bin/elixirc time.ex

.PHONY: clean test test-rebar docs

clean:
	rm *.beam

test: all
	deps/elixir/bin/elixir -r 'test/test_helper.ex' -pr 'test/*_test.ex'

test-rebar: app all
	deps/elixir/bin/elixir -r 'test/test_helper.ex' -pr 'test/*_test.ex'

docs:
	mkdir -p ebin
	rm -rf docs
	cp *.beam ./ebin
	elixir ~/Documents/git/exdoc/bin/exdoc "DateTime" "0.1" -m Date -u "https://github.com/alco/elixir-datetime/blob/master/%{path}#L%{line}"
	rm -rf ebin

app: get-deps
	@./rebar compile

get-deps:
	@./rebar get-deps

dist-clean: clean
	@./rebar clean
	rm -f erl_crash.dump
