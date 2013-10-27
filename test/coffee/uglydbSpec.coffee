define [ 'uglydb' ], (uglydb) ->
  describe 'uglydb', ->
    it 'should have a read() function', ->
      expect(typeof uglydb.read).toEqual('function')

    it 'should have a write() function', ->
      expect(typeof uglydb.write).toEqual('function')
