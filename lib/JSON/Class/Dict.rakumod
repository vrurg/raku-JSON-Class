use v6.e.PREVIEW;
unit class JSON::Class::Dict:ver($?DISTRIBUTION.meta<ver>):auth($?DISTRIBUTION.meta<auth>):api($?DISTRIBUTION.meta<api>);

use JSON::Class::Collection;
use JSON::Class::Common;
use JSON::Class::Config;
use JSON::Class::Jsonish;
use JSON::Class::ItemDescriptor;
use JSON::Class::Types :DEFAULT;
use JSON::Class::Utils;
use JSON::Class::Types :NOT-SET;

also does Associative;
also does Iterable;
also does JSON::Class::Collection;
also does JSON::Class::Common;
also does JSON::Class::Types::CloneFrom;

has $!json-raw;
# Deserialized or user-installed
has $!json-items;
# For non-Str keyof this is where we hold deserialized keys.
# We're trying to preserve the key objects which were used to store data in first place. User-side key objects provided
# to obtain info/value from the Dict are tend to be ignored.
has $!json-keys;

my class EmptyRaw is Nil {
    method new { self.WHAT }
    method Bool { False }
    method EXISTS-KEY(| --> False) {}
    method keys(--> Empty) {}
    method elems(--> 0) {}
    method FALLBACK($name, |c) {
        die "Method '$name' is not allowed for empty raw storage"
    }
}

multi method new(*%profile) { self.bless(|%profile) }
multi method new(::?CLASS:D $from, *%profile) {
    self.bless(|%profile)!STORE-FROM-ITERATOR($from.iterator)
}
multi method new(*@items, *%profile) {
    self.bless(|%profile)!STORE-FROM-ITERATOR(@items.iterator)
}

my role Coercive {
    my &assign-thunk = ::?CLASS.json-class.^json-compose-assign-thunk;
    multi method ASSIGN-KEY(::?CLASS:D: Mu \key, Mu \value, |c --> Mu) is raw {
        nextwith(key, &assign-thunk(value), |c)
    }
}

submethod TWEAK(:%json-raw) {
    $!json-raw := %json-raw;
    $!json-items := self.json-new-dict-hash;
    if self.json-class.^json-has-coercions {
        self does Coercive;
    }
    given self.json-key-descriptor {
        # In the most simple case of string keys with no marshallers we may skip mapping from JSON keys into the
        # sequence keys.
        my \typeobj = .type<>;
        $!json-keys := self.json-new-key-hash;
            # !(typeobj ~~ Str && typeobj.^archetypes.definite) || .has-serializer("item") || .has-deserializer("item")
            #     ?? self.json-new-key-hash
            #     !! Nil;
    }
}

method !STORE-FROM-ITERATOR(Iterator \iter) is hidden-from-backtrace {
    my Mu $last := NOT-SET;

    my $found = 0;

    until (my Mu $item := iter.pull-one) =:= IterationEnd {
        ++$found;

        my proto sub add-item(|) {*}
        multi sub add-item(Pair:D $ (Mu :$key is raw, Mu :$value is raw)) is hidden-from-backtrace {
            self.ASSIGN-KEY($key, $value);
        }
        multi sub add-item(Mu \key, Mu \value) is hidden-from-backtrace {
            self.ASSIGN-KEY(key, value);
            $last := NOT-SET;
        }
        multi sub add-item(Mu \item) is hidden-from-backtrace {
            $last := item;
        }

        if $last =:= NOT-SET {
            add-item($item);
        }
        else {
            add-item($last, $item);
        }
    }

    unless $last =:= NOT-SET {
        X::Hash::Store::OddNumber.new(:$found, :$last).throw
    }

    self
}

proto method STORE(|) {*}
multi method STORE(::?CLASS:U \SELF: |c) {
    self!json-vivify-self(SELF).STORE(|c)
}
multi method STORE(::?CLASS:D: ::?CLASS:D $from) is hidden-from-backtrace {
    self.CLEAR;
    self!STORE-FROM-ITERATOR($from.iterator)
}
multi method STORE(::?CLASS:D: Iterable:D \values) is hidden-from-backtrace {
    self.CLEAR;
    self!STORE-FROM-ITERATOR(values.iterator)
}
multi method STORE(::?CLASS:D: *@values) is hidden-from-backtrace {
    self.CLEAR;
    self!STORE-FROM-ITERATOR(@values.iterator);
}

