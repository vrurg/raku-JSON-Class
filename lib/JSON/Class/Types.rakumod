use v6.e.PREVIEW;
unit module JSON::Class::Types:ver($?DISTRIBUTION.meta<ver>):auth($?DISTRIBUTION.meta<auth>):api($?DISTRIBUTION.meta<api>);

class NOT-SET is Nil is export(:NOT-SET) {
    method Bool { False }
}

role CloneFrom {
    method clone-from(Mu:D $obj, *%twiddles) {
        my %profile;
        for $obj.^attributes(:!local).grep({ .has_accessor || .is_built }) -> Attribute:D $attr {
            %profile{$attr.name.substr(2)} := $attr.get_value($obj);
        }
        self.new: |%profile, |%twiddles
    }
}

subset JSONBasicType is export of Mu where {
    ((my \type = $^type<>) ~~ Numeric | Stringy | Bool | Enumeration) || type =:= Mu || type =:= Any
};

subset JSONScalarType is export of Cool where Numeric | Stringy | Bool;

subset JSONHelper is export of Any where Str:D | Code:D | Any:U;
subset JSONBuildHelper is export of Any where Str:D | Code:D | Bool:D | Any:U;

enum JSONStages is export (JSSerialize => 'to-json', JSDeserialize => 'from-json', JSMatch => 'match');

my class AttrMeta {
    has Bool $.mixin-skip;
    multi method COERCE(%profile) { self.new: |%profile }
    multi method COERCE(Any:D \profile) { self.new: |profile.Hash }
}

role JSONAttr {
    has AttrMeta:D() $.json-meta is required;
}

multi sub trait_mod:<is>(Attribute:D \attr, Any:D :$json-meta!) is export {
    attr does JSONAttr( $json-meta )
}