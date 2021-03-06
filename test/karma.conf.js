module.exports = function(config) {
  config.set({
    autoWatch: false,
    basePath: '..',
    browsers: [ 'PhantomJS' ],
    frameworks: [ 'jasmine', 'requirejs' ],
    reporters: [ 'dots', 'growl' ],

    files: [
      { pattern: 'src/**/*.js', included: false },
      { pattern: 'test/**/*Spec.js', included: false },
      'test/test-main.js',
    ],

    exclude: [
    ]
  });
};
