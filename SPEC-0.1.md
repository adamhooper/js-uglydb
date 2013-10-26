UglyDB specification
====================

UglyDB makes your JSON table data small by normalizing it and truncating floats.

What do you mean, "JSON table data"?
------------------------------------

We mean tables of records, such as this:

| id | name | food | servings |
| -- | ---- | ---- | -------- |
| 1 | Adam | Pizza | 1.2      |
| 2 | Charlie | Hamburger | 2.4123123 |
| 3 | Justine | Pizza | 1.3 |
| 4 | Paul | Hamburger | 2.3 |

In regular JSON, this would be expressed like so:

    [
      {
        "id": 1,
        "name": "Adam",
        "food": "Pizza",
        "servings": 1.2
      },
      {
        "id": 2,
        "name": "Charlie",
        "food": "Hamburger",
        "servings": 2.4123123
      },
      {
        "id": 3,
        "name": "Justine",
        "food": "Pizza",
        "servings": 1.3
      }
      {
        "id": 4,
        "name": "Paul",
        "food": "Hamburger",
        "servings": 2.3
      }
    ]

UglyDB can handle more complex data than CSV, but less complex data than pure JSON. Here is what UglyDB supports:

* UglyDB encodes an Array.
* Each element of the Array must be an Object. (Let's call it a "**record**" for the rest of this document.)
* Each key in each of those Objects must be a String.
* Each value in each of those Objects can be any JSON object.
* All records must have values for all keys. (If this isn't the case, UglyDB will be lossy: there will be no way to distinguish between `null` and `undefined`.)

Just because UglyDB _supports_ a particular set of JSON data doesn't mean it will compress it very well. UglyDB works best with a certain kind of data. In general:

* UglyDB removes record keys, as a CSV does. If you have small amounts of data per key, UglyDB is a great fit.
* UglyDB removes duplicated Strings. If you have lots of duplicated Strings (for instance, a "type" column), UglyDB is a great fit.
* UglyDB removes duplicated Numbers. If you have lots of large (or precise), duplicated Numbers, UglyDB is a good fit.
* All records' values under a given key should be of the same type (i.e., Number, String, Object, or Array; null is allowed.) If you're mixing Numbers with Strings, for instance, UglyDB can't shrink them.
* UglyDB doesn't transform Arrays or nested Objects (that is, Objects which are themselves values in a record). If you have lots of this kind of data, UglyDB might _not_ be a good fit.

(When writing UglyDB, developers may choose to round floats. That does reduce file size, but it doesn't affect this specification.)

What is UglyDB format?
----------------------

In UglyDB format, the above-written JSON array will look like this:

    [
      "http://git.io/uglydb-0.1",                       _// 1. specification (optional)_
      [ "id", 1, "name", 2, "food", 2, "servings", 1 ], _// 2. header_
      [                                                 _// 3. records_
        1, "Adam", 0, 1.2,
        2, "Charlie", 1, 2.4123123,
        3, "Justine", 0, 1.3,
        4, "Paul", 1, 2.3
      ],
      []                                                _// 4. normalizedObjects (optional)_
      "|Pizza|Hamburger",                               _// 5. normalizedStrings (optional)_
    ]

UglyDB is valid JSON data. It doesn't need to be _parsed_: it needs to be _translated_. We don't deal with encodings: we deal in characters, not bytes.

What follows is a description of each component of the file. This specification should include all the information necessary to translate any UglyDB JSON into regular JSON.

### 1. Specification

The specification is a String URL describing the format of the file. It is optional.

A parser should throw an error if it is not aware of the given specification URL. It should do nothing if the URL is not present.

### 2. Header

The header must be an Array. (Otherwise, it's an error.)

The header must have an even number of entries. (Otherwise, it's an error.)

For each pair of values in the Array:

* The first value must be a String. (Otherwise, it's an error.) The String is a column name. (If two columns share the same name, it's an error.) For the purpose of this specification, we'll refer to the column name a record's **key**.
* The second value must be `1`, `2` or `3`. (Otherwise, it's an error.) This is the **type** of the column.

Here are the column types:

| type | name    | description |
| ---- | ------- | ----------- |  
| 1    | Any     | Stores any value, never normalized. |
| 2    | Any     | Stores any value, always normalized. |
| 3    | String  | Stores Strings, potentially normalized. `-1` means `null`. |

For brevity further on, let's refer to the number of keys (which is the length of the header Array divided by two) as **nColumns**.

### 3. Records

The records must be an Array. (Otherwise, it's an error.)

The number of values in the records Array must be a multiple of the number of keys in the header. (Otherwise, it's an error.) Divide the records length by nColumns to receive **nRecords**. In other words, `recordsArray.length == nColumns * nRecords`.

Reading the records Array from beginning to end, each batch of nColumns values corresponds to a single record.

Each record, then, starts as a conceptual Array of nColumns values. The first value corresponds to the first key in the header; the second value corresponds to the second key; and so on.

For instance, given this file:

    [
      "http://git.io/uglydb-0.1",                       _// 1. specification (optional)_
      [ "id", 1, "name", 2, "food", 2, "servings", 1 ], _// 2. header_
      [                                                 _// 3. records_
        1, "Adam", 0, 1.2,
        2, "Charlie", 1, 2.4123123,
        3, "Justine", 0, 1.3,
        4, "Paul", 1, 2.3
      ],
      "|Pizza|Hamburger",                               _// 5. normalizedStrings (optional)_
      []                                                _// 4. normalizedObjects (optional)_
    ]

The values `1, "Adam", 0, 1.2` make up the first record. Those values' keys are `"id"`, `"name"`, `"food"` and `"servings"`, respectively.

When translating those values, we must consider the columns' types. This amounts to some logic:

1. If `type == 1`, take the value as-is. (For instance, in the given example, the value `1` is a Number.)
2. If `type == 2`, the value is normalized in **normalizedObjects** (see below). Treat it as an index into `normalizedObjects`.
    * If the index exceeds the bounds of the `normalizedObjects` Array, it's an error.
3. If `type == 3`, the value _may_ be normalized in **normalizedStrings** (see below). Apply this logic:
    * If the value is `-1`, translate it to `null`.
    * If the value is a String, take it as-is. (For instance, in the given example, the value `"Adam"` is a String and it means `"Adam"`.)
    * If the value is a Number, treat it as an index into `normalizedStrings`. (For instance, in the given example, the value `0` is a Number, an index into `normalizedStrings`. It translates to `normalizedStrings[0]`, which is `Pizza`.)
            * If the index exceeds the bounds of the `normalizedStrings` Array, it's an error.

### 4. normalizedObjects

If there is a column with `type == 2`, there must exist a `normalizedObjects` Array. If there is no `type == 2` column, there must not exist a normalizedObjects Array. If these conditions aren't met, it's an error.

The values in `normalizedObjects` may be of any type.

### 5. normalizedStrings

Conceptually, normalizedStrings is an Array of Strings. One accesses it according to the logic described previously.

In UglyDB, normalizedStrings is _encoded_ as a String.

If there is a column with `type == 2`, there must exist a normalizedStrings String. If there is no `type == 2` column, there must not exist a normalizedStrings String. If these conditions aren't met, it's an error.

Looking at the same example: take the encoded String, `"|Pizza|Hamburger"`:

* The first character is the **separator**.
* The remainder of the String is the payload. Split it by `separator` to create `normalizedStrings`.

In JavaScript, we could express this logic like so:

    var encodedNormalizedStrings = "|Pizza|Hamburger";
    var separator = encodedNormalizedStrings.charAt(0);
    var normalizedStrings = encodedNormalizedStrings.split(separator).slice(1);
    // normalizedStrings is now [ "Pizza", "Hamburgers" ]

The `separator` isn't necessarily `|`. It could be any single character. (Why? Because if one of the normalized Strings contained `|` it would break everything.)

Reference implementation
------------------------

This repository includes a reference implementation for translating to and from UglyDB format. It also includes examples of JSON files packed in UglyDB format.

Different implementations needn't encode a given JSON file to exactly the same UglyDB file. With UglyDB, there are several ways to encode the same JSON.

License
-------

This specification is released under the public domain. (See UNLICENSE.)
