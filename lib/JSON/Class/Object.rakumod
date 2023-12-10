use v6.e.PREVIEW;
unit class JSON::Class::Object:ver($?DISTRIBUTION.meta<ver>):auth($?DISTRIBUTION.meta<auth>):api($?DISTRIBUTION.meta<api>);

use AttrX::Mooish;

use JSON::Class::Attr::Associative;
use JSON::Class::Attr::Positional;
use JSON::Class::Attr::Scalar;
use JSON::Class::Common;
use JSON::Class::Types;
use JSON::Class::Utils;

also does JSON::Class::Common;
also does JSON::Class::Types::CloneFrom;

has $!json-unused;

# For lazies this is a hash with unclaimed yet keys.
has $!json-lazies;
has $!json-lazies-lock = Lock.new;

submethod TWEAK( Associative :$!json-unused, Associative :$!json-lazies ) {}

method clone(*%twiddles) {
    my %profile;
    for self.json-class.^json-attrs(:!local) -> JSON::Class::Attr:D $json-attr {
        my Attribute:D $attr = $json-attr.attr;
        if $attr ~~ AttrX::Mooish::Attribute && $attr.is-set(self) {
            %profile{$attr.base-name} := $attr.get_value(self);
        }
        %profile<json-lazies> := self.json-lazies; # The method returns a clone and is thread-safe
        callwith(|%profile, |%twiddles)
    }
}

method json-unused(::?CLASS:D:) { $!json-unused }
method json-lazies(::?CLASS:D:) {
    $!json-lazies-lock.protect: {
        $!json-lazies.clone
    }
}

method json-all-set(::?CLASS:D:) {
    $!json-lazies-lock.protect: {
        ! $!json-lazies
    }
}

proto method json-serialize-attr(::?CLASS:D: JSON::Class::Attr:D, Mu, |) {*}
multi method json-serialize-attr(::?CLASS:D: JSON::Class::Attr::Scalar:D $json-attr, Mu \value) {
    self.json-try-serializer:
        'attribute', $json-attr, value,
        { self.json-serialize-value($json-attr.nominal-type, value) }
}
multi method json-serialize-attr(::?CLASS:D: JSON::Class::Attr::Positional:D $json-attr, Mu \value) {
    self.json-try-serializer:
        'attribute', $json-attr, value,
        {
            value.map(-> Mu \item {
                self.json-try-serializer:
                    'value', $json-attr, item,
                    { self.json-serialize-value($json-attr.nominal-type, item) }
                }).eager.Array
        }
}
multi method json-serialize-attr(::?CLASS:D: JSON::Class::Attr::Associative:D $json-attr, Mu \value) {
    self.json-try-serializer:
        'attribute', $json-attr, value,
        {
            value.map(-> (Mu :$key is raw, Mu :$value is raw) {
                self.json-try-serializer( 'key', $json-attr, $key,
                                          { self.json-serialize-value($json-attr.nominal-keytype, $key) })
                    => self.json-try-serializer( 'value', $json-attr, $value,
                                                 { self.json-serialize-value($json-attr.nominal-type, $value) } )
            }).eager.Hash
        }
}

method json-serialize(::?CLASS:D: JSON::Class::Config :$config is copy) is raw {
    my $*JSON-CLASS-SELF := self;
    $config //= self.json-config;
    my $skip-null = $config.skip-null;
    my @profile = |(.pairs with $!json-unused);
    for self.json-class.^json-attrs(:!local, :v).grep(!*.skip) -> JSON::Class::Attr:D $json-attr {
        my $*JSON-CLASS-DESCRIPTOR := $json-attr;
        my \value = self.json-serialize-attr($json-attr, $json-attr.get_value(self));
        if value.DEFINITE || !($json-attr.skip-null // $skip-null) {
            @profile.push: $json-attr.json-name => value;
        }
    }
    @profile.Hash
}

method !json-lazy(JSON::Class::Attr:D $json-attr) is raw {
    $!json-lazies-lock.protect: {
        ($!json-lazies
            andthen (.EXISTS-KEY(my $key = $json-attr.name)
                        ?? .DELETE-KEY($key)
                        !! Nil)) // Nil
    }
}

method !json-has-lazy(JSON::Class::Attr:D $json-attr) is raw {
    $!json-lazies-lock.protect: {
        ? ($!json-lazies andthen .EXISTS-KEY(my $key = $json-attr.name))
    }
}

