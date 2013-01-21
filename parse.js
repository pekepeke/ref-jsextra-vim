#!/usr/bin/env node

var util = require('util')
  , path = require('path')
  , fs = require('fs')
  , cheerio = require('cheerio')
  , glob = require('glob')
  , async = require('async')
  , child_process = require('child_process');

var $A = function(a) { return Array.prototype.slice.call(a, 0); };

function dump() {
  Array.prototype.slice.call(arguments, 0).forEach(function(v) {
    util.puts(v);
    util.puts(util.inspect(v));
  });
}

var Parsers = {
  yui : function(base_path, json, cb) {
    json = json || {};
    glob(path.join(base_path, '*.html'), function(err, files){
      files.forEach(function(f) {
        if (f.match(/\.js\.html$/)) return;
        var src = fs.readFileSync(f, 'utf8')
          , $ = cheerio.load(src);

        var get_texts = function(q) {
          return $A($(q)).map(function(v) {
            return $(v).text();
          });
        };
        var defines = [{
          attr : 'property'
        }, {
          attr : 'methods'
        }, {
          attr : 'events'
        }, {
          attr : 'attributes'
        }];
        var name = $('h2 b[property="yui:name"]').text();
        // var name = $('#hd').text().split("\n").filter(function(v) {
        //   return v.match(/^\s*>/);
        // }).map(function(v) {
        //   return v.replace(/^\s*>\s*|\s*$/g, "");
        // }).join(".");

        defines.forEach(function(item) {
          item.names = get_texts('div[rel="yui:' + item.attr + '"] a[property="yui:name"]');
        });
        if (!name) {
          util.error("name not found - " + f);
          return;
        }
        json[name] = {
          path : f
        };
        defines.forEach(function(item) {
          json[name][item.attr] = {};
          item.names.forEach(function(n) {
            json[name][item.attr][n] = f + "#" + item.attr + "_" + n;
          });
        });
      });
      if (cb) cb.call(json);
    });
  }
  , jsdoc : function(base_path, json, cb) {
    json = json || {};
    glob(path.join(base_path, 'symbols/*.html'), function(err, files){
      files.forEach(function (f) {
        var src = fs.readFileSync(f, 'utf8')
          , $ = cheerio.load(src);

        var get_texts = function(q) {
          return $A($(q)).map(function(v) {
            return $(v).text();
          });
        };
        var defines = [{
          attr : 'property'
        }, {
          attr : 'methods'
        }, {
          attr : 'events'
        }, {
          attr : 'attributes'
        }];
        var names = get_texts('table.summaryTable td.nameDescription a')
          , is_props = get_texts('table.summaryTable td.attributes');

        var name = names.shift(); is_props.shift();
        if (!name) {
          util.error("name not found - " + f);
          return;
        }
        json[name] = {
          path : f
        };
        defines.forEach(function(item) {
          json[name][item.attr] = {};
        });
        names.forEach(function(item, i) {
          var is_prop = is_props[i]
          , prop = is_prop ? "property" : "methods";
          json[name][prop][item] = f + "#" + (is_prop ? "." : "") + item;
        });
      });
      if (cb) cb.call(json);
    });
  }
};
!function() {
  // main

  var json = {}
    , def = JSON.parse(fs.readFileSync('repos_defines.json'));

  var tasks = [], commands = [];
  var parse_exec = function(type, name, def) {
    return function(next) {
      // util.puts(name, type);
      if (!Parsers[type]) return;
      json[name] = {};
      Parsers[type].call(Parsers, def[name].path, json[name], next);
    };
  };
  var command_exec = function(cmd) {
    return function(next) {
      child_process.exec(cmd, next);
    };
  };


  var name, type, relative, command, url;
  for (name in def) {
    type = def[name].type;
    relative = def[name].relative || "";
    command = def[name].command;
    url = def[name].url;
    if (!type || !command) {
      continue;
    }
    // util.puts(type, relative, command, url)
    tasks.push(parse_exec(type, name, def));

    if (command == "file") {
      // do nothing
    } else if (command == "git") {
      if (!fs.existsSync(name)) {
        if (url) {
          commands.push( command_exec("git clone " + url + " " + name));
          // util.puts('git clone ' + url + " " + name);
        }
      } else {
        commands.push( command_exec("cd " + name + " && git pull "));
      }
      def[name].path = path.join(name, def[name].relative);
    } else if(command == "zip") {
      if (!fs.existsSync(name)) {
        !function(name, type, relative, command, url) {
          commands.push(function(_next) {
            var zip = path.basename(url)
            , base = path.basename(url, ".zip");
            async.waterfall([
              function(next) {
                child_process.exec('curl -LO ' + url, next);
                // util.puts('curl -LO ' + url);
              }
              , function(err, s, next) {
                child_process.exec('unzip -n ' + zip, next);
                // util.puts('unzip ' + url);
              },
              function(err, s, next) {
                fs.rename(base, name, next);
                // util.puts('ren ' + base + ' ' + name);
              }
            ], _next);
          });
        }(name, type, relative, command, url);
      }
      def[name].path = path.join(name, def[name].relative);
    }
  }
  async.parallel(commands, function(err, results) {
    async.parallel(tasks, function(err, results) {
      fs.writeFileSync("dict.json", JSON.stringify(json));
    });
  });
  // async.parallel([
  //   function(callback) {
  //     Parsers.yui("./*", json, callback);
  //   }
  //   , function(callback) {
  //     Parsers.jsdoc("./Arctic.js/doc/api/", json, callback);
  //   }
  // ], function(err, results) {
  //   fs.writeFileSync("dict.json", JSON.stringify(json));
  // });
}();
