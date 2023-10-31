# NAME

`JSON::Class::Attr::Positional` - descriptor of `@`-sigilled attributes

# METHODS

  - **`method set-serializer($attribute?, :$value)`**
    
    Set custom serializers for the attribute. Argument names reflect the kinds of serializers.

  - **`method set-deserializer($attribute?, :$value)`**
    
    Set custom deserializers for the attribute. Argument names reflect the kinds of serializers.

  - **`multi method key-type('value')`**
    
    Returns `self.value-type`.

# SEE ALSO

  - [`JSON::Class`](../../Class.md)

  - [`JSON::Class::Details`](../Details.md)

  - [`JSON::Class::Descriptor`](../Descriptor.md)

  - [`JSON::Class::Attr`](../Attr.md)

# COPYRIGHT

(c) 2023, Vadim Belman <vrurg@cpan.org>

# LICENCE

Artistic License 2.0

See the [*LICENCE*](../../../../../LICENCE) file in this distribution.
