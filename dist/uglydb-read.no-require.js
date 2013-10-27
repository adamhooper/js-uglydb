(function () {
/**
 * almond 0.2.6 Copyright (c) 2011-2012, The Dojo Foundation All Rights Reserved.
 * Available via the MIT or new BSD license.
 * see: http://github.com/jrburke/almond for details
 */
//Going sloppy to avoid 'use strict' string cost, but strict practices should
//be followed.
/*jslint sloppy: true */
/*global setTimeout: false */

var requirejs, require, define;
(function (undef) {
    var main, req, makeMap, handlers,
        defined = {},
        waiting = {},
        config = {},
        defining = {},
        hasOwn = Object.prototype.hasOwnProperty,
        aps = [].slice;

    function hasProp(obj, prop) {
        return hasOwn.call(obj, prop);
    }

    /**
     * Given a relative module name, like ./something, normalize it to
     * a real name that can be mapped to a path.
     * @param {String} name the relative name
     * @param {String} baseName a real name that the name arg is relative
     * to.
     * @returns {String} normalized name
     */
    function normalize(name, baseName) {
        var nameParts, nameSegment, mapValue, foundMap,
            foundI, foundStarMap, starI, i, j, part,
            baseParts = baseName && baseName.split("/"),
            map = config.map,
            starMap = (map && map['*']) || {};

        //Adjust any relative paths.
        if (name && name.charAt(0) === ".") {
            //If have a base name, try to normalize against it,
            //otherwise, assume it is a top-level require that will
            //be relative to baseUrl in the end.
            if (baseName) {
                //Convert baseName to array, and lop off the last part,
                //so that . matches that "directory" and not name of the baseName's
                //module. For instance, baseName of "one/two/three", maps to
                //"one/two/three.js", but we want the directory, "one/two" for
                //this normalization.
                baseParts = baseParts.slice(0, baseParts.length - 1);

                name = baseParts.concat(name.split("/"));

                //start trimDots
                for (i = 0; i < name.length; i += 1) {
                    part = name[i];
                    if (part === ".") {
                        name.splice(i, 1);
                        i -= 1;
                    } else if (part === "..") {
                        if (i === 1 && (name[2] === '..' || name[0] === '..')) {
                            //End of the line. Keep at least one non-dot
                            //path segment at the front so it can be mapped
                            //correctly to disk. Otherwise, there is likely
                            //no path mapping for a path starting with '..'.
                            //This can still fail, but catches the most reasonable
                            //uses of ..
                            break;
                        } else if (i > 0) {
                            name.splice(i - 1, 2);
                            i -= 2;
                        }
                    }
                }
                //end trimDots

                name = name.join("/");
            } else if (name.indexOf('./') === 0) {
                // No baseName, so this is ID is resolved relative
                // to baseUrl, pull off the leading dot.
                name = name.substring(2);
            }
        }

        //Apply map config if available.
        if ((baseParts || starMap) && map) {
            nameParts = name.split('/');

            for (i = nameParts.length; i > 0; i -= 1) {
                nameSegment = nameParts.slice(0, i).join("/");

                if (baseParts) {
                    //Find the longest baseName segment match in the config.
                    //So, do joins on the biggest to smallest lengths of baseParts.
                    for (j = baseParts.length; j > 0; j -= 1) {
                        mapValue = map[baseParts.slice(0, j).join('/')];

                        //baseName segment has  config, find if it has one for
                        //this name.
                        if (mapValue) {
                            mapValue = mapValue[nameSegment];
                            if (mapValue) {
                                //Match, update name to the new value.
                                foundMap = mapValue;
                                foundI = i;
                                break;
                            }
                        }
                    }
                }

                if (foundMap) {
                    break;
                }

                //Check for a star map match, but just hold on to it,
                //if there is a shorter segment match later in a matching
                //config, then favor over this star map.
                if (!foundStarMap && starMap && starMap[nameSegment]) {
                    foundStarMap = starMap[nameSegment];
                    starI = i;
                }
            }

            if (!foundMap && foundStarMap) {
                foundMap = foundStarMap;
                foundI = starI;
            }

            if (foundMap) {
                nameParts.splice(0, foundI, foundMap);
                name = nameParts.join('/');
            }
        }

        return name;
    }

    function makeRequire(relName, forceSync) {
        return function () {
            //A version of a require function that passes a moduleName
            //value for items that may need to
            //look up paths relative to the moduleName
            return req.apply(undef, aps.call(arguments, 0).concat([relName, forceSync]));
        };
    }

    function makeNormalize(relName) {
        return function (name) {
            return normalize(name, relName);
        };
    }

    function makeLoad(depName) {
        return function (value) {
            defined[depName] = value;
        };
    }

    function callDep(name) {
        if (hasProp(waiting, name)) {
            var args = waiting[name];
            delete waiting[name];
            defining[name] = true;
            main.apply(undef, args);
        }

        if (!hasProp(defined, name) && !hasProp(defining, name)) {
            throw new Error('No ' + name);
        }
        return defined[name];
    }

    //Turns a plugin!resource to [plugin, resource]
    //with the plugin being undefined if the name
    //did not have a plugin prefix.
    function splitPrefix(name) {
        var prefix,
            index = name ? name.indexOf('!') : -1;
        if (index > -1) {
            prefix = name.substring(0, index);
            name = name.substring(index + 1, name.length);
        }
        return [prefix, name];
    }

    /**
     * Makes a name map, normalizing the name, and using a plugin
     * for normalization if necessary. Grabs a ref to plugin
     * too, as an optimization.
     */
    makeMap = function (name, relName) {
        var plugin,
            parts = splitPrefix(name),
            prefix = parts[0];

        name = parts[1];

        if (prefix) {
            prefix = normalize(prefix, relName);
            plugin = callDep(prefix);
        }

        //Normalize according
        if (prefix) {
            if (plugin && plugin.normalize) {
                name = plugin.normalize(name, makeNormalize(relName));
            } else {
                name = normalize(name, relName);
            }
        } else {
            name = normalize(name, relName);
            parts = splitPrefix(name);
            prefix = parts[0];
            name = parts[1];
            if (prefix) {
                plugin = callDep(prefix);
            }
        }

        //Using ridiculous property names for space reasons
        return {
            f: prefix ? prefix + '!' + name : name, //fullName
            n: name,
            pr: prefix,
            p: plugin
        };
    };

    function makeConfig(name) {
        return function () {
            return (config && config.config && config.config[name]) || {};
        };
    }

    handlers = {
        require: function (name) {
            return makeRequire(name);
        },
        exports: function (name) {
            var e = defined[name];
            if (typeof e !== 'undefined') {
                return e;
            } else {
                return (defined[name] = {});
            }
        },
        module: function (name) {
            return {
                id: name,
                uri: '',
                exports: defined[name],
                config: makeConfig(name)
            };
        }
    };

    main = function (name, deps, callback, relName) {
        var cjsModule, depName, ret, map, i,
            args = [],
            usingExports;

        //Use name if no relName
        relName = relName || name;

        //Call the callback to define the module, if necessary.
        if (typeof callback === 'function') {

            //Pull out the defined dependencies and pass the ordered
            //values to the callback.
            //Default to [require, exports, module] if no deps
            deps = !deps.length && callback.length ? ['require', 'exports', 'module'] : deps;
            for (i = 0; i < deps.length; i += 1) {
                map = makeMap(deps[i], relName);
                depName = map.f;

                //Fast path CommonJS standard dependencies.
                if (depName === "require") {
                    args[i] = handlers.require(name);
                } else if (depName === "exports") {
                    //CommonJS module spec 1.1
                    args[i] = handlers.exports(name);
                    usingExports = true;
                } else if (depName === "module") {
                    //CommonJS module spec 1.1
                    cjsModule = args[i] = handlers.module(name);
                } else if (hasProp(defined, depName) ||
                           hasProp(waiting, depName) ||
                           hasProp(defining, depName)) {
                    args[i] = callDep(depName);
                } else if (map.p) {
                    map.p.load(map.n, makeRequire(relName, true), makeLoad(depName), {});
                    args[i] = defined[depName];
                } else {
                    throw new Error(name + ' missing ' + depName);
                }
            }

            ret = callback.apply(defined[name], args);

            if (name) {
                //If setting exports via "module" is in play,
                //favor that over return value and exports. After that,
                //favor a non-undefined return value over exports use.
                if (cjsModule && cjsModule.exports !== undef &&
                        cjsModule.exports !== defined[name]) {
                    defined[name] = cjsModule.exports;
                } else if (ret !== undef || !usingExports) {
                    //Use the return value from the function.
                    defined[name] = ret;
                }
            }
        } else if (name) {
            //May just be an object definition for the module. Only
            //worry about defining if have a module name.
            defined[name] = callback;
        }
    };

    requirejs = require = req = function (deps, callback, relName, forceSync, alt) {
        if (typeof deps === "string") {
            if (handlers[deps]) {
                //callback in this case is really relName
                return handlers[deps](callback);
            }
            //Just return the module wanted. In this scenario, the
            //deps arg is the module name, and second arg (if passed)
            //is just the relName.
            //Normalize module name, if it contains . or ..
            return callDep(makeMap(deps, callback).f);
        } else if (!deps.splice) {
            //deps is a config object, not an array.
            config = deps;
            if (callback.splice) {
                //callback is an array, which means it is a dependency list.
                //Adjust args if there are dependencies
                deps = callback;
                callback = relName;
                relName = null;
            } else {
                deps = undef;
            }
        }

        //Support require(['a'])
        callback = callback || function () {};

        //If relName is a function, it is an errback handler,
        //so remove it.
        if (typeof relName === 'function') {
            relName = forceSync;
            forceSync = alt;
        }

        //Simulate async callback;
        if (forceSync) {
            main(undef, deps, callback, relName);
        } else {
            //Using a non-zero value because of concern for what old browsers
            //do, and latest browsers "upgrade" to 4 if lower value is used:
            //http://www.whatwg.org/specs/web-apps/current-work/multipage/timers.html#dom-windowtimers-settimeout:
            //If want a value immediately, use require('id') instead -- something
            //that works in almond on the global level, but not guaranteed and
            //unlikely to work in other AMD implementations.
            setTimeout(function () {
                main(undef, deps, callback, relName);
            }, 4);
        }

        return req;
    };

    /**
     * Just drops the config on the floor, but returns req in case
     * the config return value is used.
     */
    req.config = function (cfg) {
        config = cfg;
        if (config.deps) {
            req(config.deps, config.callback);
        }
        return req;
    };

    /**
     * Expose module registry for debugging and tooling
     */
    requirejs._defined = defined;

    define = function (name, deps, callback) {

        //This module may not have dependencies
        if (!deps.splice) {
            //deps is not an array, so probably means
            //an object literal or factory function for
            //the value. Adjust args.
            callback = deps;
            deps = [];
        }

        if (!hasProp(defined, name) && !hasProp(waiting, name)) {
            waiting[name] = [name, deps, callback];
        }
    };

    define.amd = {
        jQuery: true
    };
}());

define("almond", function(){});

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
(function() {
  var read;

  read = requirejs('./uglydb/read');

  window.uglyDb = {
    read: read
  };

}).call(this);

/*
//@ sourceMappingURL=uglydb-read.js.map
*/;
define("uglydb-read", function(){});
}());