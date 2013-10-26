define [ 'uglydb/read' ], (read) ->
  describe 'read', ->
    # This follows the spec pretty heavily for finding and throwing errors.

    it 'should not read a non-Array', ->
      check = (fn) ->
        expect(fn)
          .toThrow(new Error('Invalid uglydb JSON: it must be an Array. See http://git.io/uglydb-0.1'))
      check(-> read({}))
      check(-> read(null))
      check(-> read(3.2))

    it 'should parse the simplest possible uglydb', ->
      result = read([ ['id', 1], [ 1 ] ])
      expect(result).toEqual([{ id: 1 }])

    it 'should throw an error if the spec is wrong', ->
      expect(-> read([ 'http://example.org', [ 'id', 1 ], [ 1 ] ]))
        .toThrow(new Error('Expected uglydb JSON to have spec http://git.io/uglydb-0.1, but its spec is http://example.org'))

    it 'should throw an error if the header is not an array', ->
      expect(-> read([ { id: 1 }, [ 1 ] ]))
        .toThrow(new Error('Expected uglydb header to be an Array. See http://git.io/uglydb-0.1'))

    it 'should throw an error if the header array has the wrong number of elements', ->
      expect(-> read([ [ 'id', 1, 'foo' ], [ 1, 2 ] ]))
        .toThrow(new Error('Expected uglydb header to have format [ "key1", 3, "key2", 1, ... ]. See http://git.io/uglydb-0.1'))

    it 'should throw an error if a header key is not a string', ->
      expect(-> read([ [ 'id', 1, 2, 3 ], [ 1, 2 ] ]))
        .toThrow(new Error('Expected uglydb header to have format [ "key1", 3, "key2", 1, ... ]. See http://git.io/uglydb-0.1'))

    it 'should throw an error if a header type is not 1, 2 or 3', ->
      expect(-> read([ [ 'id', 1, 'foo', 4 ], [ 1, 2 ] ]))
        .toThrow(new Error('Type 4 in the header is not a key type. Valid key types are 1, 2 and 3. See http://git.io/uglydb-0.1'))

    it 'should throw an error if the records array is not an Array', ->
      expect(-> read([ [ 'id', 1 ], { id: 1 }]))
        .toThrow(new Error('Expected uglydb records array to be an Array. See http://git.io/uglydb-0.1'))

    it 'should throw an error if the records array is not of the correct length', ->
      expect(-> read([ [ 'id', 1, 'foo', 1 ], [ 1, 2, 3 ]]))
        .toThrow(new Error('The records array has 3 values, but it needs a multiple of 2. See http://git.io/uglydb-0.1'))

    it 'should throw an error if the String array is missing', ->
      expect(-> read([ [ 'id', 3 ], [ 0 ] ]))
        .toThrow(new Error('There is a column of type 3 but there is no String array. See http://git.io/uglydb-0.1'))

    it 'should translate normalized strings', ->
      result = read([ [ 'foo', 3 ], [ 1, 0 ], "|foo|bar" ])
      expect(result).toEqual([
        { foo: 'bar' },
        { foo: 'foo' }
      ])

    it 'should translate normalized -1 as null', ->
      result = read([ [ 'foo', 3 ], [ -1 ], "|" ])
      expect(result).toEqual([ { foo: null } ])

    it 'should throw an error if the String array is missing an entry', ->
      expect(-> read([ [ 'id', 3 ], [ 1 ], "|foo" ]))
        .toThrow(new Error('A normalized string is requested at index 1 but the maximum index is 0. See http://git.io/uglydb-0.1'))

    it 'should throw an error if the Objects array is missing', ->
      expect(-> read([ [ 'id', 2 ], [ 0 ] ]))
        .toThrow(new Error('There is a column of type 2 but there is no Object array. See http://git.io/uglydb-0.1'))

    it 'should translate normalized objects', ->
      result = read([ [ 'foo', 2 ], [ 1, 0 ], [ 'foo', { bar: 1 } ] ])
      expect(result).toEqual([
        { foo: { bar: 1 } },
        { foo: 'foo' }
      ])

    it 'should throw an error if the Object array is missing an entry', ->
      expect(-> read([ [ 'id', 2 ], [ 1 ], [ 'foo' ] ]))
        .toThrow(new Error('A normalized object is requested at index 1 but the maximum index is 0. See http://git.io/uglydb-0.1'))

    it 'should work with 0 records, with headers', ->
      expect(read([ [ 'id', 1 ], []])).toEqual([])

    it 'should work with 0 records, with 0 headers', ->
      expect(read([ [], [] ])).toEqual([])
