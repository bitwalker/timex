all: date time

date: Elixir-Date.beam
Elixir-Date.beam: date.ex
	elixirc date.ex

time: Elixir-Time.beam Elixir-Time-Helpers.beam
Elixir-Time.beam: time.ex
	elixirc time.ex

Elixir-Time-Helpers.beam: time.ex
	elixirc time.ex

.PHONY: test
test: date time
	elixir -r 'test/test_helper.ex' -pr 'test/*_test.ex'
