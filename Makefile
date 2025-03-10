.PHONY: test coverage lint run

test:
	bundle exec rspec

coverage:
	bundle exec rspec
	open coverage/index.html

lint:
	bundle exec rubocop -A

run:
	./main.rb
