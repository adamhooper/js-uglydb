define [
  './StringNormalizer'
  './ObjectNormalizer'
], (StringNormalizer, ObjectNormalizer) ->
  toString = Object.prototype.toString
  isString = (s) -> toString.call(s) == '[object String]'
  isNumber = (s) -> toString.call(s) == '[object Number]'

  # Returns an Object mapping id to type
  findKeys = (array) ->
    keys = {}
    for object in array
      for key, value of object
        if key not of keys
          keys[key] = 3 # start by assuming everything is a string

    for key, __ of keys
      for object in array
        value = object[key]
        if value != null && !isString(value)
          keys[key] = 1
          break

    keys

  # Turns a keys object (see findKeys()) into an output Array
  keysToHeader = (keys) ->
    ret = []
    for key, type of keys
      ret.push(key)
      ret.push(type)
    ret

  # Turns a header object into just a list of keys.
  #
  # This ensures the keys are in the same order as they are in the output
  # Array.
  headerToKeyNames = (header) ->
    for i in [ 0 ... (header.length / 2) ]
      header[i * 2]

  # Where appropriate, replaces Strings with indices in an Array.
  #
  # Returns the normalization string, or null if no normalization was done.
  maybeNormalizeStrings = (array, keys) ->
    usefulKeys = (key for key, type of keys when type == 3)

    normalizer = new StringNormalizer()
    for key in usefulKeys
      for object in array
        value = object[key]
        normalizer.add(value) if value?

    db = normalizer.asDb()
    if db.normalizationString?
      for key in usefulKeys
        for object in array
          object[key] = db.get(object[key])
      db.normalizationString
    else
      null

  # Where appropriate, replaces Object values with indices in an Array.
  #
  # Modifies allKeys in-place, possibly changing some keys of type 1 to type 2.
  #
  # Returns the normalization array, or null when no normalization was done.
  maybeNormalizeObjects = (array, allKeys) ->
    nonStringKeys = (key for key, type of allKeys when type == 1)

    normalizer = new ObjectNormalizer()
    for key in nonStringKeys
      for object in array
        value = object[key]
        normalizer.add(key, value) # even null

    db = normalizer.asDb()

    if db.keys.length
      for key in db.keys
        allKeys[key] = 2
        for object in array
          object[key] = db.get(object[key])
      db.normalizationArray
    else
      null

  # Modifies array in-place, rounding Numbers.
  roundFloats = (array, keys, precision) ->
    p = Math.pow(10, precision)

    for key, type of keys when type == 1
      for object in array
        value = object[key]
        if isNumber(value)
          object[key] = Math.round(value * p) / p

    undefined

  # Translates a JSON array of homogeneous objects into an UglyDB JSON array.
  (array, options) ->
    if !Array.isArray(array) || \
        !array.every((o) -> o == Object(o) && !Array.isArray(o))
      throw 'UglyDB can only encode an Array of homogeneous Objects'

    # don't modify the original. While we're at it, this protects us from
    # functions, dates, etc.
    array = JSON.parse(JSON.stringify(array))

    keys = findKeys(array)

    normalizationString = maybeNormalizeStrings(array, keys)

    if options?.precision?
      roundFloats(array, keys, options.precision)

    normalizationArray = maybeNormalizeObjects(array, keys)

    headerArray = keysToHeader(keys)
    keysList = headerToKeyNames(headerArray)

    records = []
    for object in array
      for key in keysList
        records.push(object[key])

    ret = [
      "http://git.io/uglydb-0.1"
      headerArray
      records
    ]
    ret.push(normalizationString) if normalizationString?
    ret.push(normalizationArray) if normalizationArray?

    ret
