_ = require 'underscore'
utils = require '../lib/scapula-utils'
assert = require 'assert'

# String ----------------------------------------------------------------------

describe 'capitalize', ->
  it 'basic func', ->
    assert.equal  utils.capitalize('tiger'), 'Tiger'

  it 'undefined handling', ->
    assert.equal utils.capitalize(), undefined

describe 'splitName', ->
  expected = [ 'Donnie', 'Yen' ]

  it 'splits normal name', ->
    assert.deepEqual utils.splitName('Donnie Yen'), expected

  it 'splits sort name', ->
    assert.deepEqual utils.splitName('Yen, Donnie'), expected

describe 'joinName', ->
  it 'joins normal name parts', ->
    assert.equal utils.joinName('Li Mu', 'Bai'), 'Li Mu Bai'

  it 'joins sort name parts', ->
    assert.equal utils.joinName('Scott', 'Adkins', sort: true),
      'Adkins, Scott'

describe 'wrap', ->
  it 'wraps string', ->
    assert.equal utils.wrap('samba', [ '>', '<' ]), '>samba<'

describe 'extractKeywords', ->
  it 'extracts keywords', ->
    assert.deepEqual utils.extractKeywords(' pear  " sour cherry"'),
      [ 'pear', 'sour cherry' ]

  it 'extracts keywords with marks', ->
    expected =
      '': [ 'french fries', 'computer' ]
      car: [ 'honda', 'mazda' ]
      fruit: [ 'pear', 'sour cherry' ]

    assert.deepEqual expected, utils.extractKeywords \
      '{pear} "french fries" [honda] {sour cherry} [mazda] computer',
      '{}': 'fruit', '[]': 'car', '"': ''

# Checkers --------------------------------------------------------------------

describe 'chkEmail', ->
  it 'passes valid emails', ->
    for str in [ 'jetli123@hero.org',
                 'HiroyukiSanada@Ninja86.jp',
                 'van-damme.dolph_lundgren@some.uni-soldier.com' ]
      assert utils.chkEmail str

  it 'blocks invalid emails', ->
    for str in [ 'hello', 'hello@', 'hello@baby', '@baby' ]
      assert !utils.chkEmail str

describe 'chkIP', ->
  it 'passes valid IPs', ->
    for str in [ '192.168.10.124', '10.2.4.1', '250.0.255.100' ]
      assert utils.chkIP str

  it 'blocks invalid IPs', ->
    for str in [ '192', '192.168.10', 'asdf', '123.256.1.1' ]
      assert !utils.chkIP str

describe 'chkHost', ->
  it 'passes valid host names', ->
    for str in [ 'test'
                 'google.com'
                 'rambo-online.2rockets.org'
                 [11 .. 31].join('-')
                 [7 .. 71].join('.a') ]
      assert utils.chkHost str

  it 'blocks invalid host names', ->
    for str in [ 'jetli123@hero.org'
                 '@ninja.edu'
                 '!hello'
                 'hello-'
                 [11 .. 32].join('-')
                 [8 .. 72].join('.a') ]
      assert !utils.chkHost str

# Object / "class" ------------------------------------------------------------

describe 'extendMethod', ->
  it 'extends method', ->
    obj1 = addProp: (par = {}) ->
      par.y = 2
      par

    obj2 = addProp: (par = {}) ->
      par.z = 3
      par

    utils.extendMethod obj2, obj1, 'addProp'

    assert.deepEqual obj2.addProp(x: 1), x: 1, y: 2, z: 3

describe 'mixin', ->
  it 'mixins class', ->
    fruitMixin =
      slice: -> @size /= 2
      peel: -> @size--

    class Fruit
      constructor: (@size = 10) ->
      slice: -> @size /= 4

    SliceFruit = utils.mixin fruitMixin, Fruit

    pear = new SliceFruit 40
    pear.slice()
    pear.peel()
    assert.equal pear.size, 4

describe 'obj2Array', ->
  it 'converts deep obj to array', ->
    obj =
      pear:
        size: 10
        color: 'yellow'
      apple:
        size: 8
        color: 'red'

    expected = [
      _.extend type: 'pear', obj.pear
      _.extend type: 'apple', obj.apple
    ]

    assert.deepEqual utils.obj2Array(obj), expected

  it 'converts simple obj to array with keyname', ->
    obj =
      pear: 20
      apple: 18

    expected = [
      name: 'pear', value: 20
    ,
      name: 'apple', value: 18
    ]

    assert.deepEqual utils.obj2Array(obj, keyname: 'name'), expected

describe 'getProp', ->
  it 'gets prop by default', ->
    assert.equal utils.getProp({ pear: 10 }, 'pear'), 10

  it 'gets prop as attr when get is present', ->
    obj =
      pear: 42
      get: -> @pear.toString()

    assert.strictEqual utils.getProp(obj, 'pear', attr: true), '42'

describe 'adoptProps', ->
  it 'adopts props', ->
    obj1 =
      pear: 10

    obj2 =
      banana: 12
      ananas: 13
      mango: 14

    assert.deepEqual utils.adoptProps(obj1, obj2, 'banana', 'mango'),
      pear: 10, banana: 12, mango: 14
