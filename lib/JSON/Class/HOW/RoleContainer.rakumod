use v6.e.PREVIEW;
unit role JSON::Class::HOW::RoleContainer:ver($?DISTRIBUTION.meta<ver>):auth($?DISTRIBUTION.meta<auth>):api($?DISTRIBUTION.meta<api>);

use JSON::Class::Types;

has $!json-roles is json-meta(:mixin-skip);

method json-register-role(Mu \obj, Mu \typeobj --> Nil) {
    .BIND-POS(.elems, typeobj)
        given ($!json-roles // ($!json-roles := my @))
}

method json-roles(Mu \obj) is raw { $!json-roles // () }