method json-all-set {
    !$!json-raw.elems
}

multi method json-guess-descriptor(:$json-value! is raw, Mu :$key --> JSON::Class::ItemDescriptor:D) is raw {
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

    self.json-only-single-descriptor: @cands, JSON::Class::X::Deserialize::DictItem, $json-value, :$key
}

method json-serialize(::?CLASS:D:) is raw {
    my $*JSON-CLASS-SELF := self;
    my $iter = self.iterator;

    (do loop {
        last if (my $item := $iter.pull-one) =:= IterationEnd;

        my $*JSON-CLASS-DESCRIPTOR :=
        my JSON::Class::ItemDescriptor:D $descr = self.json-guess-descriptor(item-value => $item.value);
        self.json-serialize-item($descr, $item)
    }).Hash
}

multi method json-deserialize(%from, JSON::Class::Config :$config is copy) {
    my $*JSON-CLASS-SELF := self;
    $config //= self.json-config;
    my \dict-class = $config.type-from(self.WHAT);

    # Sequence is always lazy. Otherwise it makes more sense to have an array.
    dict-class.json-create:
        json-raw => %from,
        json-lazy-config => $config
}

proto method json-key2str(Mu, Mu --> Str:D) {*}
multi method json-key2str(Str \key-type, Str:D \key) { key }
multi method json-key2str(Mu \key-type, Mu \key) {
    self.json-config.to-json: self.json-serialize-value(key-type, key), :!pretty, :sorted-keys
}

method json-serialize-dict-key(::?CLASS:D: Mu \key, Bool :$store) {
    my $descr = self.json-key-descriptor;
    my $json-key := self.json-try-serializer: 'item', $descr, key, { self.json-key2str($descr.type, key) };
    $!json-keys.ASSIGN-KEY($json-key, key) if $store;
    $json-key
}

proto method json-str2key(|) {*}
multi method json-str2key(Str:D $json-key, JSON::Class::Jsonish \key-type --> Mu) is raw {
    key-type.from-json($json-key)
}
multi method json-str2key(Str:D $json-key, ::T Mu \key-type --> T) { my T() $ = $json-key }

method json-serialize-dict-value(::?CLASS:D: JSON::Class::ItemDescriptor:D $descr, Mu \value) {
    self.json-try-serializer: 'item', $descr, value, { self.json-serialize-value: $descr.nominal-type, value }
}

method json-serialize-item(::?CLASS:D: JSON::Class::ItemDescriptor:D $descr, Pair:D $pair) {
    Pair.new:
        self.json-serialize-dict-key($pair.key),
        self.json-serialize-dict-value($descr, $pair.value)
}

method json-deserialize-dict-key(::?CLASS::D: Str:D $key --> Mu) is raw {
    my $descr = self.json-key-descriptor;
    self.json-try-deserializer: 'item', $descr, $key,
                                {
                                    my \dtype = $descr.type;
                                    self.json-str2key: $key,
                                                       is-a-class-type(dtype)
                                                            ?? self.json-config.jsonify(dtype)
                                                            !! dtype
                                }
}

method json-deserialize-dict-value(::?CLASS:D: JSON::Class::ItemDescriptor:D $descr, $json-value --> Mu) is raw {
    self.json-try-deserializer:
        'item', $descr, $json-value,
        { self.json-deserialize-value($descr.value-type, $json-value) }
}

