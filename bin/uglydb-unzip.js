#!/usr/bin/env node

var path = require('path');
var uglydb = require(path.join('..', 'index'));

process.stdin.resume()

var inputUglyJsonString = '';
process.stdin.on('error', function(error) {
  process.stderr.write("Error reading from stdin: " + error);
});
process.stdin.on('data', function(chunk) {
  inputUglyJsonString += chunk;
});
process.stdin.on('end', function() {
  var uglyJson = JSON.parse(inputUglyJsonString);
  var json = uglydb.read(uglyJson);
  var jsonString = JSON.stringify(json);

  process.stdout.write(jsonString);
  process.exit(0);
});
