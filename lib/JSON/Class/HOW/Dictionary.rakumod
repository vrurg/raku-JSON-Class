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
    multi method parse-trait-def(List(Mu) :$keyof! is raw (Mu:U \type = Str:D(), *%c)) {
        self.parse-trait-def(type, |%c, :kind<keyof>);
    }
    multi method parse-trait-def(Mu :$keyof! where *.^archetypes.generic) {
        self.parse-trait-def(:keyof($keyof,));
    }

    multi method handle-definition('keyof', JSON::Class::Descriptor:D $descr) {
        self.json-type.^json-set-key-descriptor($descr);
    }
}

method json-set-key-descriptor(Mu \obj, JSON::Class::Descriptor:D $descr, Bool :$offer --> Nil) {
    return if $offer && $!json-key-descriptor.DEFINITE;
    $!json-key-descriptor := $descr<>;
}

method json-key-descriptor(Mu \obj, Bool :$peek) is raw {
    $!json-key-descriptor //
        ($peek
            ?? Nil
            !! ($!json-key-descriptor :=
                JSON::Class::ItemDescriptor.new(:declarant(obj.WHAT), :type(Str()), :name("keyof Str"), :kind<keyof>)))
}

method json-keyof(Mu \obj --> Mu) is raw { self.json-key-descriptor(obj).type }

method json-setup-dictionary(Mu \obj) {
    self.json-set-item-default(obj, NOT-SET, :force);

    my $def-parser = DefParser.new(json-type => obj.WHAT);
    my $trait-name = $*JSON-CLASS-TRAIT // self.json-trait-name(obj);
    {
        my $*JSON-CLASS-TRAIT := $trait-name;
        for self.json-item-declarations(:clear) {
            $def-parser.parse-trait-def($_);
        }
    }

    self.json-set-item-default(obj, nominalize-type( self.json-item-descriptors(obj).head.type ));
}

method json-instantiate-dictionary(Mu \obj, TypeEnv:D \typeenv --> Mu) is raw {
    self.json-instantiate-collection(obj, typeenv);

    if $!json-key-descriptor andthen .is-generic {
        $!json-key-descriptor := typeenv.instantiate($!json-key-descriptor);
    }

    obj
}