method json-deserialize-item(::?CLASS:D: Mu $key is raw, $json-value is raw --> Mu) is raw {
    my Mu $rc;

    with $json-value {
        with self.json-guess-descriptor(:$json-value, :$key) -> JSON::Class::ItemDescriptor:D $descr {
            $rc := self.json-deserialize-dict-value($descr, $json-value);
        }
        else {
            $rc := JSON::Class::X::Deserialize::DictItem.new(
                        :type(self.WHAT), :$key, :what($json-value),
                        :why("cannot determine the target type, no matching descriptor found") ).Failure
        }
    }
    else {
        # Treat any undefined as Nil.
        $rc := Nil
    }

    $rc
}

method !json-delete-key-raw(::?CLASS:D: Str:D $json-key --> Mu) is raw {
    my $rc := Nil;
    with $!json-raw {
        $rc := .DELETE-KEY($json-key);
        $!json-raw := EmptyRaw unless $!json-raw.elems;
    }
    $rc
}

method !json-normalize(Str:D $json) {
    .to-json( .from-json($json), :!pretty, :sorted-keys ) given self.json-config
}

method json-key-object(::?CLASS:D: Str:D $json-key --> Mu) {
    return Nil unless self.json-exists-key($json-key);

    $!json-keys.EXISTS-KEY($json-key)
        ?? $!json-keys.AT-KEY($json-key)
        !! $!json-keys.ASSIGN-KEY($json-key, self.json-deserialize-dict-key($json-key))
}

method json-at-key(::?CLASS:D: Str:D $json-key, Bool :$p = False, Mu :$key is raw = NOT-SET --> Mu) is raw {
    my Mu \key = $key =:= NOT-SET ?? self.json-key-object($json-key) !! $key;

    my Mu \value =
        do if $!json-items.EXISTS-KEY($json-key) || !$!json-raw.EXISTS-KEY($json-key) {
            $!json-items.AT-KEY($json-key)
        }
        else {
            my Mu $json-value := self!json-delete-key-raw($json-key);

            self.json-lazy-deserialize-context: {
                $!json-keys.ASSIGN-KEY($json-key, key);
                $!json-items.ASSIGN-KEY: $json-key, self.json-deserialize-item(key, $json-value)
            }
        };


    $p ?? Pair.new(key, value) !! value
}

method json-delete-key(::?CLASS:D: Str:D $json-key --> Mu) is raw {
    self!json-delete-key-raw($json-key);
    $!json-keys.DELETE-KEY($json-key);
    $!json-items.DELETE-KEY($json-key)
}

method json-exists-key(::?CLASS:D: Str:D $json-key --> Mu) is raw {
    $!json-raw.EXISTS-KEY($json-key) || $!json-items.EXISTS-KEY($json-key)
}

method json-has-key(::?CLASS:D: Str:D $json-key --> Bool:D) is raw {
    $!json-items.EXISTS-KEY($json-key)
}

method json-assign-key( ::?CLASS:D:
                        Str:D $json-key,
                        Mu \value,
                        Mu :$key is raw = NOT-SET
                        --> Mu )
    is raw is hidden-from-backtrace
{
    $!json-keys.ASSIGN-KEY($json-key, $key) unless $key =:= NOT-SET;
    self!json-delete-key-raw($json-key);
    $!json-items.ASSIGN-KEY($json-key, value)
}

method json-append-or-push(::?CLASS:D: Iterable:D \values, Bool :$push) is raw {
    my $method = $push ?? "push" !! "append";

    self.throw-iterator-cannot-be-lazy('.' ~ $method) if values.is-lazy;

    my Mu $last := NOT-SET;
    my $iter := values.iterator;

    until (my $item := $iter.pull-one) =:= IterationEnd {
        my proto sub add-item(|) {*}
        multi sub add-item(Pair:D $ (Mu :$key is raw, Mu :$value is raw)) is hidden-from-backtrace {
            samewith($key, $value)
        }
        multi sub add-item(Mu $key is raw, Mu $value) is hidden-from-backtrace {
            my $json-key = self.json-serialize-dict-key($key);
            my \value = $value<>;

            if self.json-exists-key($json-key) {
                unless (my Mu $current := self.json-at-key($json-key, :$key)) ~~ Positional:D {
                    $current := Array.new($current);
                }
                # Indirect method call could work better with new-disp than a ternary or other conditional like
                # $push ?? $current.push(...) !! $current.append(...)
                self.json-assign-key: $json-key, $current."$method"(value), :$key;
            }
            else {
                self.json-assign-key($json-key, value, :$key);
            }

            $last := NOT-SET;
        }
        multi sub add-item(Mu \value) {
            $last := value;
        }

        if $last =:= NOT-SET {
            add-item($item);
        }
        else {
            add-item($last, $item);
        }
    }

    unless $last =:= NOT-SET {
        warn "Trailing item in {self.^name}.$method";
    }

    self
}

