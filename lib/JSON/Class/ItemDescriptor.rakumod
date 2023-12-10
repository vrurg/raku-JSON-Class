use v6.e.PREVIEW;
unit class JSON::Class::ItemDescriptor:ver($?DISTRIBUTION.meta<ver>):auth($?DISTRIBUTION.meta<auth>):api($?DISTRIBUTION.meta<api>);

use AttrX::Mooish;

use JSON::Class::Descriptor;
use JSON::Class::Types;
use JSON::Class::Utils;

also does JSON::Class::Descriptor;

has Mu $.type is required;
has Mu $.nominal-type is mooish(:lazy);

has Str:D $.name is mooish(:lazy, :clearer);
has Str:D $.kind is required;

method build-nominal-type is raw { nominalize-type($!type) }

method build-name { $.kind ~ " " ~ self.type.^name }

method value-type { $!type }

multi method INSTANTIATE-GENERIC(::?CLASS:D: TypeEnv:D $typeenv) {
    self.is-generic
        ?? self.clone(type => $typeenv.instantiate(self.type), :instantiated)
        !! self
}

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