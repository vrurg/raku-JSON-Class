use v6.e.PREVIEW;
unit role JSON::Class::HOW::Collection::Role:ver($?DISTRIBUTION.meta<ver>):auth($?DISTRIBUTION.meta<auth>):api($?DISTRIBUTION.meta<api>)
    [::HOW-ROLE Mu, ::CLASS-ROLE Mu];

use JSON::Class::HOW::Jsonish;
use JSON::Class::HOW::Collection;

my role ConcCollRoleHOW does JSON::Class::HOW::Collection {}

method json-specialize-with(Mu \obj, Mu \conc, TypeEnv:D \typeenv, Mu \pos-args --> Mu) is raw {
    my Mu \target-class = pos-args[0];
    my Mu \target-how = target-class.HOW;

    if target-how ~~ JSON::Class::HOW::Jsonish && target-how !~~ HOW-ROLE {
        JSON::Class::X::BadTarget.new(
            :type(obj),
            :target(target-class),
            :why("it is a JSON type but not a " ~ HOW-ROLE.json-kind) ).throw
    }

    unless target-how ~~ HOW-ROLE {
        target-how does HOW-ROLE;
        target-class.^add_role(CLASS-ROLE);
    }

    my Mu $chow := conc.HOW;
    $chow does ConcCollRoleHOW unless $chow ~~ ConcCollRoleHOW;

    for self.json-local-item-descriptors(obj) -> $descr {
        conc.^json-add-item-descriptor: typeenv.instantiate($descr);
    }

    target-class.^json-register-role(conc);
}

method json-item-descriptors(Mu \obj) {
    self.json-local-item-descriptors(obj)
}