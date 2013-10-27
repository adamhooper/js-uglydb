module.exports = (grunt) ->
  grunt.initConfig
    coffee:
      src:
        options:
          sourceMap: true
        expand: true
        flatten: false
        cwd: 'src/coffee'
        src: [ '**/*.coffee' ]
        dest: 'src/js/'
        ext: '.js'

      test:
        expand: true
        flatten: false
        cwd: 'test/coffee'
        src: [ '**/*.coffee' ]
        dest: 'test/js/'
        ext: '.js'

    urequire:
      # Template to support require()-ing index.js, in NodeJS
      UMD:
        template: 'UMDplain'
        path: 'src/js/'
        main: 'uglydb'
        dstPath: './dist/umd'

    copy:
      'uglydb-read.js':
        src: 'src/js/uglydb/read.js'
        dest: './dist/uglydb-read.js'

    requirejs:
      'uglydb-read.js':
        options:
          name: 'uglydb/read'
          baseUrl: 'src/js/'
          optimize: 'none'
          out: './dist/uglydb-read.js'

      'uglydb-read.no-require.js':
        options:
          almond: true
          wrap: true
          deps: [ 'uglydb/read' ]
          include: [ 'uglydb-read' ]
          baseUrl: 'src/js/'
          optimize: 'none'
          out: './dist/uglydb-read.no-require.js'

      'uglydb-read.no-require.min.js':
        options:
          almond: true
          wrap: true
          deps: [ 'uglydb/read' ]
          include: [ 'uglydb-read' ]
          baseUrl: 'src/js/'
          optimize: 'uglify2'
          out: './dist/uglydb-read.no-require.min.js'

    karma:
      options:
        configFile: 'test/karma.conf.js'
      unit:
        background: true
      continuous:
        singleRun: true

    watch:
      options:
        spawn: false
      coffee:
        files: [ 'src/coffee/**/*.coffee' ]
        tasks: [ 'coffee:src', 'karma:unit:run' ]
      'coffee-test':
        files: [ 'test/coffee/**/*.coffee' ]
        tasks: [ 'coffee:test', 'karma:unit:run' ]

  grunt.loadNpmTasks('grunt-contrib-coffee')
  grunt.loadNpmTasks('grunt-contrib-copy')
  grunt.loadNpmTasks('grunt-contrib-watch')
  grunt.loadNpmTasks('grunt-urequire')
  grunt.loadNpmTasks('grunt-karma')
  grunt.loadNpmTasks('grunt-requirejs')

  # Only rewrite changed files when watching
  grunt.event.on 'watch', (action, filepath) ->
    # if editing src/coffee/some/file.coffee, set coffee.src.src=./some/file.coffee
    if (m = /^(src|test)\/coffee\//.exec(filepath))?
      key = m[1] # "src" or "test".
      cwd = grunt.config("coffee.#{key}.cwd")
      grunt.config("coffee.#{key}.src", filepath.replace(cwd, '.'))

  # karma:unit takes a moment to spin up
  grunt.registerTask 'wait-for-karma', 'Wait until Karma has started', ->
    setTimeout(@async(), 3000)

  grunt.registerTask('test', [ 'coffee', 'karma:continuous' ])
  grunt.registerTask('develop', [ 'coffee', 'karma:unit', 'wait-for-karma', 'karma:unit:run', 'watch' ])
  grunt.registerTask('default', [ 'coffee', 'karma:continuous', 'copy', 'urequire', 'requirejs' ])
