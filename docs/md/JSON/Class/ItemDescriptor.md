# NAME

`JSON::Class::ItemDescriptor` - descriptor for sequence item

# ATTRIBUTES

  - `Mu `**`$.type`**
    
    Item constraint type. I.e. when `class JSeq is json(:sequence(Str:D))` it will be `Str:D`.

  - `Mu `**`$.nominal-type`**
    
    Nominalization of `$.type`.

  - `Str `**`$.name`**
    
    Name to report this descriptor in messages.

# METHODS

  - **`method set-serializer($item?)`**
    
    Set custom item serializer.

  - **`method set-deserializer($item?)`**
    
    Set custom item deserializer.

  - **`method has-matcher()`**
    
    Returns *True* if custom matcher is set for this item.

  - **`method set-matcher($matcher?)`**
    
    Set custom matcher for this item.

  - **`method matcher()`**
    
    Return custom matcher for this item

  - **`multi method kind-type('match')`**
    
    Returns `$.type`.

  - **`multi method kind-type('item')`**
    
    Returns `$.type`.

  - **`multi method kind-stage(JSDeserialize, 'match')`**
    
    Returns `JSMatch` of `JSONStages` (see [`JSON::Class::Types`](Types.md)).

# SEE ALSO

  - [`JSON::Class`](../Class.md)

  - [`JSON::Class::Details`](Details.md)

  - [`JSON::Class::Descriptor`](Descriptor.md)

  - [`JSON::Class::Types`](Types.md)

# COPYRIGHT

(c) 2023, Vadim Belman <vrurg@cpan.org>

# LICENCE

Artistic License 2.0

See the [*LICENCE*](../../../../LICENCE) file in this distribution.
