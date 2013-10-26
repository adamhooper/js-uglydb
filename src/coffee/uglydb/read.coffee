define ->
  SPEC_URL = "http://git.io/uglydb-0.1"
  toString = Object.prototype.toString
  isString = (s) -> toString.call(s) == '[object String]'

  # Given uglydb, returns { specUrl, keys, records, stringArray, objectArray }
  #
  # "keys" is an Array of { key, type } Objects
  uglydbToObject = (uglydb) ->
    if !Array.isArray(uglydb)
      throw new Error("Invalid uglydb JSON: it must be an Array. See #{SPEC_URL}")

    ret =
      specUrl: null
      keys: null
      records: null
      stringArray: null
      objectArray: null

    uglyIndex = 0 # our cursor as we iterate over uglydb

    if isString(uglydb[uglyIndex])
      ret.specUrl = uglydb[uglyIndex]
      uglyIndex += 1
      if ret.specUrl != SPEC_URL
        throw new Error("Expected uglydb JSON to have spec #{SPEC_URL}, but its spec is #{ret.specUrl}")

    if !Array.isArray(uglydb[uglyIndex])
      throw new Error("Expected uglydb header to be an Array. See #{SPEC_URL}")

    invalidArrayFormat = -> new Error("Expected uglydb header to have format [ \"key1\", 3, \"key2\", 1, ... ]. See #{SPEC_URL}")

    header = uglydb[uglyIndex]
    uglyIndex += 1

    throw invalidArrayFormat() if header.length % 2 != 0

    keys = ret.keys = []
    needStrings = false
    needObjects = false

    for i in [ 0 ... header.length ] by 2
      key = header[i]
      type = header[i + 1]

      needObjects = true if type == 2
      needStrings = true if type == 3

      throw invalidArrayFormat() if !isString(key)
      if type != 1 && type != 2 && type != 3
        throw new Error("Type #{JSON.stringify(type)} in the header is not a key type. Valid key types are 1, 2 and 3. See #{SPEC_URL}")

      keys.push({ key: key, type: type })

    if !Array.isArray(uglydb[uglyIndex])
      throw new Error("Expected uglydb records array to be an Array. See #{SPEC_URL}")

    ret.records = uglydb[uglyIndex]
    uglyIndex += 1

    if (keys.length > 0 && ret.records.length % keys.length != 0) || (keys.length == 0 && ret.records.length > 0)
      throw new Error("The records array has #{ret.records.length} values, but it needs a multiple of #{keys.length}. See #{SPEC_URL}")

    if needStrings
      string = uglydb[uglyIndex]
      uglyIndex += 1
      if !isString(string)
        throw new Error("There is a column of type 3 but there is no String array. See #{SPEC_URL}")
      ret.stringArray = string.split(string.charAt(0)).slice(1)

    if needObjects
      if !Array.isArray(uglydb[uglyIndex])
        throw new Error("There is a column of type 2 but there is no Object array. See #{SPEC_URL}")
      ret.objectArray = uglydb[uglyIndex]

    ret

  # Translates "ugly" JSON back into the original, verbose JSON.
  (uglydb) ->
    uglyObject = uglydbToObject(uglydb)

    keyNames = (key.key for key in uglyObject.keys)
    keyTypes = (key.type for key in uglyObject.keys)

    normalizedStrings = uglyObject.stringArray
    normalizedObjects = uglyObject.objectArray

    ret = []
    obj = {} # working object
    keyIndex = 0
    for rawValue in uglyObject.records
      type = keyTypes[keyIndex]

      value = switch keyTypes[keyIndex]
        when 1 then rawValue
        when 2
          if rawValue < 0 || rawValue >= normalizedObjects.length
            throw new Error("A normalized object is requested at index #{rawValue} but the maximum index is #{normalizedObjects.length - 1}. See #{SPEC_URL}")
          normalizedObjects[rawValue]
        when 3
          if rawValue < 0
            null
          else if rawValue >= normalizedStrings.length
            throw new Error("A normalized string is requested at index #{rawValue} but the maximum index is #{normalizedStrings.length - 1}. See #{SPEC_URL}")
          else
            normalizedStrings[rawValue]

      obj[keyNames[keyIndex]] = value

      keyIndex += 1
      if keyIndex == keyNames.length
        ret.push(obj)
        obj = {}
        keyIndex = 0

    ret
