<script>
  import { onMount } from "svelte"
  import { basicSetup } from "codemirror"
  import { EditorView, keymap } from "@codemirror/view"
  import { EditorState, EditorSelection } from "@codemirror/state"
  import { indentUnit, StreamLanguage, syntaxHighlighting } from "@codemirror/language"
  import { autocompletion } from "@codemirror/autocomplete"
  import { linter, lintGutter } from "@codemirror/lint"
  import { OWLanguage, highlightStyle } from "../../lib/OWLanguageLegacy"
  import { OWLanguageLinter } from "../../lib/OWLanguageLinter"
  import { currentItem, editorStates, items } from "../../stores/editor"
  import debounce from "../../debounce"

  export let completionsMap = []

  let element
  let view
  let currentId

  $: if ($currentItem.id != currentId && view) updateEditorState()

  onMount(() => {
    view = new EditorView({
      parent: element
    })
  })

  function updateEditorState() {
    if (currentId) $editorStates[currentId] = view.state

    currentId = $currentItem.id

    if ($editorStates[currentId]) {
      view.setState($editorStates[currentId])
      return
    }

    $editorStates[currentId] = createEditorState($currentItem.content)
    view.setState($editorStates[currentId])
  }

  function createEditorState(content) {
    return EditorState.create({
      doc: content,
      extensions: [
        syntaxHighlighting(highlightStyle),
        StreamLanguage.define(OWLanguage),
        autocompletion({
          activateOnTyping: true,
          override: [completions],
          closeOnBlur: false,
          hintOptions: /[()\[\]{};:>,+-=]/
        }),
        lintGutter(),
        linter(OWLanguageLinter),
        indentUnit.of("    "),
        keymap.of([
          { key: "Tab", run: tabIndent },
          { key: "Shift-Tab", run: tabIndent },
          { key: "Enter", run: autoIndentOnEnter }
        ]),
        EditorView.updateListener.of((state) => {
          if (state.docChanged) updateItem()
        }),
        basicSetup
      ]
    })
  }

  function completions(context) {
    const word = context.matchBefore(/[a-zA-Z0-9 ]*/)

    const add = word.text.search(/\S|$/)
    if (word.from + add == word.to && !context.explicit) return null

    return {
      from: word.from + add,
      to: word.to,
      options: completionsMap,
      validFor: /^(?:[a-zA-Z0-9]+)$/i
    }
  }

  function keydown(event) {
    if (event.ctrlKey && event.keyCode == 50) {
      event.preventDefault()
      view.focus()
    }
  }

  function autoIndentOnEnter({ state, dispatch }) {
    const changes = state.changeByRange(range => {
      const { from, to } = range, line = state.doc.lineAt(from)

      const indent = getIntendForLine(state, from)
      let insert = "\n"
      for (let i = 0; i < indent; i++) { insert += "\t" }

      const openBracket = /[\{\(\[]/gm.exec(state.doc.lineAt(from).text)?.[0].length
      const closeBracket = /[\}\)\]]/gm.exec(state.doc.lineAt(from).text)?.[0].length
      if (openBracket && !closeBracket) insert += "\t"

      return { changes: { from, to, insert }, range: EditorSelection.cursor(from + insert.length) }
    })

    dispatch(state.update(changes, { scrollIntoView: true, userEvent: "input" }))
    return true
  }

  function tabIndent({ state, dispatch }) {
    const { shiftKey } = event

    if (element.querySelector(".cm-tooltip-autocomplete")) return true

    const changes = state.changeByRange(range => {
      const { from, to } = range, line = state.doc.lineAt(from)

      let insert = ""

      if (from == to && !shiftKey) {
        const previousIndent = getIntendForLine(state, from - 1)
        const currentIndent = getIntendForLine(state, from)

        insert = "\t"
        if (currentIndent < previousIndent) {
          for (let i = 0; i < previousIndent - 1; i++) { insert += "\t" }
        }

        return {
          changes: { from, to, insert },
          range: EditorSelection.cursor(from + insert.length)
        }
      } else {
        let insert = view.state.doc.toString().substring(line.from, to)

        const originalLength = insert.length
        const leadingWhitespaceLength = insert.search(/\S/)

        if (shiftKey) {
          if (!/^\s/.test(insert[0]) && !(insert.includes("\n ") || insert.includes("\n\t"))) return { range: EditorSelection.range(from, to) }

          insert = insert.replaceAll(/\n[ \t]/g, "\n").substring(insert.search(/\S/) ? 1 : 0, insert.length)
        } else {
          insert = "\t" + insert.replaceAll("\n", "\n\t")
        }

        const fromModifier = insert.search(/\S/) - leadingWhitespaceLength
        const toModifier = insert.length - originalLength

        return {
          changes: { from: line.from, to, insert },
          range: EditorSelection.range(from + fromModifier, to + toModifier)
        }
      }
    })

    dispatch(state.update(changes, { scrollIntoView: true, userEvent: "input" }))
    dispatch({ selection: EditorSelection.create(changes.selection.ranges) })

    return true
  }

  function getIntendForLine(state, line) {
    line = Math.max(line, 0)

    const spaces = /^\s*/.exec(state.doc.lineAt(line).text)?.[0].length
    const tabs = /^\t*/.exec(state.doc.lineAt(line).text)?.[0].length
    return Math.floor(spaces / 4) + tabs
  }

  const updateItem = debounce(() => {
    $currentItem.content = view.state.doc.toString()
    const index = $items.indexOf(i => i.id == $currentItem.id)
    $items[index] = $currentItem
  }, 250)
</script>

<svelte:window on:keydown={keydown} />

<div bind:this={element} ></div>
