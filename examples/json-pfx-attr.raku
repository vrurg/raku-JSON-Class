use v6.e.PREVIEW;
use JSON::Class:auth<zef:vrurg>;

#?example start
class Foo is json(:implicit) {
    has Int $.foo;
    has Str $.json-invisible;
}

my $foo = Foo.new(:foo(42), :json-invisible("The Answer"));
say "JSON      : ", $foo.to-json;
say "Attribute : ", $foo.json-invisible;