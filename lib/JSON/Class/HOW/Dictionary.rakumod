use v6.e.PREVIEW;
unit role JSON::Class::HOW::Dictionary:ver($?DISTRIBUTION.meta<ver>):auth($?DISTRIBUTION.meta<auth>):api($?DISTRIBUTION.meta<api>);

use JSON::Class::HOW::Collection;
use JSON::Class::HOW::Collection::DefParser;
use JSON::Class::Types :NOT-SET;
use JSON::Class::Utils;
use JSON::Class::Jsonish;

also does JSON::Class::HOW::Collection;

has Mu $!json-key-descriptor;

my class DefParser does JSON::Class::HOW::Collection::DefParser['dictionary'] {
    multi method parse-trait-def(Mu :$keyof! is raw) {
        self.parse-trait-def(:kind<keyof>, |$keyof.List.Capture);
    }

    multi method handle-definition('keyof', JSON::Class::Descriptor:D $descr) {
        self.json-class.^json-set-key-descriptor($descr);
    }
}

method json-set-key-descriptor(Mu \obj, JSON::Class::Descriptor:D $descr) {
    $!json-key-descriptor := $descr<>;
}

method json-key-descriptor(Mu \obj) is raw {
    $!json-key-descriptor //
        ($!json-key-descriptor :=
            JSON::Class::ItemDescriptor.new(:declarant(obj.WHAT), :type(Str()), :name("keyof Str")))
}

method json-keyof(Mu \obj --> Mu) is raw { self.json-key-descriptor(obj).type }

method json-setup-dictionary(Mu \obj, +@definitions) {
    self.json-init-dictionary(obj);
    self.json-set-item-default(obj, NOT-SET, :force);

    my $def-parser = DefParser.new(json-class => obj.WHAT);
    for @definitions {
        $def-parser.parse-trait-def($_);
    }

    self.json-set-item-default(obj, nominalize-type( self.json-item-descriptors(obj).head.type ));
}
