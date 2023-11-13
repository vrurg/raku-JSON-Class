use v6.e.PREVIEW;
unit role JSON::Class::RoleHOW:ver($?DISTRIBUTION.meta<ver>):auth($?DISTRIBUTION.meta<auth>):api($?DISTRIBUTION.meta<api>);

use AttrX::Mooish::Helper;

use JSON::Class::Attr;
use JSON::Class::HOW::Explicit;
use JSON::Class::HOW::Jsonish;
use JSON::Class::HOW::Imply;
use JSON::Class::HOW::Configurable;
use JSON::Class::HOW::AttributeContainer;
use JSON::Class::HOW::SelfConfigure;
use JSON::Class::Config;

also does JSON::Class::HOW::Jsonish;
also does JSON::Class::HOW::AttributeContainer;
also does JSON::Class::HOW::Configurable;
also does JSON::Class::HOW::Explicit;
also does JSON::Class::HOW::SelfConfigure;
also does JSON::Class::HOW::Imply;

method compose(Mu \typeobj) {
    unless self.json-is-explicit(typeobj) {
        self.json-imply-attributes(typeobj, :local);
    }

    nextsame
}

method specialize(Mu \obj, Mu \target-class, |) is raw {
    my Mu \target-how = target-class.HOW;
    my Mu \class-how = JSON::Class::Config.json-class-how;
    unless target-how ~~ class-how {
        target-how does class-how;
        target-class.^add_role(JSON::Class::Config.json-representation);
        target-class.^json-set-explicit(True);
    }
    target-class.^json-register-role(obj);
    for self.json-incorporated-roles(obj) -> (:key($owner), :value(@roles)) {
        target-class.^json-incorporate-roles($owner, @roles);
    }
    nextsame
}

method json-kind { 'role' }