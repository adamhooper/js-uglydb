define [ 'uglydb/write' ], (write) ->
  describe 'write', ->
    it 'should not write a non-Array', ->
      expect(-> write({ id: 4 })).toThrow()

    it 'should not write an Array in which not all elements are objects', ->
      expect(-> write([{ id: 3 }, 3])).toThrow()

    it 'should not write an Array in which an element is an Array', ->
      # Array is special because Object([]) is itself
      expect(-> write([{ id: 3 }, []])).toThrow()

    describe 'writing an empty Array', ->
      result = undefined

      beforeEach -> result = write([])

      it 'should write the spec name', ->
        expect(result[0]).toBe("http://git.io/uglydb-0.1")

      it 'should write an empty header', ->
        expect(result[1]).toEqual([])

      it 'should write an empty records array', ->
        expect(result[2]).toEqual([])

      it 'should not write anything else', ->
        expect(result.length).toEqual(3)

    describe 'writing an Array of objects', ->
      result = undefined

      beforeEach ->
        result = write([
          { id: 1, string: 'foo' }
          { id: 2, string: 'bar' }
          { id: 3, string: 'foo' }
          { id: 4, string: 'foo' }
        ])

      it 'should write a header with the appropriate keys', ->
        header = result[1]
        expect(header.length).toEqual(4)

        # Columns can come in any order, really
        if header[0] == 'string'
          expect(header[0]).toEqual('string')
          expect(header[2]).toEqual('id')
        else
          expect(header[0]).toEqual('id')
          expect(header[2]).toEqual('string')

      it 'should give ids a type of 1', ->
        header = result[1]
        idx = header.indexOf('id')
        type = header[idx + 1]
        expect(type).toEqual(1)

      it 'should give strings a type of 3 (string)', ->
        header = result[1]
        idx = header.indexOf('string')
        type = header[idx + 1]
        expect(type).toEqual(3)

      it 'should output a single array for all records', ->
        records = result[2]
        expect(records.length).toEqual(8)

      it 'should output the ids as-is', ->
        records = result[2]
        expect(records[0]).toEqual(1)
        expect(records[2]).toEqual(2)
        # and so on

    describe 'writing an Array of objects with strings and nulls', ->
      result = undefined

      beforeEach ->
        result = write([
          { string: 'foo' }
          { string: 'bar' }
          { string: 'foo' }
          { string: null }
        ])

      it 'should still give strings a type of 3', ->
        header = result[1]
        expect(header[1]).toEqual(3)

    describe 'writing an Array that would benefit from string normalization', ->
      array = undefined
      result = undefined

      beforeEach ->
        array = [
          { string: 'foo' }
          { string: 'foo' }
          { string: 'foo' }
          { string: 'foo' }
          { string: 'foo' }
          { string: 'foo' }
          { string: 'foo' }
          { string: 'bar' }
          { string: null }
        ]
        result = write(array)

      it 'should output a normalization string', ->
        expect(result[3]).toEqual('|foo')

      it 'should translate strings to indices', ->
        expect(result[2][0]).toEqual(0)

      it 'should not translate non-normalized strings', ->
        expect(result[2][7]).toEqual('bar')

      it 'should translate null to -1', ->
        expect(result[2][8]).toEqual(-1)

      it 'should not modify the original array', ->
        expect(array[0].string).toEqual('foo')

    it 'should not round floats by default', ->
      result = write([ { float: 3.141593 } ])
      expect(result[2][0].toString()).toEqual('3.141593')

    it 'should round floats when precision is given', ->
      result = write([ { float: 3.141593 } ], { precision: 3 })
      expect(result[2][0].toString()).toEqual('3.142')

    it 'should not modify the original Array when rounding', ->
      array = [ { float: 3.141593 } ]
      write(array)
      expect(array[0].float.toString()).toEqual('3.141593')

    describe 'writing an Array that would benefit from non-String normalization', ->
      array = undefined
      result = undefined

      beforeEach ->
        array = [
          { float: 3.141592 }
          { float: 3.141592 }
          { float: 3.141592 }
          { float: 3.141592 }
          { float: 3.141592 }
          { float: 3.141592 }
          { float: 3.141592 }
          { float: 2 }
          { float: 2 }
          { float: null }
        ]
        result = write(array)

      it 'should give the column type 2', ->
        header = result[1]
        expect(header[1]).toEqual(2)

      it 'should transform the column', ->
        expect(result[2]).toEqual([ 0, 0, 0, 0, 0, 0, 0, 1, 1, 2 ])

      it 'should append the normalization objects', ->
        expect(result[result.length - 1]).toEqual([ 3.141592, 2, null ])

      it 'should not include a normalization string when there is no need', ->
        expect(result.length).toEqual(4)

    describe 'writing an Array where one column benefits from normalization and one does not', ->
      array = undefined
      result = undefined

      beforeEach ->
        array = [
          { int: 1, float: 3.141592 }
          { int: 2, float: 3.141592 }
          { int: 3, float: 3.141592 }
          { int: 4, float: 3.141592 }
          { int: 5, float: 3.141592 }
          { int: 6, float: 3.141592 }
          { int: 7, float: 3.141592 }
          { int: 8, float: 2 }
          { int: 9, float: 2 }
          { int: null, float: null }
        ]
        result = write(array)

      it 'should leave type=1 for the type that should not be normalized', ->
        header = result[1]
        if header[0] == 'int'
          intType = header[1]
          floatType = header[3]
        else
          intType = header[3]
          floatType = header[1]

        expect(intType).toEqual(1)
        expect(floatType).toEqual(2)

      it 'should not translate values that should not be normalized', ->
        records = result[2]
        expect(records[16]).toEqual(9)
        expect(records[18]).toBe(null)

      it 'should translate values that should be normalized', ->
        records = result[2]
        expect(records[17]).toEqual(1)
        expect(records[19]).toEqual(2)

      it 'should translate values _after_ rounding them', ->
        result = write(array, precision: 2)
        objects = result[3]
        expect(objects[0]).toEqual(3.14)
