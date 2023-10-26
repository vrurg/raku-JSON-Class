rakudoc
=======

NAME
====

`JSON::Class::Config` - `JSON::Class` configuration

METHODS
=======

General Purpose
---------------

  * **`method new(...)`**

    The following attributes can be set with the constructor:

      * `Str` **`:$severity`**

        Can be one of "easy", "warn", "strict". See methods `severity`, `alert`, `notify` for more details.

      * Severity flags:

          * `Bool` **`:$easy`**

          * `Bool` **`:$warn`**

          * `Bool` **`:$strict`**

        Alternate way to set the severity. Only one at a time can be used.

      * `Bool` **`:$defaults`**

        Set default helpers for standard types. Currently it is [`DateTime`](https://docs.raku.org/type/DateTime) supported which is serialized to a string by default.

      * Configuration parameters:

          * `Bool` **`:$allow-jsonc`**`= False`

          * `Bool` **`:$eager`**`= False`

          * `Bool` **`:$enums-as-value`**`= False`

          * `Bool` **`:$pretty`**`= False`

          * `Bool` **`:$skip-null`**`= True`

          * `Bool` **`:$sorted-keys`**`= False`

          * `UInt` **`:$spacing`**`= 2`

        See corresponding methods for the meaning of each parameter.

  * **`method global(*%)`**

    Returns the global configuration object instance. For the first time it possible to set global defaults by passing to the method the same arguments as for the `new` method. This is because the global doesn't exists until requested for the first time.

    *Remember* that invoking most methods on `JSON::Class::Config` typeobject directly redirects to the global meaning that any such call can be the first to vivify the object.

  * **`method profile()`**

    Creates a profile hash which can be used as named arguments to create a new config instance. For example:

    ```raku
    my $config = JSON::Class::Config().new(|JSON::Class::Config().profile(), :!eager)
    ```

  * **`method dup(*%twiddles)`**

    This method duplicates it's invocator, similarly to `clone`, but using method `new` to create a completely new object. Basically, the `profile` method example can be changed as:

    ```raku
    my $config = JSON::Class::Config().dup(:!eager)
    ```

Properties
----------

Note that with regard to configuration properties `JSON::Class::Config` is immutable.

  * **`method allow-jsonc()`**

    Allow JSONC standard. See [`JSON::Fast` from-json argument](https://raku.land/cpan:TIMOTIMO/JSON::Fast#allow-jsonc).

  * **`method pretty()`**

    Turn on JSON formatting. See [`JSON::Fast` to-json argument](https://raku.land/cpan:TIMOTIMO/JSON::Fast#pretty).

  * **`method spacing()`**

    Level of indentation when is `$config.pretty`. See [`JSON::Fast` to-json argument](https://raku.land/cpan:TIMOTIMO/JSON::Fast#pretty).

  * **`method sorted-keys()`**

    Sort JSON key in the output. See [`JSON::Fast` to-json argument](https://raku.land/cpan:TIMOTIMO/JSON::Fast#sorted-keys).

  * **`method enums-as-value()`**

    Treat enums by their underlying values. See [`JSON::Fast` to-json argument](https://raku.land/cpan:TIMOTIMO/JSON::Fast#enum-as-value)

  * **`method skip-null()`**

    Skip undefined values by default. JSON classes, roles, and individual attributes can override this default.

  * **`method eager()`**

    If *True* lazy deserialization is disabled.

Utility
-------

  * **`proto method jsonify(|)`**

    This method JSONifies it only positional argument. Works with both type objects and instances.

      * **`multi method jsonify(Mu:U $what, |)`**

        This method nominalizes `$what` and JSONifies it.

      * **`multi method jsonify(Mu:U :$nominal-what, Bool :$local)`**

        This candidate is for cases where one knows exactly that the typeobject is nominal. Otherwise is identical to the previous candidate. In fact, it is the previous using this one.

      * **`multi method jsonify(Mu:D $obj, |)`**

        This method creates a JSONified copy of `$obj` by first JSONifying its `.WHAT` class then using its `clone-from` method to transfer attribute values from $obj to the JSONified copy.

  * **`method set-helpers(Mu $type, :to-json(:$serializer), :from-json(:$deserializer), :$matcher, *%helpers)`**

    Set universal helper for a typeobject `$type`. This is helpful when class is used by a few JSONified structures.

    The meaning of helpers should be clear. As a little reminder, `:$matcher` is described in the *Sequences* section of [`JSON::Class`](../Class.md) documentation.

    Helpers can be either code objects, or method names on `$type`.

    `$type` can be any class, not necessarily a JSON one. For example, the default helpers for [`DateTime`](https://docs.raku.org/type/DateTime), installed when `:$defaults` of `JSON::Class::Config` constructor is *True*, are set like this:

    ```raku
    self.set-helpers(DateTime, :to-json<Str>, :from-json<new>, matcher => -> Str:D:D:D:D:D $from {
        ?try {
            DateTime.new($from)
        }
    })
    ```

    With them a `DateTime` instance would always be represented as a string.

    Setting custom helpers is allowed as keys of `%helpers` slurpy:

    ```raku
    $config.set-helpers: Foo, validator => &make-sure-foo-is-well-formed;
    ```

    Apparently, these won't be used by the `JSON::Class` itself and would only serve for one's code purposes.

  * **`method helper(Mu $type, Str:D $stage)`**

    Get a helper for `$stage` where stage is *'to-json'*, *'from-json'*, *'match'*, or a key from `%helpers` slurpy of `set-helper` method..

  * **`method serializer(Mu $what)`**

    Get serialzier for object `$what`. Similar to `$config.helper($what, 'to-json')`.

  * **`method deserializer(Mu $what)`**

    Get deserialzier for object `$what`. Similar to `$config.helper($what, 'from-json')`

  * **`method matcher(Mu $what)`**

    Get matcher for object `$what`. Similar to `$config.helper($what, 'match')`

  * **`proto method map-type(|)`**

    This method installs type mapping. See *Type Mapping* section in [`JSON::Class::Details`](Details.md).

      * **`multi method map-type(Mu:U \from-type, Mu:U \to-type)`**

        Simply install a mapping.

      * **`multi method map-type(Mu:U \wrapper)`**

        This is a simplified version of the previous candidate which can be used for classes with `is json-wrap` applied. See *Type Mapping* section in [`JSON::Class::Details`](Details.md).

      * **`method map-type(Pair:D $map)`**

        `$config.map-type((FromType) =` ToType))> is just an alternative way to do `$config.map-type(FromType, ToType)`. Mostly useful to provide support for the `map-types` method.

  * **`method map-types(*@maps)`**

    To install multiple mappings at once. Each item of maps can be either a list of two elements `(FromType, ToType)`, or a JSON wrapper class, or a [`Pair`](https://docs.raku.org/type/Pair) – see the `map-type` method candidates:

    ```raku
    class AWrapperClass is json-wrap(OriginalClass) {...}

    $config.map-types:
        (Foo, Bar),
        AWrapperClass,
        (Baz) => Fubar;
    ```

    Simply choose which one works better for you.

  * **`method type-from(Mu:U \from-type)`**

    Returns `to-type`, installed with a `map-type` class for `from-type`.

  * **`method set-severity(Bool :$easy, Bool :$warn, Bool :$strict)`**

    Set the severity of `JSON::Class` reaction to errors or warnings. See methods `alert` and `notify`.

  * **`method severity(--` Str:D)**>

    Returns current severity.

  * **`method with-severity(&code, Bool :$easy, Bool :$warn, Bool :$strict)`**

    Executes `&code` with temporarily set severity level. Say, one wants to hide errors for a task; or vice versa, make sure no error gets lost.

  * **`proto method alert(|)`**

    Depending on the current severity level, would do nothing, or issue a warning with `warn` routine, or throw an exception.

    Candidates are:

      * **`multi method alert(Exception:D $ex)`**

        This is the primary which does all the job.

      * **`multi method alert(*@msg)`**

        Same as calling with `JSON::Class::X::AdHoc` exception instance. Message is formed by joining `gist`s of `@msg` elements.

  * **`method notify(*@msg)`**

    This method is similar to `alert` except that it only warns with a message formed of `gist`s of `@msg`. Unless the severity is `easy`, of course.

  * **`method to-json-profile(--` Map:D)**>

    This method returns a [`Map`](https://docs.raku.org/type/Map) with named arguments for [`JSON::Fast`](https://raku.land/cpan:TIMOTIMO/JSON::Fast) `to-json` routine:

    ```raku
    to-json($data, |$config.to-json-profile);
    ```

  * **`method from-json-profile()`**

    Returns a [`Map`](https://docs.raku.org/type/Map) with named arguments for [`JSON::Fast`](https://raku.land/cpan:TIMOTIMO/JSON::Fast) `from-json` routine:

    ```raku
    from-json($json, |$config.from-json-profile);
    ```

SEE ALSO
========

  * [`JSON::Class`](../Class.md)

  * [`JSON::Class::Details`](Details.md)

COPYRIGHT
=========

(c) 2023, Vadim Belman <vrurg@cpan.org>

LICENSE
=======

Artistic License 2.0

See the [*LICENSE*](../../../../LICENSE) file in this distribution.

