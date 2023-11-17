use v6.e.PREVIEW;
unit class JSON::Class::Attr::Positional:ver($?DISTRIBUTION.meta<ver>):auth($?DISTRIBUTION.meta<auth>):api($?DISTRIBUTION.meta<api>);

use JSON::Class::Attr;
use JSON::Class::Attr::Collection;
use JSON::Class::Internals;
use JSON::Class::Types;

also does JSON::Class::Attr;
also does JSON::Class::Attr::Collection;

method build-value-type { $!attr.type.of }

method set-serializer($serializer?, :$value, *%extra) {
    verify-named-args(:%extra, :what(":serializer argument of trait 'json'"), :source($!declarant.^name));
    self.register-helper(JSSerialize, 'attribute', $_) with $serializer;
    self.register-helper(JSSerialize, 'value', $value);
}

method set-deserializer($deserializer?, :$value, *%extra) {
    verify-named-args(:%extra, :what(":deserializer argument of trait 'json'"), :source($!declarant.^name));
    self.register-helper(JSDeserialize, 'attribute', $_) with $deserializer;
    self.register-helper(JSDeserialize, 'value', $value);
}

multi method kind-type('value') is pure { self.value-type }