proto method AT-KEY(|) {*}
multi method AT-KEY(::?CLASS:U \SELF: Mu $key is raw --> Mu) is raw {
    self!json-vivify-self(SELF).AT-KEY($key)
}
multi method AT-KEY(::?CLASS:D: Mu $key is raw --> Mu) is raw {
    self.json-at-key: self.json-serialize-dict-key($key), :$key
}

proto method ASSIGN-KEY(|) {*}
multi method ASSIGN-KEY(::?CLASS:U \SELF: Mu $key is raw, Mu $value is raw) is raw {
    self!json-vivify-self(SELF).ASSIGN-KEY($key, $value)
}
multi method ASSIGN-KEY(::?CLASS:D: Mu $key is raw, Mu $value is raw) is raw {
    self.json-assign-key: self.json-serialize-dict-key($key), $value, :$key
}

proto method EXISTS-KEY(|) {*}
multi method EXISTS-KEY(::?CLASS:U: Mu --> False) {}
multi method EXISTS-KEY(::?CLASS:D: Mu \key) {
    self.json-exists-key: self.json-serialize-dict-key(key);
}

proto method HAS-KEY(::?CLASS:D: Mu) {*}
multi method HAS-KEY(::?CLASS:U: Mu --> False) {}
multi method HAS-KEY(::?CLASS:D: Mu \key is raw, Bool:D :$has = True) {
    ! ($!json-items.EXISTS-KEY(self.json-serialize-dict-key(key)) ^^ $has)
}
multi method HAS-KEY(::?CLASS::D: Iterable:D \keys, Bool:D :$has = True) {
    keys.map({ ! ($!json-items.EXISTS-KEY(self.json-serialize-dict-key($_)) ^^ $has) })
}

proto method DELETE-KEY(|) {*}
multi method DELETE-KEY(::?CLASS:U: Mu --> Nil) {}
multi method DELETE-KEY(::?CLASS:D: \key is raw --> Mu) {
    self.json-delete-key: self.json-serialize-dict-key(key);
}

proto method CLEAR() {*}
multi method CLEAR(::?CLASS:U: --> Nil) {}
multi method CLEAR(::?CLASS:D: --> Nil) {
    $!json-raw := EmptyRaw;
    .STORE(Empty) with $!json-keys;
    $!json-items := self.json-new-dict-hash;
}

multi method elems(::?CLASS:D:) {
    $!json-raw.elems + $!json-items.elems
}

multi method end(::?CLASS:D:) {
    $!json-raw.elems + $!json-items.elems - 1
}


my class DictIter does Iterator {
    has $!items-iter is built;
    has Mu $!raw is built;
    has $!dict is built;

    submethod TWEAK(:$items is raw) {
        $!items-iter := $items.keys.iterator;
    }

    method pull-one is raw {
        with $!items-iter {
            unless (my Mu $json-key := $!items-iter.pull-one) =:= IterationEnd {
                return $!dict.json-at-key($json-key, :p)
            }
            $!items-iter := Nil;
        }
        with $!raw {
            if .elems {
                return $!dict.json-at-key( .keys.head, :p )
            }
            else {
                $!raw := Nil;
            }
        }
        IterationEnd
    }

    method is-deterministic(--> False) {}
}

