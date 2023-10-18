use v6.e.PREVIEW;
unit role JSON::Class::Attr:ver($?DISTRIBUTION.meta<ver>):auth($?DISTRIBUTION.meta<auth>):api($?DISTRIBUTION.meta<api>);

use AttrX::Mooish:ver<1.0.5>;

use JSON::Class::Attr::Jsonish;
use JSON::Class::Descriptor;
use JSON::Class::Jsonish;
use JSON::Class::Types;
use JSON::Class::Utils;
use JSON::Class::X;

also does JSON::Class::Descriptor;
also does JSON::Class::Attr::Jsonish;

has Attribute:D $.attr handles <type name has_accessor is_built get_value package> is required;

has Bool $.skip is built(:bind);
has Bool $!skip-null is built(:bind);

# What name to use as JSON key
has Str:D $.json-name is mooish(:lazy);

has Bool $.lazy is mooish(:lazy);

has Mu $.value-type is mooish(:lazy, :no-init);
has Mu $.nominal-type is mooish(:lazy, :no-init);
# has Bool:D $.is-coercive is mooish(:lazy, :no-init);

method build-value-type {...}
method set-serializer {...}
method set-deserializer {...}

submethod TWEAK(:$serializer, :$deserializer) {
    with $serializer {
        self.set-serializer( | .List.Capture );
    }
    with $deserializer {
        self.set-deserializer( | .List.Capture );
    }
}

method build-json-name { $!attr.name.substr(2) }

method build-nominal-type is raw {
    my \vtype = self.value-type;
    vtype.^archetypes.nominalizable ?? vtype.^nominalize !! vtype
}

method build-lazy(::?CLASS:D:) {
    my \attr-type = nominalize-type($!attr.type);
    self.declarant.^json-is-lazy &&
        (attr-type ~~ JSON::Class::Jsonish || !(attr-type ~~ JSONBasicType | Map | List))
}

method sigil { $!attr.name.substr(0,1) }

method skip-null is raw {
    $!skip-null // self.declarant.^json-skip-null
}

method lazify(::?CLASS:D: Mu \obj) {
    JSON::Class::X::ReMooify.new(:$!attr, :type(obj)).throw if $.attr ~~ AttrX::Mooish::Attribute;
    my $*PACKAGE := obj;
    &trait_mod:<is>($!attr, :mooish(:lazy<json-build-attr>, :predicate('json-has-' ~ $.json-name)));
}

multi method kind-type('attribute') is pure { $!attr.type }

# Prevent AttrX::Mooish from installing its version of the 'clone' method with fixups because we know that all lazies
# here are purely immutable.
method clone { nextsame }