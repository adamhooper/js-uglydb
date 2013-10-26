define [ 'uglydb/ObjectNormalizer' ], (ObjectNormalizer) ->
  describe 'ObjectNormalizer', ->
    subject = undefined

    beforeEach ->
      subject = new ObjectNormalizer()

    describe 'with no data', ->
      it 'should not recommend any keys', ->
        expect(subject.asDb().keys).toEqual([])

      it 'should give a null normalizationArray', ->
        expect(subject.asDb().normalizationArray).toBe(null)

    describe 'with data not worth normalizing', ->
      db = undefined

      beforeEach ->
        subject.add('object', { id: 1, name: 'foo' })
        subject.add('object', { id: 2, name: 'bar' })
        db = subject.asDb()

      it 'should not normalize anything', ->
        expect(db.keys).toEqual([])
        expect(db.normalizationArray).toBe(null)

    describe 'with data worth normalizing', ->
      db = undefined

      beforeEach ->
        # A column not worth normalizing (lots of unique values)
        subject.add('id', 1)
        subject.add('id', 2)
        subject.add('id', 3)

        # A column worth normalizing (big duplicates)
        subject.add('object', { id: 1, name: 'foo' })
        subject.add('object', { id: 1, name: 'foo' })
        subject.add('object', { id: 1, name: 'foo' })
        subject.add('object', { id: 2, name: 'bar' })
        # Including mixed types...
        subject.add('object', 'foo')
        subject.add('object', null)
        subject.add('object', null)
        subject.add('object', 2.13)

        db = subject.asDb()

      it 'should suggest normalizing the correct columns', ->
        expect(db.keys).toEqual([ 'object' ])

      it 'should have a normalizationArray', ->
        expect(db.normalizationArray.length).toEqual(5)

      it 'should sort the most common objects first', ->
        expect(db.normalizationArray[0]).toEqual({ id: 1, name: 'foo' })
        expect(db.normalizationArray[1]).toBe(null)

      it 'should get the index for an object', ->
        expect(db.get({ id: 1, name: 'foo' })).toEqual(0)

      it 'should get the index for null', ->
        expect(db.get(null)).toEqual(1)

      it 'should get the index for a String', ->
        expect(db.get('foo')).toBeGreaterThan(0)

      it 'should get the index for a Number', ->
        expect(db.get(2.13)).toBeGreaterThan(0)
