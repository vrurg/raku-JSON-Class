use v6.e.PREVIEW;
use JSON::Class:auth<zef:vrurg>;

#?example start
class Foo is json {
    has %.idx is json(
        :to-json(
            -> %v { say "Attribute-level serializes: ", %v; json-I-cant },
            key => { say "Key-level serializes  : ", $^key; "Foo." ~ $key },
            value => "raku",
            # value => { say "Value-level serializes: ", $^value.raku; $value.raku }
        ),
        :from-json(
            -> %from { say "Attribute-level deserializes: ", %from; json-I-cant },
            key => { say "Key-level deserializes  : '", $^from-key, "'"; $from-key.substr(1) },
            value => { say "Value-level deserializes: '", $^from-value, "'"; $from-value.EVAL }
        )
    );
}

my $foo =
    Foo.new:
        idx => %(
            "k1" => Date.new("2023-10-23"),
            "k2" => pi,
            "k3" => v3.4,
        );

say "### Serializing ###";
my $json = $foo.to-json(:sorted-keys);
say $json;

say "\n### Deserializing ###";
say Foo.from-json($json);