fs = require 'fs'
{print} = require 'util'
{spawn, exec} = require "child_process"

task "compile", "Compile library", ->
  exec " coffee -o lib -c src/*.coffee", (err, stdout, stderr) ->
    throw err if err
    console.log stdout + stderr

task "test", "Run unit tests", ->
  exec "mocha --colors --compilers coffee:coffee-script test/*", (err, stdout, stderr)->
    #throw err if err
    console.log stdout + stderr

task "docs", "Generate API docs", ->
  exec "docco src/*", (err, stdout, stderr)->
    throw err if err
    console.log stdout + stderr


