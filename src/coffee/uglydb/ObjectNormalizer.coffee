define ->
  # Helps normalize a set of Objects.
  #
  # Usage:
  #
  #   normalize = new ObjectNormalizer()
  #   for column in getAllNonStringColumns() # use StringNormalizer for Strings
  #     for record in getAllRecords()
  #       normalizer.add(column, record[column])
  #
  #   db = normalizer.asDb()
  #   db.keys # Array of column names worth normalizing
  #   db.get(value) # returns the index of the value
  #   db.normalizationArray # The Array the indices point into
  #
  # An ObjectNormalizer _must_ normalize every value in a given column. Some
  # columns (ones with duplicates) can benefit from this; other columns can't.
  # If `db.keys` is empty, then normalization won't help at all.
  #
  # See also StringNormalizer. It's a more efficient way to normalize columns
  # that only contain Strings or null.
  class ObjectNormalizer
    constructor: ->
      @objects = {} # JSON representation -> { counts, length, object }
      @nObjects = 0
      @columnSet = {} # key -> null

    add: (column, object) ->
      if column not of @columnSet
        @columnSet[column] = null

      s = JSON.stringify(object)
      if s not of @objects
        @objects[s] = { counts: {}, length: s.length, object: object }
        @nObjects += 1

      counts = @objects[s].counts
      if column not of counts
        counts[column] = 0
      counts[column] += 1

      undefined

    # Returns the number of characters the column is using.
    #
    # This number is exact (though it's not encoding-aware). It doesn't include
    # the cost of the commas surrounding the values, since those can't be
    # avoided.
    #
    # For example: if the column has values 3, "hello" and null, the cost is
    # 1 + 7 + 4 = 12
    _costOfColumnAsIs: (key) ->
      cost = 0
      for __, object of @objects
        cost += object.length * (object.counts[key] ? 0)
      cost

    # Returns the number of characters the column would cost after normalizing.
    #
    # This number is a guess. It depends on indices, but those indices depend
    # on which other columns are being normalized. We assume the highest cost:
    # that is, if _all_ columns were being normalized and these ones' indices
    # were distributed at the end of the list and these values never occur in
    # other columns. (This makes the math easy and lets us consider each column
    # independently.)
    _worstCaseCostOfColumnNormalized: (key) ->
      indexCost = Math.floor(Math.log(@nObjects))

      cost = 0
      for __, object of @objects
        count = object.counts[key]

        if count
          cost += object.length + indexCost * count

      cost

    _findColumnsWorthNormalizing: ->
      ret = []
      for column, __ of @columnSet
        a = @_costOfColumnAsIs(column)
        b = @_worstCaseCostOfColumnNormalized(column)
        if b < a
          ret.push(column)
      ret

    asDb: ->
      keys = @_findColumnsWorthNormalizing()

      if keys.length
        objectsToNormalize = []
        for json, entry of @objects
          counts = entry.counts
          normalizedCount = 0
          for key in keys
            normalizedCount += counts[key] ? 0
          if normalizedCount > 0
            objectsToNormalize.push
              json: json
              object: entry.object
              count: normalizedCount

        objectsToNormalize.sort((a, b) -> b.count - a.count)
        normalizationArray = objectsToNormalize.map((x) -> x.object)
        jsonToIndex = {}
        for entry, index in objectsToNormalize
          jsonToIndex[entry.json] = index
      else
        normalizationArray = jsonToIndex = null

      {
        keys: keys
        normalizationArray: normalizationArray
        get: (o) -> s = JSON.stringify(o); jsonToIndex[s]
      }
