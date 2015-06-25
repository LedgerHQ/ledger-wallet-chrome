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
    unless @breadcrumb?
      parts = (i.slice 1 for i in url.match(/\/\w+/g))
      for part, index in parts
        title = "#{parts[0]}.breadcrumb" + ('.' + i for i in parts.slice(1, index + 1)).join('')
        url = '/' + (i for i in parts.slice(0, index + 1)).join('/')
        breadcrumb.push {title, url} unless index is 0
    l {breadcrumb, actions}
    {breadcrumb, actions}