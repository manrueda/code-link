{shell} = require 'electron'

describe "code-link package", ->
  beforeEach ->
    waitsForPromise ->
      atom.packages.activatePackage('language-gfm')

    waitsForPromise ->
      atom.packages.activatePackage('language-javascript')

    waitsForPromise ->
      atom.packages.activatePackage('language-hyperlink')

    waitsForPromise ->
      activationPromise = atom.packages.activatePackage('code-link')
      atom.commands.dispatch(atom.views.getView(atom.workspace), 'link:open')
      activationPromise

  describe "when the cursor is on a link", ->
    it "opens the link using the 'open' command", ->
      waitsForPromise ->
        atom.workspace.open('sample.js')

      runs ->
        editor = atom.workspace.getActiveTextEditor()
        editor.setText("// \"file://package.json:10\"")

        spyOn(atom.workspace, 'open').andCallThrough();
        spyOn(editor, 'setCursorScreenPosition').andCallThrough();

        atom.commands.dispatch(atom.views.getView(editor), 'link:open')
        expect(atom.workspace.open).not.toHaveBeenCalled()

        editor.setCursorBufferPosition([0, 17])

        atom.commands.dispatch(atom.views.getView(editor), 'link:open')

        expect(atom.workspace.open).toHaveBeenCalled()
        expect(atom.workspace.open.argsForCall[0][0]).toBe 'package.json'

        atom.workspace.open.reset()
        editor.setCursorBufferPosition([0, 8])
        atom.commands.dispatch(atom.views.getView(editor), 'link:open')

        expect(atom.workspace.open).toHaveBeenCalled()
        expect(atom.workspace.open.argsForCall[0][0]).toBe 'package.json'

        atom.workspace.open.reset()
        editor.setCursorBufferPosition([0, 21])
        atom.commands.dispatch(atom.views.getView(editor), 'link:open')

        expect(atom.workspace.open).toHaveBeenCalled()
        expect(atom.workspace.open.argsForCall[0][0]).toBe 'package.json'

    describe "when the cursor is on a [name][url-name] style markdown link", ->
      it "opens the named url", ->
        waitsForPromise ->
          atom.workspace.open('README.md')

        runs ->
          editor = atom.workspace.getActiveTextEditor()
          editor.setText """
            you should [click][here]
            you should not [click][her]

            [here]: file://package.json:10
          """

          spyOn(atom.workspace, 'open').andCallThrough();
          editor.setCursorBufferPosition([0, 0])
          atom.commands.dispatch(atom.views.getView(editor), 'link:open')
          expect(atom.workspace.open).not.toHaveBeenCalled()

          editor.setCursorBufferPosition([0, 20])
          atom.commands.dispatch(atom.views.getView(editor), 'link:open')

          expect(atom.workspace.open).toHaveBeenCalled()
          expect(atom.workspace.open.argsForCall[0][0]).toBe 'package.json'

          atom.workspace.open.reset()
          editor.setCursorBufferPosition([1, 24])
          atom.commands.dispatch(atom.views.getView(editor), 'link:open')

          expect(atom.workspace.open).not.toHaveBeenCalled()

    it "does not open http/https links", ->
      waitsForPromise ->
        atom.workspace.open('sample.js')

      runs ->
        editor = atom.workspace.getActiveTextEditor()
        editor.setText("// http://github.com\n")

        spyOn(atom.workspace, 'open').andCallThrough();
        atom.commands.dispatch(atom.views.getView(editor), 'link:open')
        expect(atom.workspace.open).not.toHaveBeenCalled()

        editor.setCursorBufferPosition([0, 5])
        atom.commands.dispatch(atom.views.getView(editor), 'link:open')

        expect(atom.workspace.open).not.toHaveBeenCalled()
