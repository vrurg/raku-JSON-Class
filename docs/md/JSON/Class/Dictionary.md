# rakudoc

# NAME

`JSON::Class::Dictionary` – base role for JSON dictionaries

# METHODS

  - **`method json-class()`**
    
    Returns the class `is json` trait was applied to.

  - **`method json-config-defaults()`**
    
    Returns a hash of configuration properties to be used as defaults for a new [`JSON::Class::Config`](Config.md) instance. See also [`JSON::Class`](../Class.md) and [`JSON::Class::Details`](Details.md).

  - **`method json-dictionary-type()`**
    
    Returns a parameterization of [`Hash`](https://docs.raku.org/type/Hash) which would be validating against dictionary types, both value and key. [`JSON::Class::Dict`](Dict.md) uses an instance of this type as its backing storage.

  - **`method json-key-descriptor()`**
    
    Returns the descriptor object for dictionary keys. Redirects to the same name method of [`JSON::Class::DictHOW`](DictHOW.md).

  - **`method json-item-descriptors(|)`**
    
    Redirects to the same name method of [`JSON::Class::HOW::Collection`](HOW/Collection.md).

  - **`method json-create(*%profile)`**
    
    Exists for compatibility with other components of this distribution. Currently it is just a redirect to `new`.

  - **`method keyof()`**
    
    Returns the dictionary key type.

  - **`method of()`**
    
    Returns the dictionary value type.

# SEE ALSO

  - [`JSON::Class`](../Class.md)

  - [`JSON::Class::Dict`](Dict.md)

  - [`JSON::Class::DictHOW`](DictHOW.md)

  - [`JSON::Class::Details`](Details.md)

  - [`INDEX`](../../../../INDEX.md)

# COPYRIGHT

(c) 2023, Vadim Belman <vrurg@cpan.org>

# LICENSE

Artistic License 2.0

See the [*LICENSE*](../../../../LICENSE) file in this distribution.
