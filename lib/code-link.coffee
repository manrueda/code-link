url = require 'url'
{shell} = require 'electron'
_ = require 'underscore-plus'

selector = null
PROTOCOL = 'file:'

module.exports =
  activate: ->
    atom.commands.add('atom-workspace', 'link:open', openLink)

openLink = ->
  editor = atom.workspace.getActiveTextEditor()
  return unless editor?

  link = linkUnderCursor(editor)
  return unless link?

  if editor.getGrammar().scopeName is 'source.gfm'
    link = linkForName(editor.getBuffer(), link)

  {protocol, host, path} = url.parse(link)
  host = host + (if path != '/' then path else '')
  if protocol is PROTOCOL
    # Exract the file and line number of the host (try with a second regex if the file doesn't have line number)
    extract = host.match(/^(.*)\:(\d*)$/i) || host.match(/^(.*)$/)
    extract[2] = extract[2] || 1 # if the line number is missing, put one

    atom.workspace.open(extract[1]).then (editor) ->
      editor.setCursorScreenPosition([extract[2] - 1, 0]);

# Get the link under the cursor in the editor
#
# Returns a {String} link or undefined if no link found.
linkUnderCursor = (editor) ->
  cursorPosition = editor.getCursorBufferPosition()
  link = linkAtPosition(editor, cursorPosition)
  return link if link?

  # Look for a link to the left of the cursor
  if cursorPosition.column > 0
    linkAtPosition(editor, cursorPosition.translate([0, -1]))

# Get the link at the buffer position in the editor.
#
# Returns a {String} link or undefined if no link found.
linkAtPosition = (editor, bufferPosition) ->
  unless selector?
    {ScopeSelector} = require 'first-mate'
    selector = new ScopeSelector('markup.underline.link')

  if token = editor.tokenForBufferPosition(bufferPosition)
    token.value if token.value and selector.matches(token.scopes)

# Get the link for the given name.
#
# This is for Markdown links of the style:
#
# ```
# [label][name]
#
# [name]: https://github.com
# ```
#
# Returns a {String} link
linkForName = (buffer, linkName) ->
  link = linkName
  regex = new RegExp("^\\s*\\[#{_.escapeRegExp(linkName)}\\]\\s*:\\s*(.+)$", 'g')
  buffer.backwardsScanInRange regex, buffer.getRange(), ({match, stop}) ->
    link = match[1]
    stop()
  link
