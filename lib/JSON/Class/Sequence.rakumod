use v6.e.PREVIEW;
unit class JSON::Class::Sequence:ver($?DISTRIBUTION.meta<ver>):auth($?DISTRIBUTION.meta<auth>):api($?DISTRIBUTION.meta<api>);

use JSON::Class::Collection;
use JSON::Class::Common;
use JSON::Class::Config;
use JSON::Class::ItemDescriptor;
use JSON::Class::Types :DEFAULT;
use JSON::Class::Utils;
use JSON::Class::Types :NOT-SET;

also does Positional;
also does Iterable;
also does JSON::Class::Collection;
also does JSON::Class::Common;
also does JSON::Class::Types::CloneFrom;

# Un-deserialized yet items
has $!json-raw;
has int $!json-unused-count;
# Deserialized or user-installed items
has @!json-items handles <push append of>;

multi method new(*@items, *%profile) {
    given self.bless(|%profile) {
        .append: @items if @items;
        $_
    }
}

submethod TWEAK(:@json-raw) {
    $!json-raw := @json-raw;
    @!json-items := self.json-new-seq-array;
    $!json-unused-count = $!json-raw.elems;
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
    @cands ||= self.json-guess-descr-candidates($json-value, @descr-for-guess);

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
        $rc := @!json-items.ASSIGN-POS($idx, Nil);
    }

    $rc
}

method json-all-set { !$!json-unused-count }

method !json-delete-pos-raw($pos --> Mu) is raw {
    my $rc := Nil;
    if ($!json-raw andthen .EXISTS-POS($pos)) {
        $rc := $!json-raw.DELETE-POS($pos);
        if --$!json-unused-count == 0 {
            $!json-raw := Empty;
        }
        elsif $!json-unused-count < 0 {
            JSON::Class::X::AdHoc.new(
                message => "We overused our lazy elements somehow, has taken "
                            ~ $!json-unused-count.abs ~ " more elements than there was available!" ).throw;
        }
    }
    $rc
}

method AT-POS(::?CLASS:D: Int:D $idx --> Mu) is raw {
    return @!json-items[$idx] if @!json-items.EXISTS-POS($idx) || !$!json-raw.EXISTS-POS($idx);
    return self.^json-item-default if $idx > self.end;

    my Mu $json-value := self!json-delete-pos-raw($idx);

    self.json-lazy-deserialize-context: {
        self.json-deserialize-item($idx, $json-value)
    }
}

method EXISTS-POS(::?CLASS:D: Int:D $pos) {
    $!json-raw.EXISTS-POS($pos) || @!json-items.EXISTS-POS($pos)
}

multi method ASSIGN-POS(::?CLASS:D: Int:D $pos, Mu \value) is raw {
    self!json-delete-pos-raw($pos);
    @!json-items.ASSIGN-POS($pos, value)
}

proto method HAS-POS(::?CLASS:D: Any:D) {*}
multi method HAS-POS(::?CLASS:D: Int:D $pos, Bool:D :$has = True) {
    ! (@!json-items.EXISTS-POS($pos) ^^ $has)
}
multi method HAS-POS(::?CLASS:D: Iterable:D \positions, Bool:D :$has = True) {
    positions.map({ ! (@!json-items.EXISTS-POS($_) ^^ $has) }).List
}

multi method DELETE-POS(::?CLASS:D: Int:D $pos) is raw {
    self!json-delete-pos-raw($pos);
    @!json-items.DELETE-POS($pos)
}

method elems(::?CLASS:D:) { $!json-raw.elems max @!json-items.elems }

method end(::?CLASS:D:) { $!json-raw.end max @!json-items.end }

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
    my $array := self.json-new-seq-array;
    my $from := self.json-all-set ?? @!json-items !! self;
    for ^$from.elems -> $pos {
        $array.ASSIGN-POS($pos, $from.AT-POS($pos)) if $from.EXISTS-POS($pos);
    }
    $array
}

multi method Str(::?CLASS:D:) { self.Array.Str }
multi method gist(::?CLASS:D:) { self.Array.gist }
multi method raku(::?CLASS:D:) { self.^name ~ ".new(" ~ self.map(*.raku).join(", ") ~ ")" }