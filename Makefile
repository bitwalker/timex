all: date time date_proto

date_proto: Elixir-DateRec.beam
Elixir-DateRec.beam: lib/date_proto.ex
	deps/elixir/bin/elixirc lib/date_proto.ex

date: Elixir-Date.beam
Elixir-Date.beam: lib/date.ex
	deps/elixir/bin/elixirc lib/date.ex

time: Elixir-Time.beam Elixir-Time-Helpers.beam
Elixir-Time.beam: lib/time.ex
	deps/elixir/bin/elixirc lib/time.ex

Elixir-Time-Helpers.beam: lib/time.ex
	deps/elixir/bin/elixirc lib/time.ex

.PHONY: clean test test-rebar docs

clean:
	rm -f *.beam

test: all
	deps/elixir/bin/elixir -r 'test/test_helper.exs' -pr 'test/*_test.exs'

test-rebar: app all
	deps/elixir/bin/elixir -r 'test/test_helper.exs' -pr 'test/*_test.exs'

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
