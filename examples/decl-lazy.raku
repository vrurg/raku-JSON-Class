use v6.e.PREVIEW;
use JSON::Class:auth<zef:vrurg>;

#?example start
class Item {
    has $.something;
}

class Foo is json {
    has Str $.foo;   # Basic types are eager by default
    has Item $.item; # Non-basic types is lazy by default
}

say "--- Foo";
say "    .foo lazy      : ", Foo.^json-get-key("foo").lazy;
say "    .item lazy     : ", Foo.^json-get-key("item").lazy;

class Bar is json(:lazy, :implicit) {
    has Str $.bar;
    has Item $.item;
    has Item $.item2 is json(:!lazy);
}

say "--- Bar";
say "    .bar is lazy   : ", Bar.^json-get-key('bar').lazy;
say "    .item is lazy  : ", Bar.^json-get-key('item').lazy;
say "    .item2 is lazy : ", Bar.^json-get-key('item2').lazy;

class Baz is json(:!lazy, :implicit) {
    has Str $.baz;
    has Item $.item;
    has Item $.item2 is json(:lazy);
}

say "--- Baz";
say "    .baz lazy      : ", Baz.^json-get-key("baz").lazy;
say "    .item lazy     : ", Baz.^json-get-key("item").lazy;
say "    .item2 lazy    : ", Baz.^json-get-key("item2").lazy;
#?example end