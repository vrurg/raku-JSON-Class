use v6.e.PREVIEW;
unit role JSON::Class::Descriptor:ver($?DISTRIBUTION.meta<ver>):auth($?DISTRIBUTION.meta<auth>):api($?DISTRIBUTION.meta<api>);

use AttrX::Mooish;

use JSON::Class::Types;
use JSON::Class::Utils;

method name {...}
method type {...}
method value-type {...}
method nominal-type {...}
method set-serializer {...}
method set-deserializer {...}

# Where this object was originally declared.
has Mu $!declarant is built(:bind) is required;

has %!helpers;
has Lock:D $!helpers-lock .= new;

has Bool:D $.is-a-class is mooish(:lazy);

method build-is-a-class { is-a-class-type(self.type) }

method register-helper(::?CLASS:D: Str:D $stage, Str:D $kind, JSONHelper:D $helper --> Nil) {
    $!helpers-lock.protect: {
        (%!helpers{$stage} // (%!helpers{$stage} := my %)).{$kind} := $helper<>
    }
}

method helper(::?CLASS:D: Str:D $stage, Str:D $kind) {
    $!helpers-lock.protect: { %!helpers{$stage} andthen .{$kind} orelse Nil }
}

method has-helper(::?CLASS:D: Str:D $stage, Str:D $kind) {
    $!helpers-lock.protect: {
        %!helpers.EXISTS-KEY($stage) && %!helpers{$stage}.EXISTS-KEY($kind)
    }
}

# Shortcuts for .helper('stage', $kind)
method serializer(::?CLASS:D: Str:D $kind) {
    $!helpers-lock.protect: { %!helpers{JSSerialize} andthen .{$kind} orelse Nil }
}
method deserializer(::?CLASS:D: Str:D $kind) {
    $!helpers-lock.protect: { %!helpers{JSDeserialize} andthen .{$kind} orelse Nil }
}

method declarant(::?CLASS:D: --> Mu) is raw { $!declarant }
method is-declarant-lazy(::?CLASS:D:) { $!declarant.HOW.json-is-lazy($!declarant) }

# Give descriptor type for a requested kind of de-/serializer, as specified by set-serializer/set-deserializer methods.
# I.e. for 'attribute' it would give back $!attr.type.
proto method kind-type(Str:D) {*}

multi method kind-type(Str:D $kind) {
    die "Don't know de-/serializer kind '$kind'"
}

# Similar to kind-type by maps a pair of $stage and $kind into config helper stages. For example, JSDeserialize and
# 'match' would map info JSMatch by ItemDescriptor, but so far all JSSerialize map into itself, no matter what kind is
# requested.
method kind-stage(Str:D $stage, Str:D) is pure { $stage }