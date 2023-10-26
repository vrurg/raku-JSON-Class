use v6.e.PREVIEW;
use JSON::Class:auth<zef:vrurg>;

#?example start
class Foo is json {
    has $.foo;
}

say "Foo is explicit: ", Foo.^json-is-explicit, "\n",
    " has 'foo' key : ", Foo.^json-has-key('foo');

class Bar is json {
    has $.bar1;
    has $.bar2 is json;
}

say "Bar is explicit: ", Bar.^json-is-explicit, "\n",
    " has 'bar1' key: ", Bar.^json-has-key('bar1'), "\n",
    " has 'bar2' key: ", Bar.^json-has-key('bar2');
#?example end