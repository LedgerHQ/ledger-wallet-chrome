class @SpecIndexViewController extends ledger.specs.ViewController

  view:
    filter: '#filter'
    suitesTree: '#suites_tree'

  initialize: ->
    super
    @_selectedSpecs = []

  onBeforeRender: ->
    super
    @topSuite = jasmine.getEnv().topSuite()

  onAfterRender: ->
    super
    @renderSuitesNodes = _.debounce(@renderSuitesNodes, 200)
    @view.filter.on 'input', @renderSuitesNodes
    @renderSuitesNodes()

  renderSuitesNodes: ->
    filter = @view.filter.val()
    filteredResult = @_filterSpecs(filter, @topSuite) or {children: []}
    @_renderNode(filteredResult).then (html) =>
      @view.suitesTree.html(html)

  onDetach: ->
    super
    @view.filter.off 'input', @renderSuitesNodes

  runSpec: ({id}) ->

  runSelectedSpec: () ->

  toggleSpec: ({id}) ->
    if _.contains(@_selectedSpecs, id)
      @_selectedSpecs = _.without(@_selectedSpecs, id)
    else
      @_selectedSpecs.push id
      @_selectedSpecs = _.uniq(@_selectedSpecs)

  _filterSpecs: (filter, root) ->
    return root if _.isString(filter) and _.isEmpty(filter)
    unless filter?.regexp?
      words = _.str.clean(filter).split(/\s+/)
      filter = regexp: new RegExp(words.join('|'), 'ig'), requiredMatch: words.length
    if root.description.match(filter.regexp)?.length is filter.requiredMatch
      root
    else if root.children?
      node = _.clone(root)
      node.children = _.compact(@_filterSpecs(filter, child) for child in root.children)
      if node.children.length is 0 then null else node
    else
      null

  _renderNode: (node, depth = -1) ->
    d = ledger.defer()
    onSelfRender = (html) =>
      d.resolve(html) if !node.children? or node.children.length is 0
      Q.all(@_renderNode(child, depth + 1) for child in node.children)
      .then (htmls) ->
        d.resolve(html + htmls.join(''))
      .done()
    if depth is -1
      onSelfRender('')
    else
      @_renderPartial(node, depth).then(onSelfRender)
    d.promise

  _renderPartial: (node, depth) ->
    d = ledger.defer()
    data =
      id: node.id
      name: node.description
      depth: depth
      isSuite: node.constructor.name is 'Suite'
      isSelected: _.contains(@_selectedSpecs, node.id)
    render 'spec/_suite_node', data, (html) -> d.resolve(html)
    d.promise