use v6.e.PREVIEW;
unit module JSON::Class::Utils:ver($?DISTRIBUTION.meta<ver>):auth($?DISTRIBUTION.meta<auth>):api($?DISTRIBUTION.meta<api>);
use nqp;

use JSON::Class::Types;

sub nominalize-type(Mu \type) is raw is pure is export {
    type.^archetypes.nominalizable ?? type.^nominalize !! type.WHAT
}

sub is-basic-type(Mu \type) is raw is pure is export {
    (type.^archetypes.nominalizable ?? type.^nominalize !! type) ~~ JSONBasicType
}

# We consider a type to be a class if it's not a basic type or has at least one public or settable attribute.
sub is-a-class-type(Mu \type) is raw is pure is export {
    my \nominal-type = (type.^archetypes.nominalizable ?? type.^nominalize !! type);

    # Rat needs to be handled individually because it does have public attributes from the Rational role.
    !(nominal-type === Rat)
      && ?( nominal-type.HOW ~~ Metamodel::ClassHOW
            && (nominal-type !~~ JSONBasicType
                || nominal-type.^attributes.first({ .has_accessor || .is_built }) ))
}

sub type-or-instance(Mu \what) is export {
    (nqp::isconcrete(nqp::decont(what)) ?? "an instance of " !! "a type object ") ~ what.^name
}