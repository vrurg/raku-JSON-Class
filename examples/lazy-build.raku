use v6.e.PREVIEW;
use JSON::Class:auth<zef:vrurg>;
use JSON::Class::Attr:auth<zef:vrurg>;

#?example start
class LazyRec is json(:lazy) {
    has $.attr1 is json(:build);
    has $.attr2 is json(:build<build-attr1>);
    has @.attr3 is json(:build(-> $ { "π", pi, "the answer", 42 }));
    has %.attr4 is json(:build<new-map>);

    method build-attr1(JSON::Class::Attr:D $descr) {
        say "Builder for attr1 for ", $descr.json-name;
        "for " ~ $descr.name
    }
    method new-map($) { :key<value>, :!flag }
}

my $lr = LazyRec.new;
say "- attr1: ", $lr.attr1;
say "- attr2: ", $lr.attr2;
say "- attr3: ", $lr.attr3;
say "- attr4: ", $lr.attr4;