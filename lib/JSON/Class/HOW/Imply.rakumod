use v6.e.PREVIEW;
unit role JSON::Class::HOW::Imply:ver($?DISTRIBUTION.meta<ver>):auth($?DISTRIBUTION.meta<auth>):api($?DISTRIBUTION.meta<api>);

use JSON::Class::Attr;
use JSON::Class::Internals;
use JSON::Class::Jsonish;
use JSON::Class::Utils;

method json-has-attr {...}
method json-is-lazy {...}

method json-imply-attributes(Mu \obj, Bool :$local, Bool :$forced) {
    my @attrs;

    if $local {
        @attrs = self.attributes(obj, :local);
    }
    else {
        my SetHash $seen .= new;

        my sub collect-from-class(Mu $class is raw) {
            for $class.^attributes(:local) {
                unless $seen.EXISTS-KEY(my $aname = .name) {
                    @attrs.push: $_;
                    $seen.set: $aname;
                }
            }

            for $class.^parents(:local) -> Mu \parent {
                # We only collect from non-json parents since others would take care of themselves.
                collect-from-class(parent) unless parent ~~ JSON::Class::Jsonish;
            }
        }

        collect-from-class(obj);
    }

    for @attrs.grep({ (.has_accessor || .is_built)
                        && !self.json-has-attr(obj, .name, :local)
                        && !(.name.substr(2).starts-with('json-')) })
        -> Attribute:D $attr
    {
        obj.^jsonify-attribute($attr, :skip($attr.name.starts-with('&')));
    }
}