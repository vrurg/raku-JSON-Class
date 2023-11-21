use v6.e.PREVIEW;
unit role JSON::Class::Common:ver($?DISTRIBUTION.meta<ver>):auth($?DISTRIBUTION.meta<auth>):api($?DISTRIBUTION.meta<api>);
use experimental :will-complain;

use JSON::Fast;

use JSON::Class::CX;
use JSON::Class::Config;
use JSON::Class::HOW::JSONified;
use JSON::Class::Internals;
use JSON::Class::Jsonish;
use JSON::Class::Types;
use JSON::Class::Utils;

also does JSON::Class::Jsonish;

has JSON::Class::Config $!json-lazy-config;

method json-serialize {...}
method json-all-set {...}

my $warnings-reported;

submethod TWEAK(:$!json-lazy-config = Nil) {
    unless $warnings-reported {
        self.json-class.^json-report-warnings(self.json-config);
        $warnings-reported := True;
    }
}

method json-create(*%profile) {
    (self.HOW ~~ JSON::Class::HOW::JSONified ?? self.^json-FROM !! self.WHAT).new: |%profile
}

method json-config-class is raw { JSON::Class::Config }

method json-config {
    $*JSON-CLASS-CONFIG
        // self.json-config-context: :config(self.json-config-class.global), |self.json-config-defaults, { $^config }
}

method json-guess-serializer(Str:D $kind, JSON::Class::Descriptor:D $descr, Mu \value --> Code) {
    my Mu \value-type = value.WHAT;
    my $serializer :=
        $descr.serializer($kind) // self.json-config.helper(value-type, $descr.kind-stage(JSSerialize, $kind));

    if $serializer ~~ Str:D {
        return $_ with value-type.^find_method($serializer);
        my $hint =
            ($_ ?? "to serialize " ~ $_ ~ " " !! "")
                ~ "as required by '" ~ $kind ~ "' serializer"
            given $descr.name;
        JSON::Class::X::NoMethod.new( :type(value-type), :method-name($serializer), :$hint ).throw
    }

    $serializer // Nil
}

method json-guess-deserializer(Str:D $kind, JSON::Class::Descriptor:D $descr) is raw {
    my Mu \value-type = $descr.kind-type($kind);
    my $deserializer :=
        $descr.deserializer($kind) // self.json-config.helper(value-type, $descr.kind-stage(JSDeserialize, $kind));

    if $deserializer ~~ Str:D {
        return $_ with value-type.^find_method($deserializer);
        my $hint = $_ ?? "to deserilize " ~ $_ ~ "." !! "" given $descr.name;
        JSON::Class::X::NoMethod.new( :type(value-type), :method-name($deserializer), :$hint ).throw
    }

    $deserializer // Nil
}

method json-helper(Mu $type is raw, Str:D $stage) {
    my $config = self.json-config;
    my $helper = $config.helper($type, $stage);

    if $helper ~~ Str:D {
        return $_ with $type.^find_method($helper);
        JSON::Class::X::NoMethod.new( :$type, :method-name($helper), :hint("needed for '$stage' stage") ).throw
    }

    $helper
}

my sub try-user-code(&code, Capture:D \args, &fallback --> Mu) is raw {
    my Mu $rc;
    my $use-fallback := True;

    if &code.cando(args) {
        $use-fallback := False;
        CATCH {
            default {
                $rc := .Failure;
            }
        }
        CONTROL {
            when JSON::Class::CX::Cannot {
                $use-fallback := True;
            }
            default { .rethrow }
        }
        $rc := &code(|args);
    }

    $use-fallback ?? &fallback() !! $rc
}

proto method json-try-serializer(|) {*}

multi method json-try-serializer(&serializer, Capture:D \serializer-args, &fallback --> Mu) is raw {
    try-user-code(&serializer, serializer-args, &fallback)
}

