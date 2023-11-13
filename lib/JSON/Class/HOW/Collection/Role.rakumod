use v6.e.PREVIEW;
unit role JSON::Class::HOW::Collection::Role:ver($?DISTRIBUTION.meta<ver>):auth($?DISTRIBUTION.meta<auth>):api($?DISTRIBUTION.meta<api>)
    [::HOW-ROLE Mu, ::CLASS-ROLE Mu];

use JSON::Class::HOW::Jsonish;

method json-role-specialize(Mu \obj, Mu \target-class, |) is raw {
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

    target-class.^json-register-role(obj);
}

method json-item-descriptors(Mu \obj) {
    self.json-local-item-descriptors(obj)
}