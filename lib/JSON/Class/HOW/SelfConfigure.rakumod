use v6.e.PREVIEW;
unit role JSON::Class::HOW::SelfConfigure:ver($?DISTRIBUTION.meta<ver>):auth($?DISTRIBUTION.meta<auth>):api($?DISTRIBUTION.meta<api>);

use JSON::Class::Config;
use JSON::Class::Jsonish;
use JSON::Class::Internals;

has $!json-incorporated-roles;

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
                                  :does(:@roles),
                                  :is(:$parents) )
{
    self.json-incorporate-roles(obj, obj, @roles);
    self.add_role(obj, $_) for @roles;

    with $parents -> @p {
        for @p -> Mu \parent-class {
            my \jpclass =
                (parent-class ~~ JSON::Class::Jsonish ?? parent-class !! JSON::Class::Config.jsonify(parent-class));
            self.add_parent: obj, jpclass;
        }
    }

    my $eager;
    with $lazy {
        self.json-set-lazy(obj, $_);
        $eager = !$_;
    }

    self.json-configure-defaults(obj, :$pretty, :$sorted-keys, :$eager);
}