use v6.e.PREVIEW;
unit class JSON::Class::Sequence:ver($?DISTRIBUTION.meta<ver>):auth($?DISTRIBUTION.meta<auth>):api($?DISTRIBUTION.meta<api>);
use nqp;

use JSON::Class::Common;
use JSON::Class::Config;
use JSON::Class::ItemDescriptor;
use JSON::Class::Types :DEFAULT;
use JSON::Class::Utils;
use JSON::Class::Types :NOT-SET;

also does Positional;
also does Iterable;
also does JSON::Class::Common;
also does JSON::Class::Types::CloneFrom;

# Un-deserialized yet items
has Mu @!json-raw;
has int $!json-unused-count;
# Deserialized or user-installed items
has @!json-items handles <ASSIGN-POS push append of>;

multi method new(*@items, *%profile) {
    given self.bless(|%profile) {
        .append: @items if @items;
        $_
    }
}

submethod TWEAK(:@!json-raw) {
    @!json-items := self.json-new-seq-array;
    $!json-unused-count = @!json-raw.elems;
}

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

multi method json-guess-descriptor(:$json-value! is raw, Int:D :$idx --> JSON::Class::ItemDescriptor:D) is raw {
    my @cands;
    my @descr-for-guess;

    for self.json-item-descriptors(:!local) -> $descr {
        if self.json-try-deserializer('match', $descr, $json-value, { @descr-for-guess.push: $descr; False }) {
            @cands.push: $descr;
        }
    }

    # Since we trust user-provided matchers the most if any descriptor has claimed the JSON object then there is no
    # need in guessing.
    unless @cands {
        given $json-value {
            when Map:D {
                my $json-key-set;
                my $config;
                # Chose descriptors where either JSON object keys are a subset of class' JSON keys, or JSON object hash
                # matches descriptor type (mostly useful with coercions), or descriptor represents an associative type.
                @cands =
                    @descr-for-guess.grep({
                        ($^descr.is-a-class && do {
                            my \cand-jclass = ($config //= self.json-config).jsonify(:nominal-what($descr.nominal-type));
                            ($json-key-set //= $json-value.keys.Set) ⊆ cand-jclass.^json-mro-key-set;
                        })
                        || ($json-value ~~ (my \dtype = $descr.type) #`{ Mostly to support coercions })
                        || (dtype ~~ Associative);
                    });
            }
            when List:D {
                @cands = @descr-for-guess.grep({ .type ~~ Positional })
            }
            default {
                @cands = @descr-for-guess.grep({ $json-value ~~ $^descr.type });
            }
        }
    }

    self.json-only-single-descriptor: @cands, JSON::Class::X::Deserialize::SeqItem, $json-value, :$idx
}

method json-serialize-item(::?CLASS:D: JSON::Class::ItemDescriptor:D $descr, Mu \value) {
    # my \json-value = is-basic-type(value) ?? value !! self.json-config.jsonify(value);
    self.json-try-serializer:
        'item', $descr, value,
        { self.json-serialize-value: $descr.nominal-type, value }
}

method json-serialize(::?CLASS:D:) is raw {
    my $*JSON-CLASS-SELF := self;
    my $iter = self.iterator;
    gather loop {
        last if (my Mu $item := $iter.pull-one) =:= IterationEnd;

        my $*JSON-CLASS-DESCRIPTOR :=
        my JSON::Class::ItemDescriptor:D $descr = self.json-guess-descriptor(item-value => $item);
        take self.json-serialize-item($descr, $item)
    }
}

multi method json-deserialize(@from, JSON::Class::Config :$config is copy) {
    my $*JSON-CLASS-SELF := self;
    $config //= self.json-config;
    my \seq-class = $config.type-from(self.WHAT);

    # Sequence is always lazy. Otherwise it makes more sense to have an array.
    seq-class.json-create:
        json-raw => @from,
        json-lazy-config => $config
}

method json-deserialize-item(::?CLASS:D: Int:D $idx, Mu $json-value is raw --> Mu) is raw {
    my Mu $rc;

    with $json-value {
        with self.json-guess-descriptor(:$json-value, :$idx) -> JSON::Class::ItemDescriptor:D $descr {
            $rc := ( @!json-items[$idx] =
                        self.json-try-deserializer(
                            'item', $descr, $json-value,
                            { self.json-deserialize-value($descr.value-type, $json-value) } ));
        }
        else {
            $rc := JSON::Class::X::Deserialize::SeqItem.new(
                :type(self.WHAT), :$idx, :what($json-value),
                :why("cannot determine the target type, no matching descriptor found") ).Failure
        }
    }
    else {
        # Treat any undefined as Nil
        $rc := (@!json-items[$idx] = Nil);
    }

    $rc

}

method json-all-set { !$!json-unused-count }

method AT-POS(::?CLASS:D: Int:D $idx --> Mu) is raw {
    return @!json-items[$idx] if @!json-items.EXISTS-POS($idx) || !@!json-raw.EXISTS-POS($idx);
    return self.^json-item-default if $idx > self.end;

    my Mu $json-value := @!json-raw[$idx]:delete;
    if --$!json-unused-count == 0 {
        @!json-raw = Empty;
    }
    elsif $!json-unused-count < 0 {
        JSON::Class::X::AdHoc.new(
            message => "We overused our lazy elements somehow, has taken "
                        ~ $!json-unused-count.abs ~ " more elements than was available!" ).throw;
    }

    self.json-lazy-deserialize-context: {
        self.json-deserialize-item($idx, $json-value)
    }
}

method EXISTS-POS(::?CLASS:D: Int:D $pos) {
    @!json-raw.EXISTS-POS($pos) || @!json-items.EXISTS-POS($pos)
}

proto method HAS-POS(::?CLASS:D: Any:D) {*}
multi method HAS-POS(::?CLASS:D: Int:D $pos, Bool:D :$has = True) {
    ! (@!json-items.EXISTS-POS($pos) ^^ $has)
}
multi method HAS-POS(::?CLASS:D: Iterable:D \positions, Bool:D :$has = True) {
    positions.map({ ! (@!json-items.EXISTS-POS[$_] ^^ $has) })
}

multi method DELETE-POS(::?CLASS:D: Int:D $pos) is raw {
    @!json-raw.DELETE-POS($pos);
    @!json-items.DELETE-POS($pos)
}

method elems(::?CLASS:D:) { @!json-raw.elems max @!json-items.elems }

method end(::?CLASS:D:) { @!json-raw.end max @!json-items.end }

multi method iterator(::?CLASS:D:) {
    class :: does Iterator {
        has $.idx = 0;
        has $.seq;

        method pull-one is raw {
            return IterationEnd if $!idx > $.seq.end;
            $.seq.AT-POS($!idx++)
        }
    }.new(:seq(self))
}

multi method iterator(::?CLASS:U:) {
    (self,).iterator
}

multi method List(::?CLASS:D:) {
    self.json-all-set
        ?? @!json-items.List
        !! (^self.elems).map({ self.AT-POS($_) }).List
}

multi method Array(::?CLASS:D:) {
    self.json-new-seq-array.append:
        self.json-all-set
            ?? @!json-items
            !! (^self.elems).map({ self.AT-POS($_) })
}

multi method Str(::?CLASS:D:) { self.List.Str }
multi method gist(::?CLASS:D:) { self.List.gist }