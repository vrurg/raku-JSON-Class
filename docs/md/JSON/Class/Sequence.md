# NAME

`JSON::Class::Sequence` - parent of JSON sequence classes

# DESCRIPTION

This class is injected into the list of parents of any JSON sequence class. It implements the essential functionality of sequence marshalling. See more in [`JSON::Class::Details`](Details.md).

# METHODS

The class implements standard positional methods like `AT-POS`, `EXISTS-POS`, `DELETE-POS`, `ASSIGN-POS`, `push`, `append`, `of`, `elems`, `end`, `iterator`.

  - **`method json-all-set()`**
    
    Returns *True* if all sequence values are deserialized.

  - **`proto method json-guess-descriptor(|)`**
    
      - **`multi method json-guess-descriptor(::?CLASS:D: Mu :$item-value!)`**
        
        Must return an [`JSON::Class::ItemDescriptor:D`](ItemDescriptor.md) for a given item value for serialization; or throw if no descriptor matches the `$item-value`.
    
      - **`multi method json-guess-descriptor(:$json-value, Int:D $idx)`**
        
        Must return a [`JSON::Class::ItemDescriptor:D`](ItemDescriptor.md) for a given JSON value for deserialization; or throw if no descriptor matches the `$json-value`. `$idx` is the position of the value in the original JSON array.

  - **`method json-serialize-item(::?CLASS:D: JSON::Class::ItemDescriptor:D $descr, Mu $value)`**
    
    Serialize given `$value` using item descriptor `$descr`.

  - **`method json-deserialize-item(::?CLASS:D: Int:D $idx, Mu $json-value)`**
    
    Default deserializer for `$json-value` at position `$idx` in the JSON array.

  - **`multi method json-deserialize(@from, JSON::Class::Config :$config)`**
    
    Deserialize given JSON array `@from`. The standard method maps `self` into a final type, if a type map is defined in [the configuation](Config.md). Then a new instance of the resulting is created and returned.

  - **`proto method HAS-POS(|)`**
    
      - **`multi method HAS-POS(Int:D $pos, Bool:D :$has = True)`**
        
        Reports if a value at the given position `$pos` has been deserialized already. If `$has` is *False* then it reports quite opposite: if it hasn't been deserialized.
    
      - **`multi method HAS-POS(::?CLASS:D: Iterable:D \positions, Bool:D :$has = True)`**
        
        Returns a sequence of boolean values for each position from `positions` as if `HAS-POS(position, :$hash)` has been invoked for each.

# SEE ALSO

  - [`JSON::Class`](../Class.md)

  - [`JSON::Class::Details`](Details.md)

  - [`JSON::Class::Sequential`](Sequential.md)

  - [`JSON::Class::SequenceHOW`](SequenceHOW.md)

# COPYRIGHT

(c) 2023, Vadim Belman <vrurg@cpan.org>

# LICENSE

Artistic License 2.0

See the [*LICENSE*](../../../../LICENSE) file in this distribution.
