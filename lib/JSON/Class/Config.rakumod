use v6.e.PREVIEW;
unit class JSON::Class::Config:ver($?DISTRIBUTION.meta<ver>):auth($?DISTRIBUTION.meta<auth>):api($?DISTRIBUTION.meta<api>);

use AttrX::Mooish;

use JSON::Class::HOW::JSONified;
use JSON::Class::HOW::TypeWrapper;
use JSON::Class::Internals;
use JSON::Class::Jsonish;
use JSON::Class::Types;
use JSON::Class::Utils;
use JSON::Class::X;

my enum SerializeSeverity <EASY WARN STRICT>;

has SerializeSeverity:D $!severity is built = WARN;

# Bypass laziness and deserialize immediately
has Bool $!eager is built = False;

has Bool $!skip-null is built = True;

# Named arguments for to-json/from-json
has Bool $!pretty is built = False;
has Bool $!sorted-keys is built = False;
has Bool $!enums-as-value is built = False;
has Bool $!allow-jsonc is built = False;
has UInt $!spacing is built = 2;

has %!helpers{Mu:U};
has Lock $!helpers-lock .= new;

has Mu:U %!type-map{Mu:U};
has Lock $!type-map-lock .= new;

my JSON::Class::Config $singleton;

my JSON::Class::Jsonish:U %jsonifications{Mu:U};
my Lock $jsonifications-lock .= new;

my Mu:U $json-class-how;
my Mu:U $json-representation;
my Mu:U $json-object-class;
my $std-types-lock = Lock.new;

has Bool $.using-defaults;

our sub set-std-typeobjects( Mu :$class-how is raw,
                             Mu :$object is raw,
                             Mu :$representation is raw --> Nil )
{
    $std-types-lock.protect: {
        $json-class-how := $class-how<>;
        $json-representation := $representation<>;
        $json-object-class := $object<>;
    }
}

method json-class-how is raw { $json-class-how }
method json-representation is raw { $json-representation }
method json-object-class is raw { $json-object-class }

submethod TWEAK(Bool :defaults($!using-defaults) = True, Bool :$easy, Bool :$warn, Bool :$strict) {
    if $!using-defaults {
        self!PRESET-HELPERS;
    }
    self.set-severity(:$easy, :$warn, :$strict);
}

method global(*%c) {
    cas $singleton, {
        JSON::Class::X::Config::ImmutableGlobal.new.throw if $_ && %c;
        $_ // self.new(|%c)
    }
}

method profile is raw {
    my %p;
    for self.^attributes(:!local).grep({ .has_accessor || .is_built }) -> $attr {
        %p{$attr.name.substr(2)} := $attr.get_value(self)<>;
    }
    %p
}

proto method dup(|) {*}
multi method dup(::?CLASS:U: |c) { self.global.dup(|c) }
multi method dup(::?CLASS:D: *%twiddles) {
    self.new: |self.profile, |%twiddles
}

proto method pretty(|) {*}
multi method pretty(::?CLASS:U:) { self.global.pretty }
multi method pretty(::?CLASS:D:) { $!pretty }

proto method sorted-keys(|) {*}
multi method sorted-keys(::?CLASS:U:) { self.global.sorted-keys }
multi method sorted-keys(::?CLASS:D:) { $!sorted-keys }

proto method enums-as-value(|) {*}
multi method enums-as-value(::?CLASS:U:) { self.global.enums-as-value }
multi method enums-as-value(::?CLASS:D:) { $!enums-as-value }

proto method allow-jsonc(|) {*}
multi method allow-jsonc(::?CLASS:U:) { self.global.allow-jsonc }
multi method allow-jsonc(::?CLASS:D:) { $!allow-jsonc }

proto method spacing(|) {*}
multi method spacing(::?CLASS:U:) { self.global.spacing }
multi method spacing(::?CLASS:D:) { $!spacing }

proto method skip-null(|) {*}
multi method skip-null(::?CLASS:U:) { self.global.skip-null }
multi method skip-null(::?CLASS:D:) { $!skip-null }

proto method eager(|) {*}
multi method eager(::?CLASS:U:) { self.global.eager }
multi method eager(::?CLASS:D:) { $!eager }

proto method jsonify(|) {*}

proto method non-jsonifiable(Mu:U) {*}

multi method non-jsonifiable(::?CLASS:U: Mu:U \typeobj) {
    self.global.non-jsonifiable(typeobj)
}

multi method non-jsonifiable(::?CLASS:D: Version --> True) {
    self.notify: "Version class cannot have an implicit JSONification. ",
                    ($.using-defaults
                    ?? "But default marshallers will take care of Version objects."
                    !! "Default marshallers are disabled, consider using your own.");
}

