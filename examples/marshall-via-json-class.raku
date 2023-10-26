use v6.e.PREVIEW;
use JSON::Class:auth<zef:vrurg>;

#?example start
class Foo is json(:skip-null) {
    has Real $.n
        is json(
            :serializer({ $*JSON-CLASS-SELF.n2s($_) }),
            :deserializer({ $*JSON-CLASS-SELF.s2n($_) }) );

    multi method new(Real $n) { self.bless: :$n }

    proto method n2s(|) {*}
    multi method n2s(Real:U \t) { t.^name }
    multi method n2s(Real:D \n) { n.^name ~ ":" ~ n }

    method s2n(Str:D $from) {
        if $from.contains(":") {
            my ($type, $val) = $from.split(":");
            return $val."$type"()
        }
        ::($from)
    }
}

say "Serializing π  : ", Foo.new(pi).to-json;
say "Serializing Num: ", Foo.new(Num).to-json;
say "";
say "Deserializing a Rat: ", Foo.from-json(q<{"n":"Rat:-12.42"}>).n.WHICH;
say "Deserializing a type: ", Foo.from-json(q<{"n":"Int"}>).n.WHICH;