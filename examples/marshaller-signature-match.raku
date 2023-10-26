use v6.e.PREVIEW;
use JSON::Class:auth<zef:vrurg>;

#?example start
class Foo is json {
    has Real:D $.foo is json(:serializer(-> Int:D \v { say "serializing ", v.WHICH; v.Rat })) is required;
}

say Foo.new(foo => 12).to-json;
say Foo.new(foo => 1.2).to-json;