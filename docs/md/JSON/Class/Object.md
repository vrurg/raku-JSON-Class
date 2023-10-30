# rakudoc

# NAME

`JSON::Class::Object` – parent of JSONified classes

# DESCRIPTION

This class is injected into the list of parent of any JSONified class. It implements the essential functionality of class serialization. See more in [`JSON::Class::Details`](Details.md).

# METHODS

Some methods of this class are already covered by [`JSON::Class`](../Class.md) page.

  - **`method json-unused()`**
    
    Returns a hash with keys for which no corresponding attributes are found.

  - **`method json-lazies()`**
    
    Returns a hash of keys not yet consumed by lazy deserialization

  - **`proto method json-serialize-attr(JSON::Class::Attr:D $attribute-descriptor, Mu \value)`**
    
    Multi-candidates of this proto take care of [`JSON::Class::Attr::Scalar`](Attr/Scalar.md), [`JSON::Class::Attr::Postional`](Attr/Postional.md), and [`JSON::Class::Attr::Associative`](Attr/Associative.md) descriptors each.

  - **`method json-build-attr(Str:D :$attribute)`**
    
    This method is invoked by [`AttrX::Mooish` to lazily build a JSON attribute.](https://raku.land/zef:vrurg/AttrX::Mooish)

  - **`proto method json-deserialize-attr(|)`**
    
    Similarly to the `json-serialize-attr` method, candidates of this proto take care of deserializing each kind of attribute descriptor.

# SEE ALSO

  - [`JSON::Class`](../Class.md)

  - [`JSON::Class::Details`](Details.md)

  - [`JSON::Class::Representation`](Representation.md)

  - [`JSON::Class::ClassHOW`](ClassHOW.md)

# COPYRIGHT

(c) 2023, Vadim Belman <vrurg@cpan.org>

# LICENCE

Artistic License 2.0

See the [*docs/md/LICENCE*](../../LICENCE) file in this distribution.
