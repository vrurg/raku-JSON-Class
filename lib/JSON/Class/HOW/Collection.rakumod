use v6.e.PREVIEW;
unit role JSON::Class::HOW::Collection:ver($?DISTRIBUTION.meta<ver>):auth($?DISTRIBUTION.meta<auth>):api($?DISTRIBUTION.meta<api>);

use experimental :will-complain;

use JSON::Class::HOW::Jsonish;
use JSON::Class::ItemDescriptor;
use JSON::Class::Types :NOT-SET;
use JSON::Class::Utils;

also does JSON::Class::HOW::Jsonish;

has $!json-item-descriptors;
# What would serve as default value for array elements when Nil is assigned.
has Mu $!json-item-default;

has $!json-item-declarations;
has $!json-trait-name;

method json-build-collection-type(Mu,@) {...}

method json-set-item-default(Mu \obj, Mu \item-default, Bool :$force) {
    $!json-item-default := item-default if $force || $!json-item-default =:= NOT-SET;
}

method json-set-item-declarations(Mu, +@declarations, Str:D :$trait = $*JSON-CLASS-TRAIT) {
    $!json-item-declarations := @declarations;
    $!json-trait-name := $trait;
}

method json-item-declarations(Bool :$clear) is raw {
    LEAVE {
        if $clear {
            $!json-item-declarations := Nil;
            $!json-trait-name := Nil;
        }
    }
    $!json-item-declarations // ()
}

method json-trait-name(Mu) { $!json-trait-name }

method json-add-item-descriptor(Mu \obj, JSON::Class::ItemDescriptor:D $descr) {
    ( $!json-item-descriptors
        // ($!json-item-descriptors := Array[JSON::Class::ItemDescriptor:D].new) ).push: $descr;
}

method json-item-default(Mu \obj) { $!json-item-default }

method json-local-item-descriptors(Mu \obj) is raw { $!json-item-descriptors // () }

method json-build-collection-subset(@descriptors, Str:D $kind) is raw {
    my Mu:U @types = @descriptors.map(*.type);
    my @type-names = @types.map(*.^name);
    my $subset-name = "JSON" ~ $kind.tclc ~ "Of(" ~ @type-names.join("|") ~ ")";

    my $any-child-type = @types.any;

    my \JSONCollectionTypes =
        Metamodel::SubsetHOW.new_type:
            :name($subset-name),
            :refinee(Mu),
            :refinement({ $_ ~~ $any-child-type });

    &trait_mod:<will>(
        :complain,
        JSONCollectionTypes,
        { "expected any of " ~ @type-names.join(", ") ~ ", but got " ~ type-or-instance($_) } );

    JSONCollectionTypes
}