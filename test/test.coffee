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
# URL -------------------------------------------------------------------------

describe 'addUrlParams', ->
  beforeEach ->
    @url = 'https://locahost'

  it 'adds params with encoding', ->
    assert.equal \
      utils.addUrlParams(@url,
        { fruits: 'pear cherry', banana: 2 }, encode: true),
      @url + "?fruits=#{encodeURIComponent('pear cherry')}&banana=2"

  it 'adds params without encoding', ->
    assert.equal \
      utils.addUrlParams(@url, fruits: 'pear cherry', banana: 2),
      @url + '?fruits=pear cherry&banana=2'

  it 'adds params after an existing one', ->
    assert.equal \
      utils.addUrlParams(@url + '?car=1', fruits: 'pear cherry', banana: 2),
      @url + '?car=1&fruits=pear cherry&banana=2'

  it 'handles invalid input', ->
    assert.equal utils.addUrlParams(), undefined

describe 'getUrlParams', ->
  it 'gets params from url', ->
    assert.deepEqual \
      utils.getUrlParams('https://localhost?pear=sweet&cherry=sour'),
      { pear: 'sweet', cherry: 'sour' }

describe 'shareUrlSocial', ->
  it 'constructs share url', ->
    url = 'https://localhost'
    for k, v of { facebook: 'FB', google: 'G' }
      assert utils.shareUrlSocial(url, v).match new RegExp "#{k}.+localhost"

  it 'handles invalid input', ->
    assert.equal utils.shareUrlSocial(), undefined

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

# Calc / conversion -----------------------------------------------------------

describe 'parseNum', ->
  it 'parses float', ->
    assert.equal utils.parseNum('4.5'), 4.5

  it 'parses int', ->
    assert.equal utils.parseNum('4.5', int: true), 4

  it 'parses with default', ->
    assert.equal utils.parseNum(), undefined
    assert.equal utils.parseNum('pear', def: 0), 0

describe 'limitNum', ->
  it 'limits number with all param passing methods', ->
    for p in [ { min: 200, max: 300 }, { min: 200 }, { max: 300 }, {} ]
      for num in [ 100, 250, 350 ]
        expected = if num < p.min
          p.min
        else if num > p.max
          p.max
        else
          num

        assert.equal utils.limitNum(num, p.min, p.max), expected
        assert.equal utils.limitNum(num, [ p.min, p.max ]), expected
        assert.equal utils.limitNum(num, p), expected

  it 'handles invalid input', ->
    assert isNaN utils.limitNum()
    assert isNaN utils.limitNum 'x'

describe 'calcRank', ->
  it 'calcs default rank', ->
    assert.equal utils.calcRank(), 1

  it 'calcs basic rank', ->
    assert.equal utils.calcRank(2, 4), 3

  it 'calcs forward rank', ->
    assert.equal utils.calcRank(5), 6

  it 'calcs backward rank', ->
    assert.equal utils.calcRank(null, 4), 2
    assert.equal utils.calcRank(null, 0.2, signed: true), -0.8

describe 'num2Letters', ->
  it 'converts num to one char', ->
    assert.equal utils.num2Letters(2), 'B'

  it 'converts num to two chars', ->
    assert.equal utils.num2Letters(28), 'AB'

  it 'returns undefined on invalid input', ->
    assert.strictEqual utils.num2Letters('pear'), undefined

  it 'returns empty string on 0 or less', ->
    assert.equal utils.num2Letters(num), '' for num in [ 0, -2 ]

describe 'maxVersion', ->
  it 'picks the max version', ->
    assert.equal utils.maxVersion('1.2', '1.1.0', '1.3'), '1.3'
    assert.equal utils.maxVersion('1.2', '1.8.9', 3, '0.1'), 3

describe 'isNewerVersion', ->
  it 'determines the newer version', ->
    assert utils.isNewerVersion '1.4', '1.2'
    assert utils.isNewerVersion '1.2.6', '1.2.3'
    assert !utils.isNewerVersion '1.2', '1.2'
    assert !utils.isNewerVersion '1.2.2', '1.2.3'

describe 'sort', ->
  beforeEach ->
    @nums = [ 5, 3, 2, 9 ]
    @strs = [ 'mango', 'carrot', 'pear', 'banana' ]
    @props = [
      name  : 'carrot'
      type  : 'vegetable'
      value : 0
    ,
      name  : 'mango 2'
      type  : 'fruit'
      value : 2
    ,
      name  : 'banana'
      type  : 'fruit'
    ,
      name  : 'mango 10'
      type  : 'fruit'
      value : 4
    ,
      name  : 'carrot'
      type  : 'vegetable'
      value : 3
    ]
    prop.id = i for prop, i in @props

  it 'sorts nums', ->
    assert.deepEqual @nums.sort(utils.sort), [ 2, 3, 5, 9 ]

  it 'sorts nums desc', ->
    assert.deepEqual \
      @nums.sort( (a, b) -> utils.sort a, b, desc: true),
      [ 9, 5, 3, 2 ]

  it 'sorts strings', ->
    assert.deepEqual @strs.sort(utils.sort),
      [ 'banana', 'carrot', 'mango', 'pear' ]

  it 'sorts collections', ->
    assert.deepEqual \
      _.pluck(@props.sort( (a, b) ->
        utils.sort a, b, [
          'type'
        ,
          name    : 'name'
          natural : true
        ,
          name : 'value'
          desc : true
        ]), 'id'),
      [ 2, 1, 3, 4, 0 ]