multi method json-try-serializer( ::?CLASS:D:
                                  Str:D $kind,
                                  JSON::Class::Descriptor:D $descr,
                                  Mu \value,
                                  &fallback
                                  --> Mu )
    is raw
{
    my $*JSON-CLASS-DESCRIPTOR := $descr;
    with self.json-guess-serializer($kind, $descr, value) -> &serializer {
        return try-user-code(&serializer, \(value), &fallback)
    }

    &fallback()
}

proto method json-try-deserializer(|) {*}

multi method json-try-deserializer(&deserializer, Mu \from-value, &fallback --> Mu) is raw {
    try-user-code &deserializer, \(from-value), &fallback
}

multi method json-try-deserializer(Str:D $kind, JSON::Class::Descriptor:D $descr, Mu \from-value, &fallback --> Mu) {
    my $*JSON-CLASS-DESCRIPTOR := $descr;
    with self.json-guess-deserializer($kind, $descr) -> &deserializer {
        my \args =
            &deserializer ~~ Method ?? \(nominalize-type($descr.kind-type($kind)), from-value) !! \(from-value);
        return try-user-code(&deserializer, args, &fallback)
    }

    &fallback()
}

proto method json-deserialize-value(Mu, Mu) {*}

multi method json-deserialize-value( Mu \dest-type,
                                     Mu:D \from-value,
                                     JSON::Class::Config :$config is copy,
                                     --> Mu )
    is raw
{
    return from-value if from-value ~~ dest-type;

    my proto sub j2v(| --> Mu) {*}

    multi sub j2v(JSON::Class::Jsonish \final-type, \value --> Mu) is raw is default {
        final-type.json-deserialize(value, :$config)
    }

    multi sub j2v(Positional \final-type, \value) is raw {
        my Mu \of-type = $config.type-from(final-type.of);
        value.map(-> \item-val {
            item-val ~~ of-type ?? item-val !! j2v(of-type, item-val)
        }).eager
    }

    multi sub j2v(Associative \final-type, \value) is raw {
        my Mu \of-type = $config.type-from(final-type.of);
        my Mu \keyof-type = $config.type-from(final-type.keyof);
        value.map({ j2v(keyof-type, .key) => j2v(of-type, .value) }).eager
    }

    multi sub j2v(Enumeration \final-type, \value --> Mu) is raw {
        $config.enums-as-value ?? final-type.(value) !! final-type.WHO{value}
    }

    multi sub j2v(JSONBasicType, Any:D \value) is raw is default { value }

    multi sub j2v(Mu \final-type, Any:D \value --> Mu) is raw {
        my &fallback = { $config.jsonify(final-type).json-deserialize(value, :$config) };
        with self.json-helper(final-type, 'from-json') {
            return self.json-try-deserializer($_, value)
        }
        &fallback()
    }

    $config //= self.json-config;

    j2v( $config.type-from(dest-type), from-value )
}

