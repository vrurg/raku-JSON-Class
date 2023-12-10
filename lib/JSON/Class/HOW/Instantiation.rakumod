use v6.e.PREVIEW;
unit role JSON::Class::HOW::Instantiation:ver($?DISTRIBUTION.meta<ver>):auth($?DISTRIBUTION.meta<auth>):api($?DISTRIBUTION.meta<api>);

use nqp;

# This must be set to a half-baked, pre-composed HOW. Normally, it'd be a clone of pre-composed class HOW.
has $!json-orig;
has $!json-how-template;
has $!json-typeenv;

my sub clone-HOW(Mu \how --> Mu) is raw {
    my Mu \how-clone := nqp::clone(how);
    for Metamodel::ClassHOW.^attributes(:local) -> \attr {
        my Mu \val = nqp::getattr(how, Metamodel::ClassHOW, attr.name);
        if nqp::islist(val) || nqp::ishash(val) {
            given attr.name {
                when '%!mro' | '%!hides_ids' {
                    # Reset MRO cache because it has to be rebuilt.
                    nqp::bindattr(how-clone, Metamodel::ClassHOW, attr.name, nqp::create(val.WHAT));
                }
                when '@!parents' | '@!hides' | '@!roles_to_compose' {
                    nqp::bindattr(how-clone, Metamodel::ClassHOW, attr.name, nqp::create(val.WHAT));
                }
                default {
                    nqp::bindattr(how-clone, Metamodel::ClassHOW, attr.name, nqp::clone(val));
                }
            }
        }
    }
    how-clone
}

method json-set-typeenv(Mu \obj, TypeEnv:D $typeenv --> Nil) {
    $!json-typeenv := $typeenv;
}

method json-clear-typeenv(Mu \obj --> Nil) {
    $!json-typeenv := Nil
}

method json-typeenv(Mu) is raw { $!json-typeenv }

method json-instantiation-prepare(Mu \obj) {
    die "Too late to call 'json-instantiation-prepare' method: " ~ self.name(obj) ~ " has been composed already"
        if self.is_composed(obj);
    $!json-orig := obj;
    $!json-how-template := clone-HOW(self);
}

# We play some dirty tricks here. :(
my atomicint $type-id = 0;
method json-instantiation-new-type(Mu \obj, Str :$name, TypeEnv :$typeenv --> Mu) is raw {
    my $*JSON-CLASS-INST-CLONING := True;
    my Mu \new-how = clone-HOW($!json-how-template);

    my Mu \new-type = Metamodel::Primitives.create_type(new-how);
    new-type.^set_name($name) with $name; # // new-type.^name ~ "_" ~ ++⚛$type-id);
    new-type.^publish_method_cache; # Prevent new class from using methods of the original
    new-type.^setup_mixin_cache();
    new-type.^json-set-typeenv($typeenv);

    new-type.HOW.wipe_conc_cache;
    new-how.add_parent(new-type, $!json-orig, :hides);
    new-how.compose(new-type);
    new-type
}