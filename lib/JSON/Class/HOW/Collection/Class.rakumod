use v6.e.PREVIEW;
unit role JSON::Class::HOW::Collection::Class:ver($?DISTRIBUTION.meta<ver>):auth($?DISTRIBUTION.meta<auth>):api($?DISTRIBUTION.meta<api>);
use MONKEY-SEE-NO-EVAL;

use JSON::Class::HOW::Collection;
use JSON::Class::ItemDescriptor;
use JSON::Class::Types :NOT-SET, :DEFAULT;
use JSON::Class::Utils;

# Item descriptors collected from parents and roles
has $!json-mro-descriptors is json-meta(:mixin-skip);

has $!json-descr-by-cond is json-meta(:mixin-skip);
has $!json-has-coercions is json-meta(:mixin-skip);

method json-build-collection-type(Mu,@) {...}

method json-build-from-mro(Mu \obj, :$force --> Nil) {
    return if !$force && $!json-mro-descriptors.DEFINITE;

    my @descriptors;
    my @non-basics;
    my $guessed-default := NOT-SET;

    for |self.json-roles(obj), |obj.^mro(:unhidden).grep({ .HOW ~~ JSON::Class::HOW::Collection }) -> \typeobj {
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
    $!json-descr-by-cond = Nil if $force;

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

    if $class {
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

method json-has-coercions(Mu \obj) {
    $!json-has-coercions := self.json-item-descriptors(obj).first(*.type.^archetypes.coercive, :k).defined
}

# Produces a code object which takes a source value and coerces it if necessary. The code is a multi-dispatch routine
# where candidates are added in the order of our descriptors.
has $!json-assign-thunk is json-meta(:mixin-skip);
method json-compose-assign-thunk(Mu \obj) {
    without $!json-assign-thunk {
        if self.json-has-coercions(obj) {
            my $sub-name = "_assign_" ~ (S:g/\W/_/ given self.name(obj));
            my &proto = $!json-assign-thunk := ('my proto sub ' ~ $sub-name ~ '(Mu) {*}').EVAL;

            my sub new-cand(::T) { my sub (T \v) is raw { my T $ = v } }

            for self.json-item-descriptors(obj) -> \descr {
                &proto.add_dispatchee: new-cand(descr.type);
            }

            &proto.add_dispatchee: my sub (Mu \v) is raw { v };
        }
        else {
            $!json-assign-thunk := sub (Mu \v) is raw { v };
        }
    }
    $!json-assign-thunk
}