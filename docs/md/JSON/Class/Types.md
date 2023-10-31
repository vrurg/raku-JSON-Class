# rakudoc

# NAME

`JSON::Class::Types` - standard types of `JSON::Class`

# DESCRIPTION

## `role CloneFrom`

Implements `clone-from` method. Method signature is:

  - **`method clone-from(Mu:D $obj, *%twiddles)`**

In a way, this method is identical to cloning but allows to clone for a different type object. It does so by pulling in attributes of `$obj`, creating a `%profile` where keys are attribute base names, and then by submitting the profile and `%twiddles` to the constructor `new`: `self.new(|%profile, |%twiddles)`.

## `subset JSONBasicType`

This subset matches what [`JSON::Class`](../Class.md) considers a "basic type". For now it would be one of the following:

  - `Numeric`

  - `String`

  - `Bool`

  - `Enumeration`

  - `Mu`

  - `Any`

The last two are checked for exact match. I.e. a [`Failure`](https://docs.raku.org/type/Failure) is not a basic type.

## `subset JSONHelper`

This subset matches only conrete string, or code, or an undefined `Any`.

## `enum JSONStages`

Enumerate marshalling stages. Elements are:

  - `JSSerialize` =\> *'to-json'*

  - `JSDeserialize` =\> *'from-json'*

  - `JSMatch` =\> *'match'*

# SEE ALSO

  - [`JSON::Class`](../Class.md)

  - [`JSON::Class::Details`](Details.md)

# COPYRIGHT

(c) 2023, Vadim Belman <vrurg@cpan.org>

# LICENCE

Artistic License 2.0

See the [*LICENCE*](../../../../LICENCE) file in this distribution.