method !json-use-builder(JSON::Class::Attr:D $descr --> Mu) is raw {
    $descr.build
        andthen (do {
            when Str:D {
                return self."$_"($descr)
            }
            when Code:D {
                return $_.($descr)
            }
        })
        orelse ($descr ~~ JSON::Class::Attr::Scalar ?? Nil !! Empty)
}

method json-build-attr(::?CLASS:D: Str:D :$attribute! --> Mu) is raw {
    self.json-lazy-deserialize-context:
        {
            given self.json-class.^json-get-attr($attribute) {
                self!json-has-lazy($_)
                    ?? self.json-deserialize-attr($_)
                    !! self!json-use-builder($_)
            }
        },
        finalize => { $!json-lazies-lock.protect: { $!json-lazies := Nil; } }
}

proto method json-deserialize-attr(|) {*}

multi method json-deserialize-attr(::?CLASS:D: JSON::Class::Attr::Positional:D $json-attr --> Mu) is raw {
    self!json-lazy($json-attr) andthen self.json-deserialize-attr($json-attr, $_)
}

multi method json-deserialize-attr(JSON::Class::Attr::Positional:D $json-attr, Mu \value --> Mu ) is raw {
    my $config = self.json-config;
    self.json-try-deserializer:
        'attribute', $json-attr, value,
        {
            $json-attr.jsonish
                ?? self.json-deserialize-value($json-attr.type, value)
                !! value.List.map(
                    -> \item {
                        self.json-try-deserializer:
                            'value', $json-attr, item,
                            { self.json-deserialize-value($json-attr.value-type, item, :$config) }
                    }).eager
        }
}

multi method json-deserialize-attr(::?CLASS:D: JSON::Class::Attr::Associative:D $json-attr --> Mu) is raw {
    self!json-lazy($json-attr) andthen self.json-deserialize-attr($json-attr, $_)
}

multi method json-deserialize-attr(JSON::Class::Attr::Associative:D $json-attr, Mu \value --> Mu) is raw {
    my $config = self.json-config;
    self.json-try-deserializer:
        'attribute', $json-attr, value,
        {
            $json-attr.jsonish
                ?? self.json-deserialize-value($json-attr.type, value)
                !! value.pairs.map(
                    -> (:$key is raw, :$value is raw) {
                        self.json-try-deserializer('key', $json-attr, $key, { $key }) =>
                            self.json-try-deserializer(
                                'value', $json-attr, $value,
                                { self.json-deserialize-value($json-attr.value-type, $value, :$config) } )
                    }).eager
        }
}

multi method json-deserialize-attr(::?CLASS:D: JSON::Class::Attr::Scalar:D $json-attr --> Mu) is raw {
    self!json-lazy($json-attr) andthen self.json-deserialize-attr($json-attr, $_) orelse Nil
}

multi method json-deserialize-attr(JSON::Class::Attr::Scalar:D $json-attr, Mu \value --> Mu) is raw {
    self.json-try-deserializer:
        'attribute', $json-attr, value,
        { self.json-deserialize-value($json-attr.value-type, value) }
}

multi method json-deserialize(%from, JSON::Class::Config :$config is copy) {
    my $*JSON-CLASS-SELF := self;
    $config //= self.json-config;
    my \json-class = self.json-class;
    my $lazy-class = json-class.^json-is-lazy;
    my $force-eager = $config.eager;
    my %profile;
    my %lazies;
    my %*JSON-CLASS-PROFILE := %profile;

    for %from.keys -> $json-name {
        my \from-value = %from{$json-name}<>;

        with json-class.^json-get-key($json-name, :!local) -> JSON::Class::Attr:D $json-attr {
            my $attr-name = $json-attr.name;
            if !$force-eager && $json-attr.lazy {
                %lazies{$attr-name} := from-value;
            }
            else {
                %profile{$attr-name.substr(2)} :=
                    self.json-deserialize-attr($json-attr, from-value);
            }
        }
        else {
            $config.alert: JSON::Class::X::Deserialize::NoAttribute.new(:json-key($json-name), :type(self.WHAT));
            %profile<json-unused>{$json-name} := from-value;
        }
    }

    %profile<json-lazies> := %lazies;
    %profile<json-lazy-config> := $config if %lazies;

    $config.type-from(self.WHAT, :nominal).json-create: |%profile
}

multi method json-deserialize(@from, JSON::Class::Config :$config) {
    my $*JSON-CLASS-SELF := self;
    @from.map({ self.json-deserialize($_, :$config) }).Array
}