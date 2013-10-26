define [ 'uglydb/StringNormalizer' ], (StringNormalizer) ->
  describe 'StringNormalizer', ->
    subject = undefined

    beforeEach ->
      subject = new StringNormalizer()

    it 'should map null to -1', ->
      expect(subject.asDb().get(null)).toBe(-1)

    it 'should not give a normalizationString', ->
      expect(subject.asDb().normalizationString).toBe(null)

    describe 'with only a unique string', ->
      beforeEach -> subject.add('foo')

      it 'should map an input string back to the same string', ->
        expect(subject.asDb().get('foo')).toEqual('foo')

      it 'should not give a normalizationString', ->
        expect(subject.asDb().normalizationString).toBe(null)

    describe 'with a duplicated string', ->
      beforeEach -> subject.add('foo'); subject.add('foo')

      it 'should map an input string to 0', ->
        expect(subject.asDb().get('foo')).toEqual(0)

      it 'should give a normalizationString with "|" as word separator', ->
        expect(subject.asDb().normalizationString).toEqual('|foo')

    it 'should split by , when | is taken', ->
      subject.add('fo|o'); subject.add('fo|o')

    it 'should split by something else when , and | are taken', ->
      subject.add(',|!@#$ ~'); subject.add(',|!@#$ ~')
      expect(subject.asDb().normalizationString).toEqual('%,|!@#$ ~')

    it 'should sort more-frequent strings before less-frequent ones', ->
      subject.add('foo') for i in [ 0 .. 10 ]
      subject.add('bar') for i in [ 0 .. 20 ]

      db = subject.asDb()

      expect(db.get('foo')).toEqual(1)
      expect(db.get('bar')).toEqual(0)
      expect(db.normalizationString).toEqual('|bar|foo')

    it 'should not translate a string when the translation would not save any characters', ->
      for i in [ 0 .. 100 ]
        for j in [ 0 .. 2 ]
          subject.add(String(i))

      db = subject.asDb() # 0, 1, 10, 100, 11, 12, 13, ..., all with equal counts

      # Given a string, returns the number of characters of the output JSON.
      # We do not return the number of bytes because we do not deal with
      # encodings.
      trlen = (s) -> JSON.stringify(db.get(s)).length

      for i in [ 0 .. 100 ]
        expect(trlen(String(i))).toBeLessThan(JSON.stringify(String(i)).length + 1)


