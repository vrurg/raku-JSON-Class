use v6.e.PREVIEW;
unit role JSON::Class::HOW::Collection::Class:ver($?DISTRIBUTION.meta<ver>):auth($?DISTRIBUTION.meta<auth>):api($?DISTRIBUTION.meta<api>);

use JSON::Class::HOW::Collection;
use JSON::Class::ItemDescriptor;
use JSON::Class::Types :NOT-SET;
use JSON::Class::Utils;

# Item descriptors collected from parents and roles
has $!json-mro-descriptors;

has $!json-descr-by-cond;

method json-build-from-mro(Mu \obj) {
    return with $!json-mro-descriptors;

    my @descriptors;
    my @non-basics;
    my $guessed-default := NOT-SET;

    for |self.json-roles(obj), |obj.^mro.grep({ .HOW ~~ JSON::Class::HOW::Collection }) -> \typeobj {
        my \typeobj-how = typeobj.HOW;
        if typeobj-how ~~ ::?ROLE && typeobj-how.json-kind ne self.json-kind {
            self.json-add-warning:
                obj,
                self.json-kind.tclc
                    ~ " class " ~ obj.^name ~ " subclasses "
                    ~ typeobj-how.json-kind ~ " " ~ typeobj.^name
                    ~ ", ignoring inherited item descriptors";
        }
        $guessed-default := typeobj.HOW.json-item-default(typeobj) if $guessed-default =:= NOT-SET;
        for typeobj.^json-local-item-descriptors -> JSON::Class::ItemDescriptor:D $descr {
            my \dtype = $descr.type;
            @descriptors.push: $descr;
        }
    }

    $!json-mro-descriptors := @descriptors;

    self.json-set-item-default(obj, $guessed-default) unless $guessed-default =:= NOT-SET;

    self.json-build-collection-type(obj, @descriptors);
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
        @descr-list := (self.json-local-item-descriptors // ());
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