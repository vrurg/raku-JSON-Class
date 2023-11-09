use v6.e.PREVIEW;
unit role JSON::Class::Collection:ver($?DISTRIBUTION.meta<ver>):auth($?DISTRIBUTION.meta<auth>):api($?DISTRIBUTION.meta<api>);

use JSON::Class::ItemDescriptor;
use JSON::Class::X;

method json-only-single-descriptor(@cands, JSON::Class::X::Base \ex, Mu \value, *%c) {
    return @cands.head if @cands == 1;

    if !@cands {
        ex.new( :type(self.WHAT), :what(value), :why("no matching item definition found"), |%c ).throw
    }

    ex.new( :type(self.WHAT),
            :what(value),
            :why( "item definitions for types "
                    ~ (@cands.map(*.type.^name).join(", "))
                    ~ " are matching, but only one is expected"),
            |%c ).throw
}

proto method json-guess-descr-candidates($, @) {*}

multi method json-guess-descr-candidates(Map:D $json-value, @descr-for-guess) {
    my $json-key-set;
    my $config;
    # Chose descriptors where either JSON object keys are a subset of class' JSON keys, or JSON object hash
    # matches descriptor type (mostly useful with coercions), or descriptor represents an associative type.
    @descr-for-guess.grep({
        ($^descr.is-a-class && do {
            my \cand-jclass = ($config //= self.json-config).jsonify(:nominal-what($descr.nominal-type));
            ($json-key-set //= $json-value.keys.Set) ⊆ cand-jclass.^json-mro-key-set;
        })
        || ($json-value ~~ (my \dtype = $descr.type) #`{ Mostly to support coercions })
        || (dtype ~~ Associative);
    })
}

multi method json-guess-descr-candidates(List:D $json-value, @descr-for-guess) {
    @descr-for-guess.grep({ .type ~~ Positional })
}

multi method json-guess-descr-candidates($json-value, @descr-for-guess) {
    @descr-for-guess.grep({ $json-value ~~ $^descr.type });
}

proto method json-guess-descriptor(|) {*}

multi method json-guess-descriptor(::?CLASS:D: Mu :$item-value! is raw --> JSON::Class::ItemDescriptor:D) is raw {
    my @desc = self.json-class.^json-item-descriptors.grep({ $item-value ~~ $^descr.type });

    if !@desc {
        JSON::Class::X::Serialize::Impossible.new(
            :type(self.WHAT),
            :what($item-value),
            :why("type is not registered with the sequence")).throw
    }
    elsif @desc > 1 {
        JSON::Class::X::Serialize::Impossible.new(
            :type(self.WHAT),
            :what($item-value),
            :why("too many types are matching, possible candidates are " ~ @desc.map(*.type.^name).join(", "))).throw
    }

    @desc.head
}