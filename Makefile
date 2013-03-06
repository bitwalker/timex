all: date time

date: Elixir-Date.beam Elixir-TimeDelta.beam Elixir-TimeDelta-Struct.beam
Elixir-Date.beam, Elixir-TimeDelta.beam, Elixir-TimeDelta-Struct.beam: date.ex
	elixirc date.ex

time: Elixir-Time.beam Elixir-Time-Helpers.beam
Elixir-Time.beam, Elixir-Time-Helpers.beam: time.ex
	elixirc time.ex

.PHONY: test
test: date time
	elixir -r 'test/test_helper.ex' -pr 'test/*_test.ex'
