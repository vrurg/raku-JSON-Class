use v6.e.PREVIEW;
unit role JSON::Class::HOW::Jsonish:ver($?DISTRIBUTION.meta<ver>):auth($?DISTRIBUTION.meta<auth>):api($?DISTRIBUTION.meta<api>);
use nqp;

use JSON::Class::Types;

has $!json-warnings;

method json-kind {...}
method json-is-generic {...}

method json-add-warning(Mu \obj, \warning) {
    ($!json-warnings // ($!json-warnings := Array.new)).push: warning;
}

method json-warnings(Mu \obj, Bool :$clear) is raw {
    $!json-warnings // ()
}

method json-report-warnings(Mu, $config --> Nil) is hidden-from-backtrace {
    return without $!json-warnings;
    $config.notify(|$_) for $!json-warnings;
    $!json-warnings := Nil;
}

method json-mixin(Mu \obj, Mu \target) {
    my \target-how = target.HOW;
    my \obj-how = obj.HOW;

    HOW-ATTR:
    for obj-how.^attributes.grep({ .name ~~ /^<[\$@\%]> \! json <.wb>/ }) -> \attr {
        if attr ~~ JSON::Class::Types::JSONAttr {
            my $meta := attr.json-meta;
            next HOW-ATTR if $meta.mixin-skip;
        }
        my \orig-value = attr.get_value(obj-how);
        my \copy-value =
            orig-value.DEFINITE
                ?? (orig-value.^can('clone') ?? orig-value.clone !! nqp::clone(orig-value))
                !! orig-value;
        my \target-container = attr.get_value(target-how);
        # If the original attribute and the target one are both scalar containers then copy by assigning to preserve
        # containerization.
        if orig-value.VAR ~~ Scalar && target-container.VAR ~~ Scalar {
            attr.get_value(target-how) = copy-value;
        }
        else {
            attr.set_value(target-how, copy-value)
        }
    }
}

method generate_mixin(Mu \obj, @roles) is raw {
    my $*JSON-CLASS-MIXIN := True;
    my Mu $*JSON-CLASS-MIXIN-BASE := obj;
    nextsame
}

method new_type(:$is_mixin, |c --> Mu) is raw {
    my \obj = callsame();

    if $is_mixin {
        self.json-mixin($*JSON-CLASS-MIXIN-BASE, obj);
    }

    obj
}