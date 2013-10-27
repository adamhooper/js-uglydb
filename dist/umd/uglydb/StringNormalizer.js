// Generated by uRequire v0.6.4 - template: 'UMDplain'
(function () {
  var __isAMD = (typeof define === 'function' && define.amd),
    __isNode = (typeof exports === 'object'),
    __isWeb = !__isNode;


(function (factory) {
  

if (typeof exports === 'object') {
   
   module.exports = factory(require);
 } else if (typeof define === 'function' && define.amd) {
     define(factory);
 }
}).call(this, function (require) {
  
// uRequire v0.6.4: START body of original AMD module
var StringNormalizationDb, StringNormalizer;
    StringNormalizationDb = function () {
      function StringNormalizationDb(indexes, normalizationString) {
        this.indexes = indexes;
        this.normalizationString = normalizationString;
      }
      StringNormalizationDb.prototype.get = function (s) {
        var _ref;
        if (s != null) {
          return (_ref = this.indexes[s]) != null ? _ref : s;
        } else {
          return -1;
        }
      };
      return StringNormalizationDb;
    }();
    return StringNormalizer = function () {
      function StringNormalizer() {
        this._counts = {};
      }
      StringNormalizer.prototype.add = function (string) {
        var _base;
        if ((_base = this._counts)[string] == null) {
          _base[string] = 0;
        }
        return this._counts[string] += 1;
      };
      StringNormalizer.prototype.asDb = function () {
        var c, count, i, indexes, normalizationString, separator, string, strings, usedChars, word, words, _i, _j, _len, _ref;
        words = function () {
          var _ref, _results;
          _ref = this._counts;
          _results = [];
          for (string in _ref) {
            count = _ref[string];
            _results.push({
              string: string,
              count: count
            });
          }
          return _results;
        }.call(this).filter(function (w) {
          return w.count > 1;
        }).sort(function (a, b) {
          return b.count - a.count || a.string.localeCompare(b.string);
        });
        indexes = this.indexes = {};
        strings = [""];
        usedChars = {};
        for (i = _i = 0, _len = words.length; _i < _len; i = ++_i) {
          word = words[i];
          string = word.string;
          indexes[string] = i;
          strings.push(string);
          for (i = _j = 0, _ref = string.length; 0 <= _ref ? _j <= _ref : _j >= _ref; i = 0 <= _ref ? ++_j : --_j) {
            c = string.charAt(i);
            usedChars[c] = null;
          }
        }
        normalizationString = function () {
          var _k, _l, _len1, _ref1;
          if (words.length > 0) {
            separator = null;
            _ref1 = [
              "|",
              ","
            ];
            for (_k = 0, _len1 = _ref1.length; _k < _len1; _k++) {
              c = _ref1[_k];
              if (!(c in usedChars)) {
                separator = c;
                break;
              }
            }
            if (separator == null) {
              for (i = _l = 32; _l < 65536; i = ++_l) {
                c = String.fromCharCode(i);
                if (!(c in usedChars) && JSON.stringify(c).indexOf("\\") === -1) {
                  separator = c;
                  break;
                }
              }
            }
            return strings.join(separator);
          } else {
            return null;
          }
        }();
        return new StringNormalizationDb(indexes, normalizationString);
      };
      return StringNormalizer;
    }();
// uRequire v0.6.4: END body of original AMD module


})
}).call(this);