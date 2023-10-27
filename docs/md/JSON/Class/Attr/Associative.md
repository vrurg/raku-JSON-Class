rakudoc
=======

NAME
====

`JSON::Class::Attr::Associative` – descriptor of `%`-sigilled attributes

ATTRIBUTES
==========

  * `Mu `**`$.key-type`**

    Constraint type of associative keys. for `has %.assoc{Foo:D}` it will be `Foo:D`.

  * `Mu `**`$.nominal-keytype`**

    Nominalized `$.key-type`. For the above example it will be `Foo`.

METHODS
=======

  * **`method set-serializer($attribute?, :$value, :$key)`**

    Set custom serializers for the attribute. Argument names reflect the kinds of serializers.

  * **`method set-deserializer($attribute?, :$value, :$key)`**

    Set custom deserializers for the attribute. Argument names reflect the kinds of serializers.

  * **`multi method kind-type('value')`**

    Returns value type of the associative. I.e. for `has Bar:D %.assoc` it would be `Bar:D`.

  * **`multi method kind-type('key')`**

    Returns `self.key-type` of the associative.

SEE ALSO
========

  * [`JSON::Class`](../Class.md)

  * [`JSON::Class::Details`](Details.md)

  * [`JSON::Class::Descriptor`](../Descriptor.md)

  * [`JSON::Class::Attr`](../Attr.md)

COPYRIGHT
=========

(c) 2023, Vadim Belman <vrurg@cpan.org>

LICENSE
=======

Artistic License 2.0

See the [*LICENCE*](../../../../LICENCE) file in this distribution.

