use v6.e.PREVIEW;
unit role JSON::Class::Attr:ver($?DISTRIBUTION.meta<ver>):auth($?DISTRIBUTION.meta<auth>):api($?DISTRIBUTION.meta<api>);

use AttrX::Mooish;
use AttrX::Mooish::Attribute;

use JSON::Class::Attr::Jsonish;
use JSON::Class::Descriptor;
use JSON::Class::Jsonish;
use JSON::Class::Types;
use JSON::Class::Utils;
use JSON::Class::X;

also does JSON::Class::Descriptor;
also does JSON::Class::Attr::Jsonish;

has Attribute:D $.attr handles <type name has_accessor is_built get_value package> is required;

has Bool $.skip;
has Bool $!skip-null is built;

# What name to use as JSON key
has Str:D $.json-name is mooish(:lazy, :predicate);

has Bool $.lazy is mooish(:lazy, :predicate);
has JSONHelper $.build; # Either method name or a Code object

has Mu $.value-type is mooish(:lazy, :no-init);
has Mu $.nominal-type is mooish(:lazy, :no-init);

method build-value-type {...}
method set-serializer {...}
method set-deserializer {...}

submethod TWEAK(:to-json(:$serializer), :from-json(:$deserializer)) {
    with $serializer {
        self.set-serializer( | .List.Capture );
    }
    with $deserializer {
        self.set-deserializer( | .List.Capture );
    }
}

method build-json-name { $!attr.name.substr(2) }

method build-nominal-type is raw {
    my \vtype = self.value-type;
    vtype.^archetypes.nominalizable ?? vtype.^nominalize !! vtype
}

method build-lazy(::?CLASS:D:) {
    return False if $!attr.build.DEFINITE || $!attr.container_descriptor.default.DEFINITE;
    my $declarant-lazy = self.declarant.^json-is-lazy;

    # If declarant mode is set explicitly, then use it indisputably.
    return $declarant-lazy if self.declarant.^json-has-lazy;

    my \attr-type = nominalize-type($!attr.type);
    ? ($declarant-lazy && (attr-type ~~ JSON::Class::Jsonish || !(attr-type ~~ JSONBasicType | Map | List)))
}

# JSON::Class::ClassHOW replaces descriptors with clones bound to attributes from the class itself. These will already
# have been instantiated.
multi method INSTANTIATE-GENERIC(::?CLASS:D: TypeEnv) { self }

method sigil { $!attr.name.substr(0,1) }

method skip-null is raw {
    $!skip-null // self.declarant.^json-skip-null
}

method !install-clearer(Mu \obj, JSONCoreHelper $clearer --> Nil) {
    my $cname = $clearer ~~ Str ?? $clearer !! 'json-clear-' ~ $.json-name;
    my $attr-name := $!attr.name;
    my \meth = anon method () is hidden-from-backtrace {
        self.json-clear-attr($attr-name)
    }
    meth.set_name($cname);
    obj.^add_method($cname, meth);
}

method mooify(::?CLASS:D: Mu \obj, JSONCoreHelper :$clearer, JSONCoreHelper :$predicate, :$aliases) {
    JSON::Class::X::ReMooify.new(:$!attr, :type(obj)).throw if $.attr ~~ AttrX::Mooish::Attribute;
    my $*PACKAGE := obj;
    my @profile;
    if $.lazy {
        @profile.push: "lazy" => 'json-build-attr';
        if $predicate {
            @profile.push: "predicate" => $predicate ~~ Str ?? $predicate !! 'json-has-' ~ $.json-name;
        }
        self!install-clearer(obj, $clearer) if $clearer;
    }
    if $aliases {
        @profile.append: (:$aliases);
    }
    return unless @profile;
    &trait_mod:<is>($!attr, :mooish(@profile));
}

# Preserve critical attributes.
method clone(*%twiddles) is raw {
    %twiddles<lazy> //= $!lazy if self.has-lazy;
    %twiddles<json-name> //= $!json-name if self.has-json-name;
    ::?CLASS.^post-clone: self, callwith(|%twiddles), %twiddles
}

multi method kind-type('attribute') is pure { $!attr.type }