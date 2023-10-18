unit role JSON::Class::ClassHOW:ver($?DISTRIBUTION.meta<ver>):auth($?DISTRIBUTION.meta<auth>):api($?DISTRIBUTION.meta<api>);

use AttrX::Mooish;
use AttrX::Mooish::Attribute;
use AttrX::Mooish::Helper;

use JSON::Class::Attr;
use JSON::Class::Jsonish;
use JSON::Class::HOW::AttributeContainer;
use JSON::Class::HOW::Configurable;
use JSON::Class::HOW::Explicit;
use JSON::Class::HOW::Imply;
use JSON::Class::HOW::SelfConfigure;
use JSON::Class::Internals;
use JSON::Class::Utils;

also does JSON::Class::HOW::AttributeContainer;
also does JSON::Class::HOW::Configurable;
also does JSON::Class::HOW::Explicit;
also does JSON::Class::HOW::Imply;
also does JSON::Class::HOW::SelfConfigure;

has $!json-roles;
has $!json-composed;

method compose_attributes(Mu \obj, |) {
    nextsame() if $!json-composed;

    # This method is called twice during class composition. The first time is when roles are already specialized
    # for the target class but not yet applied. At this point we know all JSON roles to pull info from.
    # At the second stage all attributes, including those from roles, are already installed but not composed yet. This
    # would be the best time to fixup JSON attribute descriptors.
    if self.is_composed(obj) {
        $!json-composed := True;

        with $!json-roles {
            # Move attribute descriptors from roles to class local registry and re-bind them to class' attribute instances.
            for $!json-roles.List -> Mu \jsony-role {
                for jsony-role.^json-attrs.values -> JSON::Class::Attr:D $json-attr {
                    my Attribute:D $my-attr := self.get_attribute_for_usage(obj, $json-attr.name);
                    self.json-attr-register(obj, $json-attr.clone(:attr($my-attr)));
                }
            }
        }

        self.json-incorporate-attributes(obj);

        # We don't need this anymore as at this point all is set.
        self.json-incorporated-roles-cleanup(obj);
    }
    else {
        unless self.json-is-explicit(obj) {
            self.json-imply-attributes(obj, :local);
        }
    }

    nextsame();
}

method json-register-role(Mu \obj, Mu \typeobj) {
    ($!json-roles // ($!json-roles := Array[Mu].new)).push: typeobj;
}

method json-incorporate-attributes(Mu \obj --> Nil) {
    for self.json-incorporated-roles(obj) -> \p (:key($owner) is raw, :value(@roles) is raw) {
        for @roles -> \r {
            my @c = self.concretization_lookup(obj, r, :local);
            for @c[1..*] -> \conc {
                for conc.^attributes(:local) -> \cattr {
                    my Bool $lazy = $owner.^json-is-lazy && !is-basic-type(cattr.type);
                    self.jsonify-attribute($owner, cattr, :$lazy, :skip(cattr.name.starts-with('&')));
                }
            }
        }
    }
}

# For classes jsonified by JSON::Class::Config this method will return the original class.
method json-FROM(Mu \obj) is raw { obj.WHAT }