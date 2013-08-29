fs = require 'fs'
{print} = require 'util'
{spawn, exec} = require "child_process"

task "compile", "Compile library", ->
  exec " coffee -o lib -c src/*.coffee", (err, stdout, stderr) ->
    throw err if err
    console.log stdout + stderr

task "test", "Run unit tests", ->
  exec "mocha -R spec --colors --compilers coffee:coffee-script test/*", (err, stdout, stderr)->
    #throw err if err
    console.log stdout + stderr

