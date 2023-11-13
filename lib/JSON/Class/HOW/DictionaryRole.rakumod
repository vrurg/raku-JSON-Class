use v6.e.PREVIEW;
unit role JSON::Class::HOW::DictionaryRole:ver($?DISTRIBUTION.meta<ver>):auth($?DISTRIBUTION.meta<auth>):api($?DISTRIBUTION.meta<api>);

use JSON::Class::HOW::Collection::Role;
use JSON::Class::HOW::Dictionary;
use JSON::Class::DictHOW;
use JSON::Class::Dictionary;

also does JSON::Class::HOW::Collection::Role[JSON::Class::DictHOW, JSON::Class::Dictionary];
also does JSON::Class::HOW::Dictionary;

method compose(|) is raw {
    my Mu \obj = callsame();
    self.json-setup-dictionary(obj);
    obj
}

method specialize(Mu \obj, Mu \target-class) is raw {
    self.json-role-specialize(obj, target-class);

    target-class.^json-set-key-descriptor($_, :offer) with self.json-key-descriptor(obj, :peek);

    nextsame
}

method json-kind { 'dictionary role' }