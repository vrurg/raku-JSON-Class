# rakudoc

# NAME

`JSON::Class::Sequential` – base role for JSON sequences

# METHODS

  - **`method json-class()`**
    
    Returns the class `is json` trait was applied to.

  - **`method json-config-defaults()`**
    
    Returns a hash of configuration properties to be used as defaults for a new [`JSON::Class::Config`](Config.md) instance. See also [`JSON::Class`](../Class.md) and [`JSON::Class::Details`](Details.md).

  - **`method json-array-type()`**
    
    Returns a parameterization of [`Array`](https://docs.raku.org/type/Array) which would be validating against sequence types, listed in the trait arguments. Same array type backs [`JSON::Class::Sequence`](Sequence.md) functionality.

  - **`method json-item-descriptors(|)`**
    
    Redirects to the same name method of [`JSON::Class::SequenceHOW`](SequenceHOW.md).

  - **`method json-create(*%profile)`**
    
    Exists for compatibility with other components of this distribution. Currently it is just a redirect to `new`.

# SEE ALSO

  - [`JSON::Class`](../Class.md)

  - [`JSON::Class::Sequence`](Sequence.md)

  - [`JSON::Class::SequenceHOW`](SequenceHOW.md)

# COPYRIGHT

(c) 2023, Vadim Belman <vrurg@cpan.org>

# LICENCE

Artistic License 2.0

See the [*LICENCE*](../../../../LICENCE) file in this distribution.
