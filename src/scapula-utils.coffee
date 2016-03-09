_ = require 'underscore'

module.exports =
  # String --------------------------------------------------------------------

  capitalize: (str) ->
    return unless _.isString str
    str = str.toString()
    str.charAt(0).toUpperCase() + str.slice(1)

  splitName: (str) ->
    return unless _.isString str
    str = str.trim()

    lname = if str.match /,/
      arr = str.split(/\s*,\s*/)
      arr.shift()
    else
      arr = str.split(/\s+/)
      arr.pop()

    fname = arr.join ' '

    [ fname.trim(), lname.trim() ]

  joinName: (first = '', last = '', opts = {}) ->
    names = []
    for n in [ first.toString().trim(), last.toString().trim() ]
      names.push n if n
    if opts.sort
      names.reverse().join ', '
    else
      names.join ' '

  wrap: (str, wrapper, opts = {}) ->
    return str unless str && wrapper
    qs = if _.isArray wrapper
      wrapper
    else if opts.split && wrapper.length > 1
      wrapper.split ''
    else
      [ wrapper, wrapper ]

    if opts.quote
      qs = _.map qs, (q) -> '\\' + q

    qs[0] + str + qs[1]

  extractKeywords: (str, opts = {}) ->
    ret = '' : []
    str = str.toString().trim() if str?
    if str
      opts = '"' : '' if _.isEmpty opts

      _sortFunc = (a, b) ->
        if a[1] < b[1]
          1
        else if a[1] > b[1]
          -1
        else
          0

      markitems = _.pairs opts
      markitems.sort _sortFunc

      for markitem in markitems
        [mark, type] = markitem
        ret[type] ?= []

        qre = @wrap '(.*?)', mark, quote: true, split: true
        str = str.replace new RegExp(qre, 'g'), (match, capture, pos) ->
          capture = capture.trim()
          ret[type].push [capture, pos] if capture
          Array(match.length + 1).join(' ')

      str = str.replace /(\S+)/g, (match, capture, pos) ->
        ret[''].push [capture, pos]

      for type of ret
        ret[type] = _.map ret[type].sort(_sortFunc).reverse(), (arr) -> arr[0]

    if _.keys(ret).length == 1 then ret[''] else ret

  # Checkers ------------------------------------------------------------------

  REG_EMAIL : '[-_a-z0-9]+(\\.[-_a-z0-9]+)*@[-a-z0-9]+(\\.[-a-z0-9]+)' +
              '*\\.[a-z]{2,6}'
  REG_IP    : '([01]?\\d\\d?|2[0-4]\\d|25[0-5])' +
              '(\\.([01]?\\d\\d?|2[0-4]\\d|25[0-5])){3}'
  REG_HOST  : '[a-z\\d]([a-z\\d\\-]{0,61}[a-z\\d])?' +
              '(\\.[a-z\\d]([a-z\\d\\-]{0,61}[a-z\\d])?)*'

  _chkRegExp: (str, re_name) ->
    re = new RegExp "^#{@[re_name]}$", 'i'
    str if str?.toString().match re

  chkEmail: (str) ->
    @_chkRegExp str, 'REG_EMAIL'

  chkIP: (str) ->
    @_chkRegExp str, 'REG_IP'

  chkHost: (str) ->
    @_chkRegExp str, 'REG_HOST' if str?.toString().length <= 255

  # Object / "class" ----------------------------------------------------------

  extendMethod: (to, from, methodName) ->
    if _.isFunction(to[methodName]) && _.isFunction(from[methodName])
      old = to[methodName]
      to[methodName] = ->
        oldReturn = old.apply @, arguments
        from[methodName].apply @, arguments
        oldReturn

  mixin: (mixins..., classRef) ->
    to = classRef::
    for mixin in mixins
      for method of mixin
        @extendMethod to, mixin, method
      _.defaults to, mixin
      _.defaults to.events, mixin.events
    classRef
   
  obj2Array: (obj, opts) ->
    ret = []
    if _.isObject obj
      keyname = opts?.keyname || 'type'
      for key, val of obj
        val = if _.isObject val
          _.clone val
        else
          value: val
        val[keyname] = key
        ret.push val

    ret

  getProp: (obj, prop, opts) ->
    if opts?.attr && _.isFunction obj.get
      obj.get prop
    else
      _.result obj, prop

  # obj, srcobj, props as args || props array
  adoptProps: ->
    args = [].slice.call arguments
    obj = args.shift()
    srcobj = args.shift()
    if _.isObject(obj) && _.isObject(srcobj)
      keys = if _.isArray args[0] then args[0] else args
      _.extend obj, _.pick srcobj, keys
