UglyDB
======

UglyDB makes your tabular [JSON](http://www.json.org/) data smaller by normalizing it.

What kind of data does it handle?
---------------------------------

UglyDB is a format specifically designed to handle Arrays of homogeneous Objects. This is the sort of data you'd find in a database or CSV file.

For instance, UglyDB can losslessly translate data like this:

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

Into something a bit more cryptic that looks like this:

    [
      "http://git.io/uglydb-0.1",                       // 1. specification (optional)
      [ "id", 1, "name", 2, "food", 2, "servings", 1 ], // 2. header
      [                                                 // 3. records
        1, "Adam", 0, 1.2,
        2, "Charlie", 1, 2.4123123,
        3, "Justine", 0, 1.3,
        4, "Paul", 1, 2.3
      ],
      "|Pizza|Hamburger",                               // 4. normalizedStrings (optional)
      []                                                // 5. normalizedObjects (optional)
    ]

... and it translates the other way, too.

Why?
----

UglyDB can make some JSON objects smaller (and less memory-intensive). It works really well for files which contain duplicates of certain Strings: for instance, if your dataset has a `type` column.

It removes whitespace.

It can optionally truncate floats, which is nifty.

Parsing UglyDB is plenty fast: about [half the speed of parsing equivalent JSON](http://jsperf.com/reading-uglydb-vs-reading-json). The speed gain in downloading more than makes up for this.

Parsed UglyDB usually needs less memory than equivalent parsed JSON, which should put less load on the garbage collector.

UglyDB competes with CSV. CSV tends to work better when there _aren't_ any duplicate Strings in the file; UglyDB works better when there _are_. UglyDB is usually more convenient than CSV: it maintains objects' types and can handle complex JSON values, while CSV values can only be Strings.

To see some size comparisons, check out https://github.com/adamhooper/js-uglydb-examples. For instance, consider a Statistics Canada dataset of crime statistics which contains long, repeated strings:

| File format | Size (kb) | Size (kb gzipped) | compared to gzipped CSV |
| ----------- | --------- | ----------------- | ----------------------- |
| CSV         | 12,732    | 616               | 100%                    |
| JSON        | 20,541    | 688               | 112%                    |
| UglyDB JSON | 2,780     | 479               | 78%                     |

After compression, this particular file is 22% smaller in UglyDB format than in CSV (and it's faster to parse) and about 30% smaller in UglyDB format than in JSON. Larger savings (40% and beyond) are easy to attain.

How do I create an UglyDB file?
-------------------------------

On the command-line, you need NodeJS:

    npm install -g uglydb # once
    uglydb-zip < input-file.json > output-file.uglydb.json

In code, you need NodeJS, too:

    var jsonData = ...;
    var uglyDb = require('uglydb');
    var uglyJson = uglyDb.write(jsonData); // throws an error if UglyDB doesn't support this data

In both cases, UglyDB has certain options. On the command-line, `--like=this`. In JavaScript, you can pass an `options` parameter to `uglyDb.write()` as a second parameter. The `options` is an Object.

### Options

| command-line | JavaScript | default | description |
| ------------ | ---------- | ------- | ----------- |
| `--precision=3` | `{ precision: 3 }` | `null` | Rounds floating-point Numbers to take at most this number of decimal places. (With `precision=3`, `3.1415` becomes `3.142`, and `3.1` stays `3.1`. When `null` (the default), does not round Numbers. |

How do I read an UglyDB file?
-----------------------------

On the command-line, you need NodeJS:

    npm install -g uglydb # once
    uglydb-unzip < input-file.uglydb.json > output-file.json

In code, you can do it with NodeJS:

    var uglyJsonData = ...;
    var uglyDb = require('uglydb');
    var json = uglyDb.read(uglyJsonData); // throws an error if uglyJsonData is invalid

Or you can do it on your website with RequireJS:

    var uglyJsonData = ...;
    require([ 'uglydb-read' ], function(uglyDbRead) {
      var json = uglyDbRead(uglyJsonData); // throws an error if uglyJsonData is invalid
    });

Or you can do it on your website _without_ RequireJS. First you need a script tag:

    <script src="/path/to/uglydb-read.no-require.js"></script>

Now you can use this code:

    var uglyJsonData = ...;
    var json = uglyDb.read(uglyJsonData);

How would you acquire this uglyJsonData? Probably by downloading a JSON file through, say, [jQuery.ajax](http://api.jquery.com/jQuery.ajax/) (or by including JSON inline).

How does it work?
-----------------

See INTRODUCTION.md to see how the specification was derived.

See SPEC-0.1.md for an explanation of what an UglyDB file looks like. This contains all the information you need to read or write UglyDB files, and it should help you get started if you want to extend the format.

How can I contribute?
---------------------

Start the development environment:

```
sudo npm install -g grunt-cli
npm install
grunt develop
```

Now edit `test/coffee/**/*.coffee` to make something fail, then edit `src/coffee/**/*.coffee` until everything passes.

Run `grunt` to update the `dist/` directory.

Please send pull requests. I prefer pull requests _with tests_, whether or not any code accompanies them.

License?
--------

Public Domain. See UNLICENSE.
