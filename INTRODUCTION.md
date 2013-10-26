UglyDB - an introduction
========================

UglyDB makes your JSON table data small by normalizing it and truncating floats.

What does that mean?
--------------------

This library is made to transfer tables of records without consuming much bandwidth or memory.

Tables of records look like this:

| id | name | food | servings |
| -- | ---- | ---- | -------- |
| 1 | Adam | Pizza | 1.2      |
| 2 | Charlie | Hamburger | 2.4123123 |
| 3 | Justine | Pizza | 1.3 |
| 4 | Paul | Hamburger | 2.3 |

If we were to transfer this as JSON, we'd come up with this:

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

There are several ways we can make this smaller.

### Remove whitespace

This almost goes without saying.

After removing whitespace, the JSON still takes 232 bytes. Let's shrink it.

### Truncate floats

Often, we don't need `servings` to be so precise. Heck, sometimes it's incorrect anyway, because of a rounding error somewhere along the line. If we call it an even `2.4`, we save six bytes.

On the commandline, use `--precision=1` to truncate to one decimal place. In code, use the option `{ precision: 1 }`.

We're down to 226 bytes now.

### Use a header row

Next, you'll notice that column names are repeated. We can solve this by rewriting the Array to something closer to a CSV. For illustration, picture this:

    [
      [ "id", "name", "food", "servings" ],
      [ 1, "Adam", "Pizza", 1.2 ],
      [ 2, "Charlie", "Hamburger", 2.4 ],
      [ 3, "Justine", "Pizza", 1.3 ],
      [ 4, "Paul", "Hamburger", 2.3 ]
    ]
    
This brings us down to 139 bytes.

Notice that it now looks a bit like a CSV. It's different in two main ways:

1. This JSON format is simpler to parse than a CSV; and
2. This JSON format takes more space than a CSV. (The CSV takes 104 bytes.)

Our goal is to save space while still being reasonably efficient; let's forge ahead.

### Flatten the list

Now we have a notion of a schema, so it's easy to remove four characters by taking advantage of it:

    [
      [ "id", "name", "food", "servings" ],
      [
        1, "Adam", "Pizza", 1.2,
        2, "Charlie", "Hamburger", 2.4,
        3, "Justine", "Pizza", 1.3,
        4, "Paul", "Hamburger", 2.3
      ]
    ]
    
Now we're at 133 bytes.

### Normalize strings

Notice that the word "Pizza" appears twice. We can solve that, by creating a separate "Strings" array and indexing into it.

To do that, we need to complicate our schema somewhat, by specifying a type for each column. Let's do that in a space-efficient way: by using an integer. Now, in the header row, type `1` means "as-is" and type `2` means "string":

    [
      [ "id", 1, "name", 2, "food", 2, "servings", 1 ],
      [
        1, 0, 1, 1.2,
        2, 2, 3, 2.4,
        3, 4, 1, 1.3,
        4, 5, 3, 2.3
      ],
      [ "Adam", "Pizza", "Charlie", "Hamburger", "Justine", "Paul" ]
    ]
    
See how we only used the word "Pizza" once?

In this particular example, we didn't actually save space: we jumped from 133 to 139 bytes. That's because the strings don't repeat themselves very often.

But we should probably keep it anyway, for the next optimization.

### Join strings

Notice that the most common characters are quotation marks and commas. Can we reduce their numbers?

We can, by finding a unique character to join our strings together with. Let's use `|` for illustration. (We'll encode it into the JSON; we can use any character, as long as it doesn't appear in the actual dataset, and as long as we stay below three UTF bytes we'll save space.)

    [
      [ "id", 1, "name", 2, "food", 2, "servings", 1 ],
      [
        1, 0, 1, 1.2,
        2, 2, 3, 2.4,
        3, 4, 1, 1.3,
        4, 5, 3, 2.3
      ],
      "|Adam|Pizza|Charlie|Hamburger|Justine|Paul"
    ]
    
Now we're down to 128 bytes. If our dataset included just two more hamburgers, UglyDB would be as small as a an equivalent CSV. The more duplicate strings there are, the greater the savings.

### Being smart about optimizations

By the way: should we put the headers in the string, too? Let's see if it saves bytes:

    [
      [ 6, 1, 7, 2, 8, 2, 9, 1 ],
      [
        1, 0, 1, 1.2,
        2, 2, 3, 2.4,
        3, 4, 1, 1.3,
        4, 5, 3, 2.3
      ],
      "|Adam|Pizza|Charlie|Hamburger|Justine|Paul|id|name|food|servings"
    ]

It's still 128 bytes, so in this particular file, it's not a worthwhile change. It _would_ be worthwhile if the strings in the headers were repeated elsewhere in the file.

Actually, we can generalize this logic. Notice that a normalized string costs one byte of overhead for the `|`, plus one or more bytes of overhead on each reference (the integer index).

Let's do math. Here's what it costs to store a single string in the original and ugly versions of a JSON file:

    costOriginal = lengthOfString + 2
    costUgly = lengthOfString / nOccurrencesOfString + 1 + log(indexInNormalizedString)
    
From this, we can derive promising rules:

* Don't normalize a unique string: it won't save any space, and it may increase the cost of all strings (because `indexInNormalizedString` will grow for other strings in the file).
* Reorder normalized strings such that the most-frequent is the first in the normalized list. That will make its index take up fewer bytes.

In this particular file, these rules won't actually improve our space efficiency (since `indexInNormalizedString < 10` throughout); but let's apply the rule anyway, for completeness' sake:

    [
      [ "id", 1, "name", 2, "food", 2, "servings", 1 ],
      [
        1, "Adam", 0, 1.2,
        2, "Charlie", 1, 2.4,
        3, "Justine", 0, 1.3,
        4, "Paul", 1, 2.3
      ],
      "|Pizza|Hamburger"
    ]

That's still 128 bytes, and it promises more savings as we add more rows and normalize more strings.

### Normalizing floats, Arrays, etc.

It's worth a shot, right? We can normalize Numbers the same way we do strings (with an Array of Numbers and a new column "type", numbered 3). That wouldn't save space in this particular file, but it's easy to calculate whether it would in the file in question.

When we normalize Numbers, we can't be selective (as we are with Strings): we need to put them _all_ into the array.

We can also normalize arrays-of-numbers, arrays-of-strings, hash-of-numbers, hash-of-strings, and so forth. Each would need its own type number.

This library is architected to eventually support such optimizations ... but at a certain point, the effort becomes excessive because it helps too few people. So for the present, this library normalizes integers and nothing else.

### Adding a spec

Part of JSON's charm is that it's readable, right? Let's help people un-uglify. We add the (optional) string `"http://git.io/uglydb-0.1"` at the start of the file so perusers can understand the file format and how to read it.

If those characters really matter, add `--no-spec-url` or set `{ specUrl: false }`.
