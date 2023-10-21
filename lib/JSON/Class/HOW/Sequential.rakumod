use v6.e.PREVIEW;
# For sequential roles where ther functionality is only to define sequence items.
unit role JSON::Class::HOW::Sequential:ver($?DISTRIBUTION.meta<ver>):auth($?DISTRIBUTION.meta<auth>):api($?DISTRIBUTION.meta<api>);

use JSON::Class::Internals;
use JSON::Class::ItemDescriptor;
use JSON::Class::Types :NOT-SET;
use JSON::Class::Utils;

has $!json-item-descriptors;
# What would serve as default value for array elements when Nil is assigned.
has Mu $!json-item-default;

method json-set-item-default(Mu \item-default) {
    $!json-item-default := item-default if $!json-item-default =:= NOT-SET;
}

method json-setup-sequence(Mu \obj, +@definitions) {
    my Mu $guessed-default := NOT-SET;
    $!json-item-default := NOT-SET;

    my proto sub parse-def(|) {*}
    multi sub parse-def(Mu:U \typeobj, *%c ( :to-json(:$serializer), :from-json(:$deserializer), :$matcher, *%extra) ) {
        verify-named-args(:%extra, :what("sequence item definition for " ~ typeobj.^name), :source(obj.^name));

        given JSON::Class::ItemDescriptor.new( :declarant(obj),
                                               :type(typeobj),
                                               :name("item " ~ typeobj.^name))
        {
            .set-serializer($serializer);
            .set-deserializer($deserializer);
            .set-matcher($matcher);

            $guessed-default := .type if $guessed-default =:= NOT-SET && .type.^archetypes.nominal;

            $!json-item-descriptors.push: $_;
        }
    }
    multi sub parse-def(Pair:D $ (Mu:U :key($typeobj) is raw, :value($adv))) {
        samewith($typeobj, |$adv.List.Capture)
    }
    multi sub parse-def(Mu :$default) {
        $!json-item-default := $default<> if $!json-item-default =:= NOT-SET;
    }
    multi sub parse-def(Pair:D $adverb (Str:D :key($), Mu :value($))) {
        parse-def(|$adverb)
    }
    multi sub parse-def(@def) {
        parse-def(|@def.Capture)
    }
    multi sub parse-def(*%c) {
        my $sfx = %c > 1 ?? "s" !! "";
        JSON::Class::X::Trait::Argument.new(
            :why("unknown :sequence adverb" ~ $sfx ~ " " ~ %c.keys.map(':' ~ *).join(", ")),
            :singular
        ).throw
    }

    without $!json-item-descriptors {
        $!json-item-descriptors := Array[JSON::Class::ItemDescriptor:D].new;
    }

    for @definitions {
        parse-def($_);
    }

    if $guessed-default =:= NOT-SET {
        $guessed-default := nominalize-type($!json-item-descriptors.head.type);
    }

    self.json-set-item-default($guessed-default) unless $guessed-default =:= NOT-SET;
}

method json-item-descriptors(Mu \obj) { $!json-item-descriptors // Empty }

method json-item-default(Mu \obj) { $!json-item-default }