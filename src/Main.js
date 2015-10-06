"use strict";

// module Main

var childProcess = require('child_process');

exports.psc = function(files) {
  return function(k) {
    return function() {
      var child = childProcess.spawn("psc", files);

      child.stderr.pipe(process.stdout);

      child.on('close', function() {
        k();
      });
    };
  };
};

exports.execModule = function(moduleName) {
  return function(k) {
    return function() {
      var fs = require('fs');
      var src = "process.on('message', function() {" +
                "  require('" + moduleName + "').main();" +
                "  process.send('');" +
                "});";

      fs.writeFile("output/index.js", src, function(err) {
          if (err) {
              return console.log(err);
          }
      });

      var child = childProcess.fork("output/index.js", [], {
        env: {
          "NODE_PATH": "output"
        }
      });

      child.on('message', function(m) {
        k();
      });

      child.send("");
    };
  };
};
