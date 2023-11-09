use v6.e.PREVIEW;
unit role JSON::Class::HOW::Collection::DefParser:ver($?DISTRIBUTION.meta<ver>):auth($?DISTRIBUTION.meta<auth>):api($?DISTRIBUTION.meta<api>) [Str:D $collection-kind];

use JSON::Class::Internals;
use JSON::Class::ItemDescriptor;
use JSON::Class::Types :NOT-SET;
use JSON::Class::Utils;
use JSON::Class::X;

has Mu $.json-class is built(:bind) is required;

proto method parse-trait-def(|) {*}
multi method parse-trait-def( Mu:U \typeobj = Str:D,
                              Str:D :$kind = 'item',
                              *%c ( :to-json(:$serializer), :from-json(:$deserializer), :$matcher, *%extra) )
{
    verify-named-args(:%extra, :what($collection-kind ~ " item definition for " ~ typeobj.^name), :source(self.^name));

    my $descr := JSON::Class::ItemDescriptor.new( :declarant($!json-class),
                                                  :type(typeobj),
                                                  :name($kind ~ " " ~ typeobj.^name));
    $descr.set-serializer($_) with $serializer;
    $descr.set-deserializer($_) with $deserializer;
    $descr.set-matcher($_) with $matcher;
    self.handle-definition($kind, $descr);
}
multi method parse-trait-def(Pair:D $ (Mu:U :key($typeobj) is raw, :value($adv))) {
    self.parse-trait-def($typeobj, |$adv.List.Capture)
}
multi method parse-trait-def(Mu :$default!) {
    self.handle-definition('default', $default);
}
multi method parse-trait-def(Pair:D $adverb (Str:D :key($), Mu :value($))) {
    self.parse-trait-def(|$adverb)
}
multi method parse-trait-def(@def) {
    self.parse-trait-def(|@def.Capture)
}
multi method parse-trait-def(*%c) {
    my $sfx = %c > 1 ?? "s" !! "";
    JSON::Class::X::Trait::Argument.new(
        :why("unknown " ~ $collection-kind ~ " adverb" ~ $sfx ~ " " ~ %c.keys.map(':' ~ *).join(", ")),
        :singular
    ).throw
}

proto method handle-definition(|) {*}
multi method handle-definition('item', JSON::Class::Descriptor:D $descr --> Nil) {
    my Mu \dtype = $descr.type;
    $!json-class.^json-set-item-default(dtype) if dtype.^archetypes.nominal;
    $!json-class.^json-add-item-descriptor($descr);
}
multi method handle-definition('default', Mu $default is raw --> Nil) {
    $!json-class.^json-set-item-default($default<>, :force);
}