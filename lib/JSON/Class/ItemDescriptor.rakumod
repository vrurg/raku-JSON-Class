use v6.e.PREVIEW;
unit class JSON::Class::ItemDescriptor:ver($?DISTRIBUTION.meta<ver>):auth($?DISTRIBUTION.meta<auth>):api($?DISTRIBUTION.meta<api>);

use AttrX::Mooish;

use JSON::Class::Descriptor;
use JSON::Class::Types;
use JSON::Class::Utils;

also does JSON::Class::Descriptor;

has Mu $.type is built(:bind) is required;
has Mu $.nominal-type is mooish(:lazy);

has Str $.name;

method build-nominal-type is raw { nominalize-type($!type) }

method value-type { $!type }

method set-serializer($serializer?) {
    self.register-helper(JSSerialize, 'item', $_) with $serializer;
}

method set-deserializer($deserializer?) {
    self.register-helper(JSDeserialize, 'item', $_) with $deserializer;
}

method has-matcher { self.has-helper(JSDeserialize, 'match') }

method set-matcher($matcher?) {
    self.register-helper(JSDeserialize, 'match', $_) with $matcher;
}

method matcher(::?CLASS:D:) { self.helper(JSDeserialize, 'match') }

multi method kind-type('match') { $!type }
multi method kind-type('item') { $!type }

proto method kind-stage(Str:D, Str:D) {*}
multi method kind-stage(JSDeserialize, 'match') is pure { JSMatch }
multi method kind-stage(Str:D $stage, Str:D) is pure { $stage }