multi method json-deserialize-value(Mu \dest-type, Any:U, JSON::Class::Config :$config ) is raw {
    ($config // self.json-config).type-from(dest-type)
}

multi method json-deserialize-value(Mu \dest-type, Nil, JSON::Class::Config :$config) is raw {
    ($config // self.json-config).type-from(dest-type)
}

proto method json-serialize-value(|) {*}

multi method json-serialize-value(Mu \value, *%c) {
    self.json-serialize-value(value.WHAT, value, |%c)
}

multi method json-serialize-value(Mu, Mu:U \value) is raw { Nil }

multi method json-serialize-value(Mu, JSON::Class::Jsonish:D \value, JSON::Class::Config :$config) is default is raw {
    value.json-serialize(config => ($config //self.json-config))
}

multi method json-serialize-value(Enumeration, Enumeration:D \evalue, JSON::Class::Config :$config) {
    ($config // self.json-config).enums-as-value ?? evalue.value !! evalue.key
}

multi method json-serialize-value(Positional, \list, *%c) {
    my Mu \of-type = nominalize-type(list.of);
    list.map({ self.json-serialize-value(of-type, $_, |%c) }).eager.Array
}

multi method json-serialize-value(Associative, \hash, *%c) {
    my Mu \of-type = nominalize-type(hash.of);
    my Mu \keyof-type = nominalize-type(hash.keyof);

    hash.pairs.map({
        self.json-serialize-value(keyof-type, .key, |%c)
            => self.json-serialize-value(of-type, .value, |%c)
    }).eager.Hash
}

multi method json-serialize-value(Mu, JSONBasicType \value) { value }

multi method json-serialize-value(Mu, Mu:D \value, JSON::Class::Config :$config = self.json-config, *%c) is raw {
    my &fallback = {
        $config.jsonify(value).json-serialize(:$config)
    };
    with self.json-helper(value.WHAT, 'to-json') {
        return self.json-try-serializer($_, \(value), &fallback)
    }
    &fallback()
}

proto method json-deserialize(|) {*}

multi method json-deserialize($from) {
    JSON::Class::X::Deserialize::Impossible.new(
        :type(self), :why("don't know how to do it from " ~ type-or-instance($from))
    ).throw
}

method json-lazy-deserialize-context(&code, :&finalize --> Mu) is raw {
    my $*JSON-CLASS-CONFIG = $!json-lazy-config;
    LEAVE {
        if self.json-all-set {
            &finalize() if &finalize;
            $!json-lazy-config = Nil;
        }
    }
    &code()
}

proto method json-config-context(|) {*}

multi method json-config-context(&code, JSON::Class::Config:D :$config, *%twiddles) is raw {
    &code( my $*JSON-CLASS-CONFIG := %twiddles ?? $config.clone(|%twiddles) !! $config )
}

multi method json-config-context(&code, :$config, *%twiddles) is raw {
    my %config = $config.Hash;
    my %defaults = %config ?? Empty !! self.json-config-defaults;
    my JSON::Class::Config:D $json-config :=
        ($*JSON-CLASS-CONFIG
            andthen (%config || %twiddles ??  .clone(|%config, |%twiddles) !! $_)
            orelse (%config
                ?? self.json-config-class.new(|%config, |%twiddles)
                !! ( (%twiddles || %defaults)
                        ?? self.json-config-class.global.dup(|%defaults, |%twiddles)
                        !! self.json-config-class.global )));
    {
        my $*JSON-CLASS-CONFIG := $json-config;
        &code($json-config)
    }
}

my subset AssocOrPos of Any
    will complain { "method 'from-json' expects either a JSON, hash, or list, not " ~ type-or-instance($_) }
    where Associative:D | Positional:D;

proto method from-json(|) {*}

multi method from-json( Str:D $json,
                        :config($user-config),
                        *%twiddles ( Bool :allow-jsonc($), Bool :enums-as-value($), *%extra ) )
{
    verify-named-args(:%extra, :what("method 'from-json'"), :source(self.^name));
    self.json-config-context: :config($user-config), |%twiddles, -> $config {
        self.json-deserialize($config.from-json($json), :$config);
    }
}

multi method from-json( AssocOrPos $from is raw,
                        :config($user-config) is raw,
                        *%twiddles ( Bool :allow-jsonc($), *%extra ) )
{
    verify-named-args(:%extra, :what("method 'from-json'"), :source(self.^name));
    self.json-config-context: :config($user-config), |%twiddles, -> $config {
        self.json-deserialize($from, :$config)
    }
}

proto method to-json(|) {*}

multi method to-json(::?CLASS:U) { "null" }

multi method to-json( ::?CLASS:D:
                      :config($user-config),
                      Bool :$raw,
                      *%twiddles ( Bool :pretty($),
                                   Bool :sorted-keys($),
                                   Bool :enums-as-value($),
                                   UInt :spacing($),
                                   *%extra ))
{
    verify-named-args(:%extra, :what("method 'to-json'"), :source(self.^name));
    self.json-config-context: :config($user-config), |%twiddles, -> $config {
        return self.json-serialize(:$config) if $raw;

        $config.to-json: self.json-serialize(:$config)
    }
}