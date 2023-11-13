use v6.e.PREVIEW;
unit role JSON::Class::HOW::RoleContainer:ver($?DISTRIBUTION.meta<ver>):auth($?DISTRIBUTION.meta<auth>):api($?DISTRIBUTION.meta<api>);

has $!json-roles;

method json-register-role(Mu \obj, Mu \typeobj) {
    ($!json-roles // ($!json-roles := Array[Mu].new)).push: typeobj;
}

method json-roles(Mu \obj) is raw { $!json-roles // () }