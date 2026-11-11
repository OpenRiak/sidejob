.PHONY: compile rel cover test dialyzer

# since we are (principally) a dependency app of riak, we usually are
# built by the top-level rebar3, of a specific version, so let's find
# it in the usual location.
REBAR ?= ../riak/rebar3

compile:
	$(REBAR) compile

clean:
	$(REBAR) clean

cover: test
	$(REBAR) cover

test: compile
	$(REBAR) as test do eunit

dialyzer:
	$(REBAR) dialyzer

xref:
	$(REBAR) xref

check: test dialyzer xref
