use v6.e.PREVIEW;
unit role JSON::Class::HOW::AttributeContainer:ver($?DISTRIBUTION.meta<ver>):auth($?DISTRIBUTION.meta<auth>):api($?DISTRIBUTION.meta<api>);

# use experimental :will-complain;

use AttrX::Mooish;

use JSON::Class::Attr;
use JSON::Class::Attr::Associative;
use JSON::Class::Attr::Jsonish;
use JSON::Class::Attr::Positional;
use JSON::Class::Attr::Scalar;
use JSON::Class::HOW::Laziness;
use JSON::Class::Internals;
use JSON::Class::Utils;

also does JSON::Class::HOW::Laziness;

# Local attributes which are to de-/serialized
has $!json-attrs;
# All serializable attributes, including parent classes
has $!json-attr-lookup;
# Local serializable attribute desriptors by their JSON names
has $!json-local-keys;
# All serializable attributes by their JSON names
has $!json-mro-keys;
# A Set of JSON key names of all JSON attributes of this class
has $!json-mro-key-set;
# If this type object wants undefined attributes to be skipped from serialization
has $!json-skip-null;

method json-attr-register(Mu, JSON::Class::Attr::Jsonish:D $json-attr) {
    $!json-attrs := (|($!json-attrs // ()), $json-attr.name => $json-attr).Map;
    $!json-attr-lookup := Nil;
    $!json-local-keys := Nil;
    $!json-mro-keys := Nil;
    $!json-mro-key-set := Nil;
}

my sub hash-by-adv( Associative:D \registry, %adv, Str:D :$what, Str:D :$source) {
    verify-named-args(%adv, :unique<p k kv v>, :$what, :$source, :offset(1));

    %adv<p> ?? .pairs
            !! %adv<k> ?? .keys
                       !! %adv<kv> ?? .kv
                                   !! .values
        given registry
}

method json-set-skip-null(Mu \obj, Bool $skip-null) { $!json-skip-null := $skip-null<>; }

method json-skip-null(Mu) is raw { $!json-skip-null }

method json-attrs(Mu \obj, Bool:D :$local = True, *%adv (Bool :$p, Bool :$k, Bool :$kv, Bool :$v)) is raw {
    my $attr-registry :=
        $local
            ?? ($!json-attrs // Map.new)
            !! ($!json-attr-lookup
                // ($!json-attr-lookup :=
                    obj.^mro.grep({ .HOW ~~ ::?ROLE }).reverse.map(*.^json-attrs(:local, :p)).Map));

    # Return the hash itself unless an true adverb is passed in.
    return $attr-registry unless any %adv.values;

    hash-by-adv($attr-registry, %adv, :what('method ^json-attrs'), :source(obj.^name))
}

method json-attrs-by-key(Mu \obj, Bool:D :$local, *%adv (Bool :$p, Bool :$k, Bool :$kv, Bool :$v)) is raw {
    my $attr-registry;
    if $local {
        $attr-registry :=
            $!json-local-keys
            // ($!json-local-keys := $!json-attrs.values.map({ next if .skip; .json-name => $_ }).Map);
    }
    else {
        $attr-registry :=
            $!json-mro-keys
            // ($!json-mro-keys := self.json-attrs(obj, :!local, :v).map({ next if .skip; .json-name => $_ }).Map);
    }

    return $attr-registry unless any %adv.values;

    hash-by-adv($attr-registry, %adv, :what("method ^json-attrs-by-key"), :source(obj.^name))
}

method json-get-attr(Mu \obj, $attr where Str:D | Attribute:D, Bool:D :$local = True) {
    self.json-attrs(obj, :$local).AT-KEY( $attr ~~ Str:D ?? $attr !! $attr.name ) // Nil
}

method json-has-attr(Mu \obj, $attr where Str:D | Attribute:D, Bool:D :$local = True) {
    self.json-attrs(obj, :$local).EXISTS-KEY( $attr ~~ Str:D ?? $attr !! $attr.name )
}

method json-has-key(Mu \obj, Str:D $json-name, Bool:D :$local = True) {
    ( ($local ?? $!json-local-keys !! $!json-mro-keys)
        // self.json-attrs-by-key(obj, :$local) ).EXISTS-KEY($json-name)
}

method json-get-key(Mu \obj, Str:D $json-name, Bool:D :$local = True) {
    ( ($local ?? $!json-local-keys !! $!json-mro-keys)
        // self.json-attrs-by-key(obj, :$local) ).AT-KEY($json-name) // Nil
}

method json-mro-key-set(Mu \obj) is raw {
    $!json-mro-key-set // ($!json-mro-key-set := self.json-attrs-by-key(obj, :!local, :k).Set)
}

my constant ATTR-TYPES = ( '$' => JSON::Class::Attr::Scalar,
                           '&' => JSON::Class::Attr::Scalar,
                           '%' => JSON::Class::Attr::Associative,
                           '@' => JSON::Class::Attr::Positional ).Map;

my subset SerializerKind of Any where Str:D | Code:D | Any:U;

method jsonify-attribute( Mu \pkg,
                          Attribute:D $attr,
                          *%adv ( Bool :skip($),
                                  Bool :skip-null($),
                                  Str :name($),
                                  Bool :lazy($),
                                  :$serializer, # (SerializerKind $?, *% where *.values.all ~~ SerializerKind),
                                  :$deserializer, # (SerializerKind $?, *% where *.values.all ~~ SerializerKind),
                                  *%extra ))
{
    my @details;

    for <serializer deserializer> -> $kind {
        my @d;

        my sub verify-serializer(*@pos, *%named) {
            if @pos > 1 {
                @d.push: "expects only one optional positional argument, got " ~ +@pos;
            }
            for @pos.head, |%named.values -> \value {
                @d.push: "must be defined by a method name or a code object, but got "
                            ~ (is-basic-type(value) ?? value.raku !! type-or-instance(value))
                    unless value ~~ SerializerKind;
            }
        }

        verify-serializer(|%adv{$kind}.List.Capture);

        if @d {
            @details.append: @d.map("':$kind' " ~ *);
        }
    }

    if @details {
        JSON::Class::X::Trait::Argument.new(
            :trait-name($*JSON-CLASS-TRAIT // 'json'),
            :@details,
            :singular(%adv < 2) ).throw
    }

    verify-named-args( %adv, :unique<skip lazy>, :%extra,
                        :what("trait 'json' for attribute " ~ $attr.name),
                        :source(pkg.^name) );

    %adv<json-name> = $_ with %adv<name>:delete;

    my $sigil = $attr.name.substr(0,1);

    my $json-attr = ATTR-TYPES.{$sigil}.new(:$attr, :declarant(pkg), |%adv);
    self.json-attr-register: pkg, $json-attr;
    $json-attr.lazify(pkg) if $json-attr.lazy;
}