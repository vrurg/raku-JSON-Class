use v6.e.PREVIEW;
unit role JSON::Class::SequenceHOW:ver($?DISTRIBUTION.meta<ver>):auth($?DISTRIBUTION.meta<auth>):api($?DISTRIBUTION.meta<api>);

use experimental :will-complain;

use JSON::Class::HOW::Configurable;
use JSON::Class::HOW::Laziness;
use JSON::Class::HOW::Sequential;
use JSON::Class::HOW::SelfConfigure;
use JSON::Class::ItemDescriptor;
use JSON::Class::Jsonish;
use JSON::Class::Utils;
use JSON::Class::Types :NOT-SET;
use JSON::Class::X;

also does JSON::Class::HOW::Configurable;
also does JSON::Class::HOW::Laziness;
also does JSON::Class::HOW::Sequential;
also does JSON::Class::HOW::SelfConfigure;

# Item descriptors collected from parents and roles
has $!json-mro-descriptors;

has $!json-descr-by-cond;

has Array:U $!json-array-type;

method json-build-array-type(@descriptors) {
    my Mu:U @types = @descriptors.map(*.type);
    my @type-names = @types.map(*.^name);
    my $subset-name = "JSONSequenceOf(" ~ @type-names.join("|") ~ ")";

    my $any-child-type = @types.any;

    my \JSONSeqTypes =
        Metamodel::SubsetHOW.new_type:
            :name($subset-name),
            :refinee(Mu),
            :refinement({ $_ ~~ $any-child-type });

    &trait_mod:<will>(
        :complain,
        JSONSeqTypes,
        { "expected any of " ~ @type-names.join(", ") ~ ", but got " ~ type-or-instance($_) } );

    $!json-array-type := Array.^parameterize(JSONSeqTypes);
}

method json-build-from-mro(Mu \obj) {
    my @descriptors;
    my @non-basics;
    my $guessed-default := NOT-SET;

    for obj.^mro(:roles).grep({ .HOW ~~ ::?CLASS }) -> \typeobj {
        $guessed-default := typeobj.HOW.json-item-default(typeobj) if $guessed-default =:= NOT-SET;
        for typeobj.^json-item-descriptors(:local).List -> JSON::Class::ItemDescriptor:D $descr {
            my \dtype = $descr.type;
            @descriptors.push: $descr;
        }
    }

    $!json-mro-descriptors := @descriptors;

    self.json-set-item-default($guessed-default) unless $guessed-default =:= NOT-SET;

    self.json-build-array-type(@descriptors);
}

method json-array-type(Mu \obj) {
    self.json-build-from-mro(obj) without $!json-mro-descriptors;
    $!json-array-type
}

my constant IDESCR_LOCAL   = 1;
my constant IDESCR_CLASS   = 1 +< 1;
my constant IDESCR_NOCLASS = 1 +< 2;
my constant IDESCR_MATCHER = 1 +< 3;
my constant IDESCR_NOMATCH = 1 +< 4;

method json-item-descriptors(Mu \obj, Bool :$local, Bool :$class, Bool :$with-matcher) is raw {
    my @descr-list;
    $!json-descr-by-cond //= my @;

    my sub idx4flag(Bool $flag, \when-true, \when-false) is pure {
        $flag
            andthen ($_ ?? when-true !! when-false)
            orelse (when-true +| when-false)
    }

    my $idx = ($local ?? IDESCR_LOCAL !! 0)
                +| idx4flag($class,        IDESCR_CLASS,   IDESCR_NOCLASS)
                +| idx4flag($with-matcher, IDESCR_MATCHER, IDESCR_NOMATCH);

    return $!json-descr-by-cond[$idx] if $!json-descr-by-cond.EXISTS-POS($idx);

    if $local {
        @descr-list := self.JSON::Class::HOW::Sequential::json-item-descriptors(obj);
    }
    else {
        self.json-build-from-mro(obj) without $!json-mro-descriptors;
        @descr-list := $!json-mro-descriptors;
    }

    with $class {
        @descr-list := @descr-list.grep({ is-a-class-type(.type) }).eager.List;
    }

    with $with-matcher {
        my $no-matcher = !$with-matcher;
        @descr-list :=
            @descr-list.grep({
                .has-matcher ^^ $no-matcher
            }).eager.List
    }

    # Cache and return the result.
    $!json-descr-by-cond[$idx] := @descr-list
}