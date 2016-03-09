module.exports = {
  entry: './src/scapula-utils',

  output: {
    path: './lib',
    filename: 'scapula-utils.js',
    libraryTarget: 'umd'
  },

  module: {
    loaders: [
      {
        test: /\.coffee$/,
        loader: "coffee"
      }
    ]
  },

  resolve: {
    extensions: [ '', '.coffee', '.js' ],
    modulesDirectories: [ 'node_modules' ]
  },

  externals: {
    'underscore': {
      root: '_',
      amd: 'underscore',
      commonjs: 'underscore',
      commonjs2: 'underscore'
    }
  }
};
