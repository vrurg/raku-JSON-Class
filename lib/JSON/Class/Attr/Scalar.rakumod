use v6.e.PREVIEW;
unit class JSON::Class::Attr::Scalar:ver($?DISTRIBUTION.meta<ver>):auth($?DISTRIBUTION.meta<auth>):api($?DISTRIBUTION.meta<api>);

use JSON::Class::Attr;
use JSON::Class::Internals;
use JSON::Class::Types;

also does JSON::Class::Attr;

method build-value-type { $!attr.type }

method set-serializer($serializer?, *%extra) {
    verify-named-args(:%extra, :what(":serializer argument of trait 'json'"), :source($!declarant.^name));
    self.register-helper(JSSerialize, 'attribute', $_) with $serializer;
}

method set-deserializer($deserializer?, *%extra) {
    verify-named-args(:%extra, :what(":deserializer argument of trait 'json'"), :source($!declarant.^name));
    self.register-helper(JSDeserialize, 'attribute', $_) with $deserializer;
}