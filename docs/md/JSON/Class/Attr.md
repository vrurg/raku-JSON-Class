# rakudoc

# NAME

`JSON::Class::Attr` – base role for attribute descriptors

# ATTRIBUTES

  - `Bool `**`$.skip`**
    
    Skip this attribute altogether:
    
    ``` raku
    has $.attr is json(:skip);
    ```

  - `Str:D `**`$.json-name`**
    
    Name of JSON object key. Unless manually altered by user, it is attribute base name.

  - `Bool `**`$.lazy`**
    
    *True* if attribute is lazily deserialized.

# METHODS

  - **`method set-serializer()`**, **`method set-deserializer()`**
    
    These methods must be implemented by particular attribute descriptor class.

  - **`method sigil()`**
    
    Gives attribute sigil.

  - **`method skip-null()`**
    
    *True* if this attribute only serializable with a defined value.

  - **`method kind-type('attribute')`**
    
    Returns attribute constraint type.

# SEE ALSO

  - [`JSON::Class`](../Class.md)

  - [`JSON::Class::Details`](Details.md)

  - [`JSON::Class::Descriptor`](Descriptor.md)

  - [`JSON::Class::Attr::Associative`](Attr/Associative.md)

  - [`JSON::Class::Attr::Positional`](Attr/Positional.md)

  - [`JSON::Class::Attr::Scalar`](Attr/Scalar.md)

# COPYRIGHT

(c) 2023, Vadim Belman <vrurg@cpan.org>

# LICENCE

Artistic License 2.0

See the [*LICENCE*](../../../../LICENCE) file in this distribution.
