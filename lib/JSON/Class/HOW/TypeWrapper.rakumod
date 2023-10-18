use v6.e.PREVIEW;
unit role JSON::Class::HOW::TypeWrapper:ver($?DISTRIBUTION.meta<ver>):auth($?DISTRIBUTION.meta<auth>):api($?DISTRIBUTION.meta<api>);

has Mu $!wrappee;

method json-set-wrappee(Mu \obj, Mu:U $!wrappee --> Nil) {
    $!wrappee.^archetypes.composable
        ?? self.add_role(obj, $!wrappee)
        !! self.add_parent(obj, $!wrappee);
}

method json-wrappee(Mu \obj) is raw { $!wrappee }