multi method non-jsonifiable( ::?CLASS:D:
                              Mu:U \typeobj where Promise | Supply | Channel | Lock | IO::Handle | IO::Socket
                              --> True )
{
    self.alert: JSON::Class::X::UnsupportedType.new(:type(typeobj), :why("cannot be implicitly JSONified"));
}

multi method non-jsonifiable(::?CLASS:D: Mu:U --> False) {}

multi method jsonify( Mu:U :$nominal-what is raw, Bool :$local --> Mu ) is raw {
    unless $nominal-what.HOW ~~ Metamodel::ClassHOW {
        JSON::Class::X::NonClass.new(:type($nominal-what), :what('produce an implicit JSON representation')).throw
    }

    $jsonifications-lock.protect: {
        return $nominal-what if $nominal-what ~~ $json-representation;

        return %jsonifications{$nominal-what} if %jsonifications{$nominal-what}:exists;

        if self.non-jsonifiable($nominal-what) {
            # If a type is not supported then let it be reported by the checker method. If the problem is not considered
            # as severe the reported code wouldn't throw and then we just return un-JSONified original type object.
            return $nominal-what
        }

        my \jsonified = $nominal-what.^mixin($json-representation);
        %jsonifications{$nominal-what} := jsonified;
        jsonified.HOW does $json-class-how;
        jsonified.HOW does JSON::Class::HOW::JSONified[$nominal-what];
        jsonified.^json-set-explicit(False);
        jsonified.^json-set-lazy(False);
        my $*PACKAGE := jsonified;
        jsonified.^json-imply-attributes(:$local);
        jsonified
    }
}

multi method jsonify(Mu:U $what is raw, |c) is raw {
    self.jsonify(nominal-what => nominalize-type($what), |c)
}

multi method jsonify(Mu:D $obj, *%c) {
    self.jsonify(nominal-what => $obj.WHAT, |%c).clone-from($obj)
}

proto method set-helpers(|) {*}
multi method set-helpers(::?CLASS:U: |c) { self.global.set-helpers(|c) }
multi method set-helpers( ::?CLASS:D:
                          Mu $what,
                          JSONHelper :to-json(:$serializer),
                          JSONHelper :from-json(:$deserializer),
                          JSONHelper :$matcher,
                          *%helpers )
{
    $!helpers-lock.lock;
    LEAVE $!helpers-lock.unlock;

    my Mu \nominal-what = nominalize-type($what);
    %!helpers{nominal-what}{JSSerialize} := $_ with $serializer<>;
    %!helpers{nominal-what}{JSDeserialize} := $_ with $deserializer<>;
    %!helpers{nominal-what}{JSMatch} := $_ with $matcher<>;
    my @keys = %helpers.keys;
    %!helpers{nominal-what}{@keys} = %helpers{@keys};
}

proto method serializer(|) {*}
multi method serializer(::?CLASS:U: |c) { self.global.serializer(|c) }
multi method serializer(::?CLASS:D: Mu $what) {
    $!helpers-lock.lock;
    LEAVE $!helpers-lock.unlock;

    %!helpers{nominalize-type($what)}{JSSerialize} // Nil
}

proto method deserializer(|) {*}
multi method deserializer(::?CLASS:U: |c) { self.global.deserializer(|c) }
multi method deserializer(::?CLASS:D: Mu $what is raw) {
    $!helpers-lock.lock;
    LEAVE $!helpers-lock.unlock;
    %!helpers{nominalize-type($what)}{JSDeserialize} // Nil
}

proto method matcher(|) {*}
multi method matcher(::?CLASS:U: |c) { self.global.matcher(|c) }
multi method matcher(::?CLASS:D: Mu $what is raw) {
    $!helpers-lock.lock;
    LEAVE $!helpers-lock.unlock;
    %!helpers{nominalize-type($what)}{JSMatch} // Nil
}

my constant %STAGE-MAP = serializer => JSSerialize, deserializer => JSDeserialize;

