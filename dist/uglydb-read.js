
(function() {
  define('uglydb/read',[],function() {
    var SPEC_URL, isString, toString, uglydbToObject;
    SPEC_URL = "http://git.io/uglydb-0.1";
    toString = Object.prototype.toString;
    isString = function(s) {
      return toString.call(s) === '[object String]';
    };
    uglydbToObject = function(uglydb) {
      var header, i, invalidArrayFormat, key, keys, needObjects, needStrings, ret, string, type, uglyIndex, _i, _ref;
      if (!Array.isArray(uglydb)) {
        throw new Error("Invalid uglydb JSON: it must be an Array. See " + SPEC_URL);
      }
      ret = {
        specUrl: null,
        keys: null,
        records: null,
        stringArray: null,
        objectArray: null
      };
      uglyIndex = 0;
      if (isString(uglydb[uglyIndex])) {
        ret.specUrl = uglydb[uglyIndex];
        uglyIndex += 1;
        if (ret.specUrl !== SPEC_URL) {
          throw new Error("Expected uglydb JSON to have spec " + SPEC_URL + ", but its spec is " + ret.specUrl);
        }
      }
      if (!Array.isArray(uglydb[uglyIndex])) {
        throw new Error("Expected uglydb header to be an Array. See " + SPEC_URL);
      }
      invalidArrayFormat = function() {
        return new Error("Expected uglydb header to have format [ \"key1\", 3, \"key2\", 1, ... ]. See " + SPEC_URL);
      };
      header = uglydb[uglyIndex];
      uglyIndex += 1;
      if (header.length % 2 !== 0) {
        throw invalidArrayFormat();
      }
      keys = ret.keys = [];
      needStrings = false;
      needObjects = false;
      for (i = _i = 0, _ref = header.length; _i < _ref; i = _i += 2) {
        key = header[i];
        type = header[i + 1];
        if (type === 2) {
          needObjects = true;
        }
        if (type === 3) {
          needStrings = true;
        }
        if (!isString(key)) {
          throw invalidArrayFormat();
        }
        if (type !== 1 && type !== 2 && type !== 3) {
          throw new Error("Type " + (JSON.stringify(type)) + " in the header is not a key type. Valid key types are 1, 2 and 3. See " + SPEC_URL);
        }
        keys.push({
          key: key,
          type: type
        });
      }
      if (!Array.isArray(uglydb[uglyIndex])) {
        throw new Error("Expected uglydb records array to be an Array. See " + SPEC_URL);
      }
      ret.records = uglydb[uglyIndex];
      uglyIndex += 1;
      if ((keys.length > 0 && ret.records.length % keys.length !== 0) || (keys.length === 0 && ret.records.length > 0)) {
        throw new Error("The records array has " + ret.records.length + " values, but it needs a multiple of " + keys.length + ". See " + SPEC_URL);
      }
      if (needStrings) {
        string = uglydb[uglyIndex];
        uglyIndex += 1;
        if (!isString(string)) {
          throw new Error("There is a column of type 3 but there is no String array. See " + SPEC_URL);
        }
        ret.stringArray = string.split(string.charAt(0)).slice(1);
      }
      if (needObjects) {
        if (!Array.isArray(uglydb[uglyIndex])) {
          throw new Error("There is a column of type 2 but there is no Object array. See " + SPEC_URL);
        }
        ret.objectArray = uglydb[uglyIndex];
      }
      return ret;
    };
    return function(uglydb) {
      var key, keyIndex, keyNames, keyTypes, normalizedObjects, normalizedStrings, obj, rawValue, ret, type, uglyObject, value, _i, _len, _ref;
      uglyObject = uglydbToObject(uglydb);
      keyNames = (function() {
        var _i, _len, _ref, _results;
        _ref = uglyObject.keys;
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          key = _ref[_i];
          _results.push(key.key);
        }
        return _results;
      })();
      keyTypes = (function() {
        var _i, _len, _ref, _results;
        _ref = uglyObject.keys;
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          key = _ref[_i];
          _results.push(key.type);
        }
        return _results;
      })();
      normalizedStrings = uglyObject.stringArray;
      normalizedObjects = uglyObject.objectArray;
      ret = [];
      obj = {};
      keyIndex = 0;
      _ref = uglyObject.records;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        rawValue = _ref[_i];
        type = keyTypes[keyIndex];
        value = (function() {
          switch (keyTypes[keyIndex]) {
            case 1:
              return rawValue;
            case 2:
              if (rawValue < 0 || rawValue >= normalizedObjects.length) {
                throw new Error("A normalized object is requested at index " + rawValue + " but the maximum index is " + (normalizedObjects.length - 1) + ". See " + SPEC_URL);
              }
              return normalizedObjects[rawValue];
            case 3:
              if (isString(rawValue)) {
                return rawValue;
              } else {
                if (rawValue < 0) {
                  return null;
                } else if (rawValue >= normalizedStrings.length) {
                  throw new Error("A normalized string is requested at index " + rawValue + " but the maximum index is " + (normalizedStrings.length - 1) + ". See " + SPEC_URL);
                } else {
                  return normalizedStrings[rawValue];
                }
              }
          }
        })();
        obj[keyNames[keyIndex]] = value;
        keyIndex += 1;
        if (keyIndex === keyNames.length) {
          ret.push(obj);
          obj = {};
          keyIndex = 0;
        }
      }
      return ret;
    };
  });

}).call(this);

/*
//@ sourceMappingURL=read.js.map
*/;