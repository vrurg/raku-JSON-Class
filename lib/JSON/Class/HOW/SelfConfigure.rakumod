use v6.e.PREVIEW;
unit role JSON::Class::HOW::SelfConfigure:ver($?DISTRIBUTION.meta<ver>):auth($?DISTRIBUTION.meta<auth>):api($?DISTRIBUTION.meta<api>);

use JSON::Class::Config;
use JSON::Class::Jsonish;
use JSON::Class::Internals;
use JSON::Class::Types;
use JSON::Class::Utils;

has $!json-incorporated-roles is json-meta(:mixin-skip);

method json-incorporated-roles(Mu \obj) is raw { $!json-incorporated-roles // () }

method json-incorporate-roles(Mu, Mu \owner-type, @roles --> Nil) {
    given ($!json-incorporated-roles // ($!json-incorporated-roles := Array.new)) {
        .BIND-POS(.elems, Pair.new(owner-type, @roles));
    }
}

method json-incorporate-role(Mu \obj, Mu \owner-type, Mu \r --> Nil) {
    self.json-incorporate-roles(obj, owner-type, (r,));
}

method json-incorporated-roles-cleanup(Mu) {
    $!json-incorporated-roles := Nil;
}

method json-configure-typeobject( Mu \obj,
                                  Bool :$implicit,
                                  Bool :$lazy,
                                  Bool :$pretty,
                                  Bool :$sorted-keys,
                                  :%config,
                                  :does(:@roles),
                                  :is(:@parents)
                                  --> Nil )
{
    self.json-incorporate-roles(obj, obj, @roles);
    self.add_role(obj, $_) for @roles;

    for @parents -> Mu \parent-class {
        if parent-class.DEFINITE || parent-class.HOW !~~ Metamodel::ClassHOW {
            JSON::Class::X::Trait::Argument.new(
                :why(type-or-instance(parent-class) ~ " passed with :is, but a class was expected"),
                :singular
            ).throw
        }
        my \jpclass =
            (parent-class ~~ JSON::Class::Jsonish ?? parent-class !! JSON::Class::Config.jsonify(parent-class));
        self.add_parent: obj, jpclass;
    }

    with $lazy {
        self.json-set-lazy(obj, $_);
        %config<eager> = !$_;
    }

    %config<pretty> = $_ with $pretty;
    %config<sorted-keys> = $_ with $sorted-keys;

    self.json-configure-defaults(obj, |%config);
}

method json-post-compose(Mu \obj --> Nil) {
    obj.WALK(:name<JSON-POSTCOMPOSE>, :submethods, :!methods, :roles).invoke()
}