proto method helper(|) {*}
multi method helper(::?CLASS:U: |c) { self.global.helper(|c) }
multi method helper(::?CLASS:D: Mu $what is raw, Str:D $stage) {
    $!helpers-lock.lock;
    LEAVE $!helpers-lock.unlock;
    %!helpers{nominalize-type($what)}{%STAGE-MAP{$stage} // $stage} // Nil
 }

proto method map-type(|) {*}
multi method map-type(::?CLASS:U: |c) { self.global.map-type(|c) }
multi method map-type(::?CLASS:D: Mu:U \from-type, Mu:U \to-type --> Nil) {
    $!type-map-lock.lock;
    LEAVE $!type-map-lock.unlock;
    unless to-type ~~ from-type {
        self.notify: "Target type '", to-type.^name,
                     "' is not a child of '", from-type.^name, "'. This may result in type-match errors.";
    }
    %!type-map{from-type<>} := to-type<>;
}
multi method map-type(::?CLASS:D: Mu:U \wrapper --> Nil) {
    $!type-map-lock.lock;
    LEAVE $!type-map-lock.unlock;

    unless wrapper.HOW ~~ JSON::Class::HOW::TypeWrapper {
        JSON::Class::X::Config::NonWrapperType.new(:type(wrapper)).throw
    }

    %!type-map{wrapper.^json-wrappee} := wrapper<>;
}
multi method map-type(::?CLASS:D: Pair:D $map --> Nil) {
    self.map-type($map.key, $map.value)
}

proto method map-types(|) {*}
multi method map-types(::?CLASS:U: |c) { self.global.map-types(|c) }
multi method map-types(::?CLASS:D: *@pos) {
    self.map-type($_) for @pos;
}

proto method type-from(|) {*}
multi method type-from(::?CLASS:U: |c --> Mu) is raw { self.global.type-from(|c) }
multi method type-from(::?CLASS:D: Mu:U \from --> Mu) is raw {
    $!type-map-lock.lock;
    LEAVE $!type-map-lock.unlock;

    # See if nominalization is a product of jsonificaton and work on the original type
    my Mu \nominalization = nominalize-type(from);
    my Mu \from-type = nominalization.HOW ~~ JSON::Class::HOW::JSONified ?? nominalization.^json-FROM !! nominalization;
    %!type-map.EXISTS-KEY(from-type) ?? %!type-map.AT-KEY(from-type) !! nominalization
}

method !map-severity(%adv) is hidden-from-backtrace {
    %adv.first(*.value)
        andthen SerializeSeverity::{.key.uc}
        orelse  Nil
}

proto method set-severity(|) {*}
multi method set-severity(::?CLASS:U: |c) { self.global.set-severity(|c) }
multi method set-severity(::?CLASS:D: *%adv (Bool :easy($), Bool :warn($), Bool :strict($))) {
    verify-named-args(%adv, :unique<easy warn strict>, :what('method set-severity'), :source(self.^name));
    with %adv.first(*.value) {
        return $!severity = SerializeSeverity::{.key.uc};
    }
    Nil
}

proto method with-severity(|) {*}
multi method with-severity(::?CLASS:U: |c --> Mu) is raw is hidden-from-backtrace { self.global.with-severity(|c) }
multi method with-severity(::?CLASS:D: &code, *%adv (Bool :easy($), Bool :warn($), Bool :strict($)) --> Mu)
    is hidden-from-backtrace is raw
{
    verify-named-args(%adv, :unique<easy warn strict>, :what('method with-severity'), :source(self.^name));
    my $*JSON-CLASS-SEVERITY := self!map-severity(%adv);
    &code()
}

proto method severity(|) {*}
multi method severity(::?CLASS:U:) { self.global.severity }
multi method severity(::?CLASS:D:) { $!severity.key.lc }

proto method alert(|) {*}
multi method alert(::?CLASS:U: |c) is hidden-from-backtrace { self.global.alert(|c) }
multi method alert(::?CLASS:D: Exception:D $ex --> Nil) {
    my $severity = $*JSON-CLASS-SEVERITY // $!severity;
    return if $severity == EASY;
    if $severity == WARN {
        warn $ex.message;
    }
    else {
        $ex.rethrow
    }
}
multi method alert(::?CLASS:D: *@msg) is hidden-from-backtrace {
    self.alert: JSON::Class::X::AdHoc.new(message => @msg.map(*.gist).join)
}

proto method notify(|) {*}
multi method notify(::?CLASS:U: |c) { self.global.notify(|c) }
multi method notify(::?CLASS:D: *@msg --> Nil) {
    return if ($*JSON-CLASS-SEVERITY // $!severity) == EASY;
    warn @msg.map(*.gist).join;
}

method to-json-profile is raw {
    ( :$!pretty, :$!sorted-keys, :$!enums-as-value, :$!spacing).Map
}

method from-json-profile is raw {
    ( :$!allow-jsonc ).Map
}

method !PRESET-HELPERS {
    self.set-helpers: DateTime,
                      :to-json<Str>,
                      :from-json<new>,
                      matcher => -> Str:D $from { ? try { DateTime.new($from) } };

    self.set-helpers: Version,
                      :to-json<Str>,
                      :from-json<new>,
                      matcher => -> Str:D $from { ? try { Version.new($from) } };

    for Set, SetHash -> \type {
        self.set-helpers: type, :to-json({ .keys }), :from-json({ type.new(@^from) });
    }

    self.set-helpers: SetHash,
                      :to-json({ .keys }),
                      :from-json({ .SetHash });

    for Bag, BagHash, Mix, MixHash -> \type {
        self.set-helpers: type, :from-json({ type.new-from-pairs(%^from) });
    }
}