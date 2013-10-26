define ->
  class StringNormalizationDb
    constructor: (@indexes, @normalizationString) ->

    get: (s) ->
      if s?
        @indexes[s] ? s
      else
        -1

  # Helps normalize a set of Strings.
  #
  # Usage:
  #
  #   normalizer = new StringNormalizer()
  #   for string in getAllStrings() # may be duplicates
  #     normalizer.add(string)
  #
  #   stringDb = normalizer.asDb()
  #   stringDb.get(string) # returns either an index or a string
  #   stringDb.get(null) # returns -1
  #   stringDb.normalizationString # returns the string the indices point into
  #
  # A StringNormalizer does not need to normalize every string: it chooses the
  # strings that are frequent enough to warrant the effort.
  class StringNormalizer
    constructor: ->
      @_counts = {} # string -> count

    # Adds a string for normalization.
    #
    # You should call this once for every string in the file. If the same
    # string occurs multiple times in the file, call add() multiple times. This
    # is important information, useful during compression.
    add: (string) ->
      @_counts[string] ?= 0
      @_counts[string] += 1

    # Returns an object which can translate strings into indexes.
    #
    # Call this after all calls to add(). With the result, call get(string) to
    # return the canonical representation of each string; access
    # .normalizationString to see the string version of the normalized list of
    # strings.
    asDb: ->
      words = ({ string: string, count: count } for string, count of @_counts)
        # Don't normalize unique strings: it can only hurt
        .filter((w) -> w.count > 1)
        # Sort words from most-frequent to least-frequent, so more-frequent
        # words will come earlier in the Array and thus take fewer characters to
        # index.
        #
        # Also sort using the order the string was first inserted, to simulate a
        # stable sort, to make tests consistent.
        .sort((a, b) -> (b.count - a.count) || a.string.localeCompare(b.string))

      indexes = @indexes = {}
      strings = ['']

      for word, i in words
        string = word.string
        indexes[string] = i
        strings.push(string)

      normalizationString = if words.length > 0
        strings.join('|')
      else
        null

      new StringNormalizationDb(indexes, normalizationString)
