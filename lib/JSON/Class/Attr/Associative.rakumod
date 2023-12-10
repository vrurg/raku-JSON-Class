use v6.e.PREVIEW;
unit class JSON::Class::Attr::Associative:ver($?DISTRIBUTION.meta<ver>):auth($?DISTRIBUTION.meta<auth>):api($?DISTRIBUTION.meta<api>);

use AttrX::Mooish;

use JSON::Class::Attr;
use JSON::Class::Attr::Collection;
use JSON::Class::Internals;
use JSON::Class::Types;
use JSON::Class::Utils;

also does JSON::Class::Attr;
also does JSON::Class::Attr::Collection;

has Mu $.key-type is mooish(:lazy, :predicate);
has Mu $.nominal-keytype is mooish(:lazy);

method build-value-type(--> Mu) is raw { $!attr.type.of }

method build-key-type(--> Mu) is raw { $!attr.type.keyof }

method build-nominal-keytype is raw { nominalize-type($!attr.type.keyof) }

method set-serializer($serializer?, :$value, :$key, *%extra) {
    verify-named-args(:%extra, :what(":serializer argument of trait 'json'"), :source($!declarant.^name));
    self.register-helper(JSSerialize, 'attribute', $_) with $serializer;
    self.register-helper(JSSerialize, 'value', $_) with $value;
    self.register-helper(JSSerialize, 'key', $_) with $key;
}

method set-deserializer($deserializer?, :$value, :$key, *%extra) {
    verify-named-args(:%extra, :what(":deserializer argument of trait 'json'"), :source($!declarant.^name));
    self.register-helper(JSDeserialize, 'attribute', $_) with $deserializer;
    self.register-helper(JSDeserialize, 'value', $_) with $value;
    self.register-helper(JSDeserialize, 'key', $_) with $key;
}

multi method kind-type('value') is pure { self.value-type }
multi method kind-type('key')   is pure { self.key-type   }

# Preserve critical attributes.
method clone(*%twiddles) is raw {
    %twiddles<key-type> := $!key-type if self.has-lazy && !(%twiddles<key-type>:exists);
    ::?CLASS.^post-clone: self, callwith(|%twiddles), %twiddles
}