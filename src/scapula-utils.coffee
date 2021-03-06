_ = require 'underscore'

utils =
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

  encodeHtml: (str) ->
    return str unless str?
    str.toString()
       .replace /&/g, '&amp;'
       .replace /</g, '&lt;'
       .replace />/g, '&gt;'
       .replace /\n$/, '<br>&nbsp;'
       .replace /\n/g, '<br>'
       .replace /\s{2,}/g, (space) ->
         res = ''
         res += '&nbsp;' for num in [ 1 .. space.length ]
         res

  decodeHtml: (str) ->
    return str unless str?
    str.toString()
       .replace /\s+/g, ' '
       .replace /&lt;/g, '<'
       .replace /&gt;/g, '>'
       .replace /&nbsp;/g, ' '
       .replace /&amp;/g, '&'
       .replace /<br\s*\/?>$/, ''
       .replace /<br\s*\/?>/g, "\n"
       .trim()

  quoteMeta: (str) ->
    return str unless str?
    str.toString().replace /([\.\\\+\*\?\[\^\]\$\(\)\-\{\}\|])/g, '\\$1'

  startMatch: (str, kw) ->
    return null unless str? && kw?
    str.toString().trim().match new RegExp '^' + @quoteMeta(kw), 'i'

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

  # Calc / conversion ---------------------------------------------------------

  parseNum: (num, opts = {}) ->
    num = if opts.int then parseInt num else parseFloat num
    num = opts.def if isNaN num
    num

  limitNum: (val, min, max) ->
    if _.isFinite val = parseFloat val
      limits = if _.isArray min
        min: min[0], max: min[1]
      else if _.isObject min
        min
      else
        min: min, max: max

      for op, limit of { min: 'max', max: 'min' }
        val = _[op] [ v, val ] if _.isFinite v = parseFloat limits[limit]

    val

  roundTo: (val, prec) ->
    if _.isFinite val = parseFloat val
      prec = if _.isFinite(prec) then prec else 0
      if prec < 0
        parseFloat((val * 10 ** prec).toFixed()) * 10 ** Math.abs prec
      else
        parseFloat val.toFixed prec

  getFrac: (num, len) ->
    frac = num?.toString().match(/\.\d+$/)?[0]
    if frac
      len = frac.length unless _.isFinite len
      frac = frac.substr 0, len + 1
    frac

  calcRank: (prev, next, opts) ->
    prev = @parseNum prev if prev?
    next = @parseNum next if next?

    if prev? && !next?
      prev + 1
    else if !prev? && next?
      if opts?.signed
        next - 1
      else
        next / 2
    else if prev? && next?
      (next + prev) / 2
    else
      1

  prec2Step: (prec = 0) ->
    if _.isFinite prec = parseInt prec
      1 / (10 ** prec)

  num2Letters: (num) ->
    return unless _.isFinite num = parseInt num

    ret = ''
    while num > 0
      mod = (num - 1) % 26
      ret = String.fromCharCode(65 + mod) + ret
      num = parseInt (num - mod) / 26

    ret

  maxVersion: ->
    args = [].slice.call arguments
    nums = 3 # semVer

    _.max args, (arg) ->
      arg = arg.toString().split '.'
      arg.splice nums
      _.reduce arg, (memo, val, idx) ->
        val = if _.isFinite(val) then parseInt(val) else 0
        memo + (Math.pow(10, (nums - idx) * 3) * val)
      , 0

  isNewerVersion: (v1, v2) ->
    v1 isnt v2 && @maxVersion(v1, v2) is v1

  formatFileSize: (size, opts = {}) ->
    if _.isFinite size = parseFloat size
      unit = if opts.unit in [ 'k', 'M', 'G' ]
        opts.unit
      else
        'M'

      size /= 1024
      if unit isnt 'k'
        size /= 1024 ** (if unit is 'G' then 2 else 1)

      @roundTo(size, opts.prec ? 2) + unit
    else
      opts.na ? 'NA'

  # Misc ----------------------------------------------------------------------

  _sort: (a, b, opts = {}) ->
    ret = if b? && (!a? && !opts.nullToEnd || a? && a < b) ||
        a? && !b? && opts.nullToEnd
      -1
    else if a? && (!b? && !opts.nullToEnd || b? && a > b) ||
        b? && !a? && opts.nullToEnd
      1

    ret *= -1 if ret && opts.desc
    ret

  sort: (a, b, props, opts) ->
    if !_.isArray(props) && _.isObject props
      opts = props
      props = null
    else
      opts ?= {}

    ret = 0

    if props
      props = [ props ] unless _.isArray props
      for prop in props
        cmp = []
        pname = if _.isObject prop then prop.name else prop
        popts = if _.isObject prop then _.omit prop, 'name' else {}
        _.defaults popts, opts, attr: true
        for obj in [ a, b ]
          if _.isArray pname
            for altpname in pname
              tmp = utils.getProp obj, altpname, popts
              break if tmp?
          else
            tmp = utils.getProp obj, pname, popts

          if popts.natural && _.isString tmp
            pad = popts.pad ? 10
            tmp = tmp
              .replace /(\d+)/g, Array(pad + 1).join('0') + '$1'
              .replace new RegExp("0*(\\d\{#{pad},\})", 'g'), '$1'
              .replace /@/g, ' '
              .toLowerCase()

          cmp.push tmp

        ret = @_sort.apply @, cmp.concat(popts)
        break if ret
    else
      ret = @_sort a, b, opts

    ret

  # URL / Link / Client -------------------------------------------------------

  addUrlParams: (url, params, opts = {}) ->
    if url? && !_.isEmpty params
      url += (if url.match /\?/ then '&' else '?') +
        _.map(_.pairs(params), (p) ->
          p[1] = encodeURIComponent p[1] if opts.encode
          p.join '='
        ).join '&'

    url

  getUrlParams: (url) ->
    paramstr = if url?
      url.toString().match(/\?(.+)$/)?[1]
    else
      window?.location.search[1..]

    if paramstr
      _.object _.compact _.map paramstr.split('&'), (item) ->
        item?.split '='

  shareUrlSocial: (url, prov) ->
    if url?
      base = if prov is 'FB'
        'https://www.facebook.com/sharer/sharer.php?u='
      else
        'https://plus.google.com/share?url='

      url = base + encodeURIComponent url

    url

  videoUrl: (vid, opts = {}) ->
    return unless vid
    prot = opts.protocol || window?.location.protocol || 'https'
    prot += ':' unless prot.match /:$/

    url = if !opts.type || opts.type is 'youtube'
      if opts.iframe
        'www.youtube-nocookie.com/embed/'
      else
        'www.youtube.com/watch?v='
    else if opts.type is 'vimeo'
      if opts.iframe
        'player.vimeo.com/video/'
      else
        'vimeo.com/'

    "#{prot}//#{url}#{vid}" if url

  parseVideoUrl: (url) ->
    url = '' unless _.isString url
    if url.match /(?:youtube\.com\/watch.*[?&]v=|youtu\.be\/)([^&]+)/
      id: RegExp.$1, type: 'youtube'
    else if url.match /vimeo\.com\/(.+)$/
      id: RegExp.$1, type: 'vimeo'

  videoIframe: (vid, opts) ->
    opts = _.extend width: 320, height: 240, opts
    if (src = @videoUrl vid, _.extend iframe: true, opts)
      "<iframe frameborder=\"0\"
        width=\"#{opts.width}\"
        height=\"#{opts.height}\"
        src=\"#{src}\" allowfullscreen></iframe>"

  link: (link, opts = {}) ->
    return link unless link?
    text = utils.encodeHtml \
      opts.text || link.toString().replace /^https?:\/\//, ''
    ret = "<a href=\"#{link}\""
    ret += " target=\"#{opts.target}\"" if opts.target
    ret + ">#{text}</a>"

  mailtoLink: (recip, opts) ->
    return recip unless recip?
    lnk = "mailto:#{recip}"
    if _.isEmpty opts
      lnk
    else
      @addUrlParams lnk, opts, encode: true

  browser: (type, ver, ua = navigator.userAgent || '') ->
    ret = switch type?.toLowerCase()
      when 'ie'
        ua.match(/trident.+rv:(\d+)/i) || ua.match(/msie\s+(\d+)/i)
      when 'edge'
        ua.match /edge\/(\d+)/i
      when 'firefox'
        ua.match /firefox\/(\d+)/i
      when 'chrome'
        ua.match /(?:crios|chrome)\/(\d+)/i
      when 'safari'
        ua.match /version\/(\d+).+safari/i

    if ret
      ret = parseInt ret[1]
      verChk = ver?.toString().match(/^(\d+)([+-]?)$/)
      if verChk
        num = parseInt verChk[1]
        rel = verChk[2]

        ret = if rel
          if rel is '+' then ret >= num else ret <= num
        else
          ret == num

    ret

  platform: (type, platform = navigator.platform || '') ->
    ret = switch type?.toLowerCase()
      when 'linux' then platform.match /^linux/i
      when 'mac' then platform.match /^mac/i
      when 'win' then platform.match /^win/i
      when 'ios' then platform.match /(ipad|ipod|iphone)/i

    ret

  isMobile: (ua = navigator.userAgent || '') ->
    ua.match /(mobi|android)/i

  selectOptions: (opts = {}) ->
    ret = ''

    _buildOption = (_opt) =>
      if _.isObject(_opt) && _opt.value?
        value = @encodeHtml _opt.value
        descr = if _opt.descr? then @encodeHtml _opt.descr else value
        _ret = "<option value=\"#{value}\""
        _ret += ' selected="selected"' if _opt.sel
        _ret + ">#{descr}</option>"

    if _.isArray opts.optgroups
      for optgroup in opts.optgroups
        if _.isObject(optgroup) && optgroup.label? &&
            _.isArray(optgroup.options) && optgroup.options.length
          ret += "<optgroup label=\"#{@encodeHtml optgroup.label}\">"
          ret += _buildOption option for option in optgroup.options
          ret += '</optgroup>'
    else if _.isArray opts.options
      ret += _buildOption option for option in opts.options

    ret

for fname, func of utils
  utils[fname] = func.bind utils if _.isFunction func

module.exports = utils
