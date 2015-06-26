###
  ActionBarViewControllers are able to declare actions and breadcrumbs in their parent navigation controller action bar.
###
class ledger.common.ActionBarViewController extends ledger.common.ViewController

  breadcrumb: undefined
  actions: undefined

  getActionBarDeclaration: ->
    breadcrumb = @breadcrumb or []
    actions = _.clone(@actions) or []
    url = @routedUrl or ''
    models = ledger.database.Model.AllModelClasses()
    modelNames = _(_(models).chain().keys().map((i) -> _.str.underscored(_.pluralize(i)).toLowerCase()).value())
    unless @breadcrumb?
      parts = (i.slice 1 for i in url.match(/\/\w+/g))
      ids = _([])
      for part, index in parts
        title = null
        url = null
        previousPart = parts[index - 1]
        if previousPart? and parts[index + 1]? and modelNames.contains(previousPart)
          ModelClass = models[_.str.capitalize(_.str.camelize(_.singularize(previousPart)))]
          instance = ModelClass.findById(if _.isNaN(+part) then part else +part)
          l "Got ", ModelClass, (if _.isNaN(+part) then part else +part), instance
          if instance?
            title = instance.get('name') or instance.get('title') or instance.get('label')
            ids.push(index)
        unless title?
          title = t("#{parts[0]}.breadcrumb" + ('.' + i for i, j in parts.slice(1, index + 1) when !ids.contains(j + 1)).join(''))
        url = '/' + (i for i in parts.slice(0, index + 1)).join('/')
        breadcrumb.push {title, url} unless index is 0
    l {breadcrumb, actions}
    {breadcrumb, actions}