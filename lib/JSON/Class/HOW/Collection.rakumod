use v6.e.PREVIEW;
unit role JSON::Class::HOW::Collection:ver($?DISTRIBUTION.meta<ver>):auth($?DISTRIBUTION.meta<auth>):api($?DISTRIBUTION.meta<api>);

use experimental :will-complain;

use JSON::Class::ItemDescriptor;
use JSON::Class::Types :NOT-SET;
use JSON::Class::Utils;

has $!json-item-descriptors;
# What would serve as default value for array elements when Nil is assigned.
has Mu $!json-item-default;

# Item descriptors collected from parents and roles
has $!json-mro-descriptors;

has $!json-descr-by-cond;

method json-build-collection-type(@) {...}

method json-set-item-default(Mu \obj, Mu \item-default, Bool :$force) {
    $!json-item-default := item-default if $force || $!json-item-default =:= NOT-SET;
}

method json-add-item-descriptor(Mu \obj, JSON::Class::ItemDescriptor:D $descr) {
    ( $!json-item-descriptors
        // ($!json-item-descriptors := Array[JSON::Class::ItemDescriptor:D].new) ).push: $descr;
}

method json-item-default(Mu \obj) { $!json-item-default }

method json-build-from-mro(Mu \obj) {
    return with $!json-mro-descriptors;

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

    self.json-set-item-default(obj, $guessed-default) unless $guessed-default =:= NOT-SET;

    self.json-build-collection-type(obj, @descriptors);
}

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
        @descr-list := ($!json-item-descriptors // ());
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