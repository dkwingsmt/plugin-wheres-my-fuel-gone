module.exports = {
  'env': {
    'browser': true,
    'es6': true,
    'node': true,
    'mocha': true,
  },
  'extends': [
    'eslint:recommended',
    'plugin:react/recommended',
    'plugin:import/errors',
    'plugin:import/warnings',
  ],
  'parserOptions': {
    'ecmaVersion': 7,
    'ecmaFeatures': {
      'experimentalObjectRestSpread': true,
      'jsx': true,
    },
    'sourceType': 'module',
  },
  'plugins': [
    'import',
    'react',
  ],
  'parser': 'babel-eslint',
  'rules': {
    'comma-dangle': ['error', 'always-multiline'],
    'indent': ['warn', 2],
    'linebreak-style': ['error', 'unix'],
    'no-console': ['warn', {'allow': ['warn', 'error']}],
    'no-var': 'error',
    'no-unused-vars': ['warn', {'args': 'none'}],
    'semi': ['error', 'never'],
    'unicode-bom': 'error',
    'prefer-const': ['error', {'destructuring': 'all'}],
    'prefer-template': "error",
    "template-curly-spacing": ["error", "never"],
    'object-curly-spacing': ["error", "always", { "arraysInObjects": false }],
    'arrow-body-style': ["error", "as-needed"],
    'global-require': "error",
    'prefer-const': "error",
    'no-irregular-whitespace': ['error', {'skipStrings': true, 'skipTemplates': true}],
    'react/prop-types': [0],
    'react/jsx-boolean-value': ['error', "never"],
    'react/jsx-first-prop-new-line': ['error', 'multiline'],
    'react/jsx-max-props-per-line': [1, { "when": "multiline" }],
  },
  'settings': {
    'import/resolver': {
      'node': {
        'extensions': ['', '.js', '.jsx', '.es', '.coffee', '.cjsx'],
        'paths': [__dirname, '/Users/DKWings/src/poi/poi', '/Users/DKWings/src/poi/poi/node_modules']
      },
    },
    'import/core-modules': ['electron', 'redux-observers'],
  },
}
