all: date time

date: date.ex
	elixirc date.ex

time: time.ex
	elixirc time.ex

.PHONY: test
test: date time
	elixir -r 'test/test_helper.ex' -pr 'test/*_test.ex'
