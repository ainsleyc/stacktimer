module.exports = function (grunt) {

  grunt.initConfig({
    pkg: '<json:package.json>',
    cafemocha: {
      src: [ 'test/**/*.coffee' ],
      options: {
        timeout: 3000,
        ignoreLeaks: false,
        ui: 'bdd',
        reporter: 'spec',
        compilers: 'coffee:coffee-script',
        globals: [
        ]
      }
    },
    watch: {
      files: [ 'Gruntfile.js', 'lib/**/*.coffee', 'test/**/*.coffee' ],
      tasks: [ 'coffee', 'cafemocha' ]
    },
    coffee: {
      compile: {
        files: {
          'dist/stacktimer.js': 'lib/stacktimer.coffee',
          'dist/trace.js': 'lib/trace.coffee',
          'dist/wrappers.js': 'lib/wrappers.coffee',
          'dist/consts.js': 'lib/consts.coffee',
        }
      }
    }
  });

  grunt.loadNpmTasks('grunt-cafe-mocha');
  grunt.loadNpmTasks('grunt-contrib-watch');
  grunt.loadNpmTasks('grunt-contrib-coffee');

  grunt.registerTask('default', [ 'coffee', 'cafemocha', 'watch' ]);

};
