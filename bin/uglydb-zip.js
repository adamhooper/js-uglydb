#!/usr/bin/env node

var path = require('path');
var uglydb = require(path.join('..', 'index'));

process.stdin.resume()

var inputJsonString = '';
process.stdin.on('error', function(error) {
  process.stderr.write("Error reading from stdin: " + error);
});
process.stdin.on('data', function(chunk) {
  inputJsonString += chunk;
});
process.stdin.on('end', function() {
  var json = JSON.parse(inputJsonString);
  var uglyJson = uglydb.write(json);
  var uglyJsonString = JSON.stringify(uglyJson);

  process.stdout.write(uglyJsonString);
  process.exit(0);
});