my class DictIter-Keys does Iterator {
    has $!items-iter;
    has $!raw-iter;
    has $!dict is built is required;

    submethod TWEAK(:$items, Mu :$raw) {
        $!items-iter := $items.keys.iterator;
        $!raw-iter := $raw.keys.iterator;
    }

    method pull-one is raw {
        with $!items-iter {
            unless (my $json-key := $!items-iter.pull-one) =:= IterationEnd {
                return $!dict.json-key-object($json-key);
            }
            $!items-iter := Nil;
        }
        with $!raw-iter {
            unless (my $json-key := $!raw-iter.pull-one) =:= IterationEnd {
                return $!dict.json-key-object($json-key)
            }
            $!raw-iter := Nil
        }
        IterationEnd
    }

    method is-deterministic(--> False) {}
}

my class DictIter-Values does Iterator {
    has $!items-iter;
    has Mu $!raw is built is required;
    has $!dict is built is required;

    submethod TWEAK(:$items) {
        $!items-iter := $items.values.iterator;
    }

    method pull-one is raw {
        with $!items-iter {
            unless (my Mu $rc := $!items-iter.pull-one) =:= IterationEnd {
                return $rc;
            }
            $!items-iter := Nil;
        }
        with $!raw {
            if .elems {
                return $!dict.json-at-key( .keys.head )
            }
            else {
                $!raw := Nil;
            }
        }
        IterationEnd
    }

    method is-deterministic(--> False) {}
}

my class DictIter-KV does Iterator {
    has $!items-iter;
    has Mu $!raw is built;
    has $!dict is built;
    has $!last-pair;
    has $!is-key;

    submethod TWEAK(:$items) {
        $!items-iter := $items.iterator;
    }

    method pull-one is raw {
        PULL:
        while $!items-iter.defined || $!raw.defined {
            with $!is-key {
                my $is-key = $!is-key;
                $!is-key = $!is-key ?? False !! Nil;
                return $is-key ?? $!last-pair.key !! $!last-pair.value
            }

            $!is-key = True;

            with $!items-iter {
                unless (my $items-pair := $!items-iter.pull-one) =:= IterationEnd {
                    $!last-pair := Pair.new: $!dict.json-key-object($items-pair.key), $items-pair.value;
                    next PULL;
                }
                $!items-iter := Nil;
            }

            with $!raw {
                if .elems {
                    $!last-pair := $!dict.json-at-key( .keys.head, :p );
                }
                else {
                    $!raw := EmptyRaw;
                }
            }
        }
        IterationEnd
    }

    method is-deterministic(--> False) {}
}

multi method iterator(::?CLASS:D:) {
    DictIter.new(:items($!json-items), :raw($!json-raw), :dict(self))
}

multi method pairs(::?CLASS:D:) {
    Seq.new(DictIter.new(:items($!json-items), :raw($!json-raw), :dict(self)))
}

multi method list(::?CLASS:D:) {
    Seq.new(DictIter.new(:items($!json-items), :raw($!json-raw), :dict(self))).List
}

multi method keys(::?CLASS:D:) {
    Seq.new(DictIter-Keys.new(:items($!json-items), :raw($!json-raw), :dict(self)))
}

multi method values(::?CLASS:D:) {
    Seq.new(DictIter-Values.new(:items($!json-items), :raw($!json-raw), :dict(self)))
}

multi method kv(::?CLASS:D:) {
    Seq.new(DictIter-KV.new(:items($!json-items), :raw($!json-raw), :dict(self)))
}

proto method append(|) {*}
multi method append(::?CLASS:U: |c) { self.new.append(|c) }
multi method append(::?CLASS:D: +values) {
    self.json-append-or-push(values)
}

proto method push(|) {*}
multi method push(::?CLASS:U: |c) { self.new.push(|c) }
multi method push(::?CLASS:D: +values) {
    self.json-append-or-push(values, :push)
}

multi method Hash(::?CLASS:D:) {
    Hash.^parameterize($!json-items.of, self.json-key-descriptor.type).new: self.pairs
}

multi method Str(::?CLASS:D:) { self.Hash.Str }
multi method gist(::?CLASS:D:) { self.Hash.gist }
multi method raku(::?CLASS:D:) {
    self.^name ~ ".new(" ~ self.pairs.map(*.raku).join(", ") ~ ")"
}