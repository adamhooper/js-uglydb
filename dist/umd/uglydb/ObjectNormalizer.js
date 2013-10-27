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
var ObjectNormalizer;
    return ObjectNormalizer = function () {
      function ObjectNormalizer() {
        this.objects = {};
        this.nObjects = 0;
        this.columnSet = {};
      }
      ObjectNormalizer.prototype.add = function (column, object) {
        var counts, s;
        if (!(column in this.columnSet)) {
          this.columnSet[column] = null;
        }
        s = JSON.stringify(object);
        if (!(s in this.objects)) {
          this.objects[s] = {
            counts: {},
            length: s.length,
            object: object
          };
          this.nObjects += 1;
        }
        counts = this.objects[s].counts;
        if (!(column in counts)) {
          counts[column] = 0;
        }
        counts[column] += 1;
        return void 0;
      };
      ObjectNormalizer.prototype._costOfColumnAsIs = function (key) {
        var cost, object, __, _ref, _ref1;
        cost = 0;
        _ref = this.objects;
        for (__ in _ref) {
          object = _ref[__];
          cost += object.length * ((_ref1 = object.counts[key]) != null ? _ref1 : 0);
        }
        return cost;
      };
      ObjectNormalizer.prototype._worstCaseCostOfColumnNormalized = function (key) {
        var cost, count, indexCost, object, __, _ref;
        indexCost = Math.floor(Math.log(this.nObjects));
        cost = 0;
        _ref = this.objects;
        for (__ in _ref) {
          object = _ref[__];
          count = object.counts[key];
          if (count) {
            cost += object.length + indexCost * count;
          }
        }
        return cost;
      };
      ObjectNormalizer.prototype._findColumnsWorthNormalizing = function () {
        var a, b, column, ret, __, _ref;
        ret = [];
        _ref = this.columnSet;
        for (column in _ref) {
          __ = _ref[column];
          a = this._costOfColumnAsIs(column);
          b = this._worstCaseCostOfColumnNormalized(column);
          if (b < a) {
            ret.push(column);
          }
        }
        return ret;
      };
      ObjectNormalizer.prototype.asDb = function () {
        var counts, entry, index, json, jsonToIndex, key, keys, normalizationArray, normalizedCount, objectsToNormalize, _i, _j, _len, _len1, _ref, _ref1;
        keys = this._findColumnsWorthNormalizing();
        if (keys.length) {
          objectsToNormalize = [];
          _ref = this.objects;
          for (json in _ref) {
            entry = _ref[json];
            counts = entry.counts;
            normalizedCount = 0;
            for (_i = 0, _len = keys.length; _i < _len; _i++) {
              key = keys[_i];
              normalizedCount += (_ref1 = counts[key]) != null ? _ref1 : 0;
            }
            if (normalizedCount > 0) {
              objectsToNormalize.push({
                json: json,
                object: entry.object,
                count: normalizedCount
              });
            }
          }
          objectsToNormalize.sort(function (a, b) {
            return b.count - a.count;
          });
          normalizationArray = objectsToNormalize.map(function (x) {
            return x.object;
          });
          jsonToIndex = {};
          for (index = _j = 0, _len1 = objectsToNormalize.length; _j < _len1; index = ++_j) {
            entry = objectsToNormalize[index];
            jsonToIndex[entry.json] = index;
          }
        } else {
          normalizationArray = jsonToIndex = null;
        }
        return {
          keys: keys,
          normalizationArray: normalizationArray,
          get: function (o) {
            var s;
            s = JSON.stringify(o);
            return jsonToIndex[s];
          }
        };
      };
      return ObjectNormalizer;
    }();
// uRequire v0.6.4: END body of original AMD module


})
}).call(this);