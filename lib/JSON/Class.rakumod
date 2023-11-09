use v6.e.PREVIEW;
unit module JSON::Class:ver($?DISTRIBUTION.meta<ver>):auth($?DISTRIBUTION.meta<auth>):api($?DISTRIBUTION.meta<api>);

use AttrX::Mooish:ver<1.0.5>;
use JSON::Fast;

use JSON::Class::ClassHOW;
use JSON::Class::Config;
use JSON::Class::DictHOW;
use JSON::Class::Dictionary;
use JSON::Class::HOW::Dictionary;
use JSON::Class::HOW::Sequential;
use JSON::Class::HOW::TypeWrapper;
use JSON::Class::Internals;
use JSON::Class::Jsonish;
use JSON::Class::Object;
use JSON::Class::Representation;
use JSON::Class::RoleHOW;
use JSON::Class::Sequence;
use JSON::Class::SequenceHOW;
use JSON::Class::Sequential;
use JSON::Class::Types :NOT-SET, :DEFAULT;
use JSON::Class::X;

INIT {
    JSON::Class::Config::set-std-typeobjects(
        :class-how(JSON::Class::ClassHOW),
        :object(JSON::Class::Object),
        :representation(JSON::Class::Representation) );
}

BEGIN {
    my sub config-defaults(*%options) is raw {
        %options.grep(*.value.defined).Hash
    }

    my sub no-redeclare(Mu \typeobj, Mu \how-role, Str:D $kind) {
        if typeobj.HOW ~~ how-role {
            JSON::Class::X::Redeclaration.new(:$kind, :name(typeobj.^name)).throw
        }
    }

    my sub apply-parents(Mu \typeobj, *@parents) {
        for @parents -> $parent {
            typeobj.^add_parent:
                $parent ~~ JSON::Class::Jsonish
                    ?? $parent
                    !! JSON::Class::Config.jsonify($parent, JSON::Class::Representation);
        }
    }

    my sub does2list(Mu \does) is raw {
        does.HOW ~~ Metamodel::ParametricRoleHOW | Metamodel::ParametricRoleGroupHOW
            ?? (does<>,)
            !! does.map(*<>).eager.List
    }

    my proto sub is2list(|) {*}
    multi sub is2list(NOT-SET) is raw { () }
    multi sub is2list(Mu:U \parent) is raw { (parent,) }
    multi sub is2list(Positional:D \parents) is raw { parents.eager.List }
    multi sub is2list(Mu:D \wrong) {
        JSON::Class::X::Trait::Argument.new(
            :why(":is must be a class or a list of classes, not an instance of " ~ wrong.^name),
            :singular
        ).throw
    }

    my sub one-collection-kind($sequence, $dict --> Nil) {
        $sequence
        andthen $dict
        andthen JSON::Class::X::Trait::Argument.new(:why("both :sequence and :dict can't be used")).throw
    }

    my sub jsonify-role( Mu:U \typeobj,
                         Bool :$implicit,
                         Bool :$lazy,
                         Bool :$skip-null,
                         :$does = (),
                         :$is = (),
                         :$sequence = NOT-SET,
                         :dictionary(:$dict) = NOT-SET,
                         *%extra )
    {
        verify-named-args(:%extra, :what("trait '" ~ $*JSON-CLASS-TRAIT ~ "'"), :source(typeobj.^name));
        one-collection-kind($sequence, $dict);

        if $sequence !=== NOT-SET {
            no-redeclare(typeobj, JSON::Class::HOW::Sequential, "role");

            typeobj.HOW does JSON::Class::HOW::Sequential;
            typeobj.^json-setup-sequence($sequence.List);
        }
        elsif $dict !=== NOT-SET {
            no-redeclare(typeobj, JSON::Class::HOW::Dictionary, "role");

            typeobj.HOW does JSON::Class::HOW::Dictionary;
            typeobj.^json-setup-dictionary($dict.List);
        }
        else {
            no-redeclare(typeobj, JSON::Class::RoleHOW, "role");

            typeobj.HOW does JSON::Class::RoleHOW;
            typeobj.^json-set-explicit(!$_) with $implicit;
            typeobj.^json-set-skip-null($skip-null);
            typeobj.^json-configure-typeobject( :$lazy, is => is2list($is), does => does2list($does) )
        }
    }

    my sub jsonify-class( Mu:U \typeobj,
                          Bool :$implicit,
                          Bool :$lazy,
                          Bool :$pretty,
                          Bool :$sorted-keys,
                          Bool :$skip-null,
                          :$does = (),
                          :$is = (),
                          :$sequence = NOT-SET,
                          :dictionary(:$dict) = NOT-SET,
                          *%extra )
    {
        verify-named-args(:%extra, :what("trait 'json'"), :source(typeobj.^name));
        one-collection-kind($sequence, $dict);

        if $sequence !=== NOT-SET {
            no-redeclare(typeobj, JSON::Class::SequenceHOW, "class");

            typeobj.HOW does JSON::Class::SequenceHOW;
            typeobj.^add_role(JSON::Class::Sequential);
            typeobj.^json-setup-sequence($sequence.List);
        }
        elsif $dict !=== NOT-SET {
            no-redeclare(typeobj, JSON::Class::DictHOW, "class");

            typeobj.HOW does JSON::Class::DictHOW;
            typeobj.^add_role(JSON::Class::Dictionary);
            typeobj.^json-setup-dictionary($dict.List);
        }
        else {
            no-redeclare(typeobj, JSON::Class::ClassHOW, "class");

            typeobj.HOW does JSON::Class::ClassHOW;
            typeobj.^add_role(JSON::Class::Representation);
            typeobj.^json-set-explicit(!$_) with $implicit;
            typeobj.^json-set-skip-null($skip-null);
        }

        typeobj.^json-configure-typeobject( :$lazy, :$pretty, :$sorted-keys, is => is2list($is), does => does2list($does) );
    }

    my sub trait-capture(Mu \trait-arg) is raw {
        (trait-arg ~~ Bool ?? () !! trait-arg.List).Capture
    }

    multi sub trait_mod:<is>(Mu:U \typeobj, :$json!) is export {
        my $*JSON-CLASS-TRAIT := 'json';
        given typeobj.HOW {
            when Metamodel::ParametricRoleHOW {
                jsonify-role(typeobj, |trait-capture($json))
            }
            when Metamodel::ClassHOW {
                jsonify-class(typeobj, |trait-capture($json))
            }
            default {
                JSON::Class::X::UnsupportedType.new(:type(typeobj)).throw
            }
        }
    }

    multi sub trait_mod:<is>(Attribute:D $attr is raw, :$json!) is export {
        my $*JSON-CLASS-TRAIT := 'json';

        my \pkg = $*PACKAGE;

        unless pkg.HOW ~~ JSON::Class::HOW::AttributeContainer {
            JSON::Class::X::Trait::NonJSONType.new(:target("attribute " ~ $attr.name), :type(pkg)).throw
        }

        # Make a class explicit by default if the trait is used with an attribute.
        pkg.^json-set-explicit(True);
        pkg.^jsonify-attribute($attr, |trait-capture($json));
    }

    multi sub trait_mod:<is>(Mu:U \type, Mu :$json-wrap! is raw) is export {
        my $*JSON-CLASS-TRAIT := 'json-wrap';
        type.HOW does JSON::Class::HOW::TypeWrapper unless type.HOW ~~ JSON::Class::HOW::TypeWrapper;
        type.^json-set-wrappee($json-wrap.WHAT);
    }

    sub json-I-cant(--> Nil) is export { JSON::Class::CX::Cannot.new.throw }
}

multi sub postcircumfix:<[ ]>(JSON::Class::Sequence:D \JSONSEQ, Any:D $pos, Bool:D :$has!) is raw is export {
    JSONSEQ.HAS-POS($pos, :$has)
}

multi sub postcircumfix:<{ }>(JSON::Class::Dict:D \JSONDICT, Mu $key, Bool:D :$has!) is raw is export {
    JSONDICT.HAS-KEY($key, :$has)
}

our sub META6 {
    $?DISTRIBUTION.meta
}

# vim: expandtab shiftwidth=4 ft=raku
