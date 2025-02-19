<template>
  <section class="editor">
    <span ref="editorButtons"></span>
    <div
      class="head flex flex-wrap gap-1 font-semibold"
      :class="{ stickyButtons: editorButtonsTop < 30 }"
    >
      <button type="button" class="!p-0 relative">
        <input
          class="w-full h-full opacity-0"
          type="color"
          @input="
            editor
              .chain()
              .focus()
              .setHighlight({ color: $event.target.value })
              .run()
          "
          :value="editor.getAttributes('highlight').color || '#000000'"
        />
        <UIcon
          name="i-material-symbols-format-color-fill"
          :style="'color:' + editor.getAttributes('highlight').color"
          dynamic
          class="absolute pointer-events-none"
        />
      </button>
      <button type="button" class="!p-0 relative cursor-pointer">
        <input
          class="w-full h-full opacity-0 cursor-pointer"
          type="color"
          @input="editor.chain().focus().setColor($event.target.value).run()"
          :value="editor.getAttributes('textStyle').color || '#000000'"
        />
        <UIcon
          name="i-material-symbols-format-color-text"
          :style="'color:' + editor.getAttributes('textStyle').color"
          dynamic
          class="absolute pointer-events-none"
        />
      </button>
      <button
        type="button"
        @click="editor.chain().focus().toggleBold().run()"
        :disabled="!editor.can().chain().focus().toggleBold().run()"
        :class="{ 'is-active': editor.isActive('bold') }"
      >
        B
      </button>
      <button
        type="button"
        @click="editor.chain().focus().toggleItalic().run()"
        :disabled="!editor.can().chain().focus().toggleItalic().run()"
        :class="{ 'is-active': editor.isActive('italic') }"
      >
        <UIcon name="i-ph-text-italic" class="w-4 h-4 md:w-6 md:h-6" dynamic />
      </button>
      <button
        type="button"
        @click="editor.chain().focus().toggleStrike().run()"
        :disabled="!editor.can().chain().focus().toggleStrike().run()"
        :class="{ 'is-active': editor.isActive('strike') }"
      >
        <del>S</del>
      </button>
      <button
        type="button"
        @click="editor.chain().focus().unsetAllMarks().run()"
      >
        <UIcon
          name="i-mingcute-broom-line"
          class="w-4 h-4 md:w-6 md:h-6"
          dynamic
        />
      </button>
      <button
        type="button"
        @click="editor.chain().focus().setParagraph().run()"
        :class="{ 'is-active': editor.isActive('paragraph') }"
      >
        P
      </button>
      <button
        type="button"
        @click="editor.chain().focus().toggleHeading({ level: 1 }).run()"
        :class="{ 'is-active': editor.isActive('heading', { level: 1 }) }"
      >
        H1
      </button>
      <button
        type="button"
        @click="editor.chain().focus().toggleHeading({ level: 2 }).run()"
        :class="{ 'is-active': editor.isActive('heading', { level: 2 }) }"
      >
        H2
      </button>
      <button
        type="button"
        @click="editor.chain().focus().toggleHeading({ level: 3 }).run()"
        :class="{ 'is-active': editor.isActive('heading', { level: 3 }) }"
      >
        H3
      </button>
      <button
        type="button"
        @click="editor.chain().focus().toggleHeading({ level: 4 }).run()"
        :class="{ 'is-active': editor.isActive('heading', { level: 4 }) }"
      >
        H4
      </button>
      <button
        type="button"
        @click="editor.chain().focus().toggleHeading({ level: 5 }).run()"
        :class="{ 'is-active': editor.isActive('heading', { level: 5 }) }"
      >
        H5
      </button>
      <button
        type="button"
        @click="editor.chain().focus().toggleHeading({ level: 6 }).run()"
        :class="{ 'is-active': editor.isActive('heading', { level: 6 }) }"
      >
        H6
      </button>

      <button
        type="button"
        @click="editor.chain().focus().toggleHighlight().run()"
        :class="{ 'is-active': editor.isActive('highlight') }"
      >
        H
      </button>

      <button
        type="button"
        @click="editor.chain().focus().toggleBulletList().run()"
        :class="{ 'is-active': editor.isActive('bulletList') }"
      >
        <UIcon
          name="i-ic-format-list-bulleted"
          class="w-4 h-4 md:w-6 md:h-6"
          dynamic
        />
      </button>
      <button
        type="button"
        @click="editor.chain().focus().toggleOrderedList().run()"
        :class="{ 'is-active': editor.isActive('orderedList') }"
      >
        <UIcon
          name="i-ic-format-list-numbered"
          class="w-4 h-4 md:w-6 md:h-6"
          dynamic
        />
      </button>
      <button
        type="button"
        @click="editor.chain().focus().toggleCode().run()"
        :disabled="!editor.can().chain().focus().toggleCode().run()"
        :class="{ 'is-active': editor.isActive('code') }"
      >
        <UIcon name="i-ic-outline-code" class="w-4 h-4 md:w-6 md:h-6" dynamic />
      </button>
      <button
        type="button"
        @click="editor.chain().focus().toggleCodeBlock().run()"
        :class="{ 'is-active': editor.isActive('codeBlock') }"
      >
        <UIcon
          name="i-material-symbols-light-terminal"
          class="w-4 h-4 md:w-6 md:h-6"
          dynamic
        />
      </button>
      <button
        type="button"
        @click="editor.chain().focus().toggleBlockquote().run()"
        :class="{ 'is-active': editor.isActive('blockquote') }"
      >
        <UIcon name="i-ic-format-quote" class="w-4 h-4 md:w-6 md:h-6" dynamic />
      </button>
      <button type="button" @click="editor.chain().focus().clearNodes().run()">
        <UIcon
          name="i-mingcute-broom-line"
          class="w-4 h-4 md:w-6 md:h-6"
          dynamic
        />
      </button>
      <button
        type="button"
        @click="editor.chain().focus().setHorizontalRule().run()"
      >
        <UIcon
          name="i-ic-sharp-horizontal-rule"
          class="w-4 h-4 md:w-6 md:h-6"
          dynamic
        />
      </button>
      <button
        type="button"
        @click="editor.chain().focus().setHardBreak().run()"
      >
        <UIcon name="i-codicon-newline" class="w-4 h-4 md:w-6 md:h-6" dynamic />
      </button>

      <button
        type="button"
        @click="editor.chain().focus().undo().run()"
        :disabled="!editor.can().chain().focus().undo().run()"
      >
        <UIcon
          name="i-material-symbols-undo"
          class="w-4 h-4 md:w-6 md:h-6"
          dynamic
        />
      </button>
      <button
        type="button"
        @click="editor.chain().focus().redo().run()"
        :disabled="!editor.can().chain().focus().redo().run()"
      >
        <UIcon
          name="i-material-symbols-redo"
          class="w-4 h-4 md:w-6 md:h-6"
          dynamic
        />
      </button>
      <button
        @click="setLink"
        type="button"
        :class="{ 'is-active': editor.isActive('link') }"
      >
        <UIcon name="i-heroicons-link-16-solid" />
      </button>

      <button
        type="button"
        @click="editor.chain().focus().unsetLink().run()"
        :disabled="!editor.isActive('link')"
      >
        <UIcon name="i-heroicons-link-slash-16-solid" />
      </button>
      <!-- <button type="button"
        class="relative z-20 bg-green-400/10"
        @click="enableAiSlide"
        :class="{ 'is-active': aiSlide }"
      >
        AI
      </button>
    --></div>
    <div
      ref="editorButtons"
      class="prose dark:prose-invert prose-sm sm:prose-base lg:prose-lg focus:outline-none min-w-full"
    >
      <editor-content
        class="bg-slate-200/10 dark:bg-slate-800/5"
        :editor="editor"
      />
    </div>
  </section>
</template>

<script setup>
import { useElementBounding } from "@vueuse/core";
import { Editor, EditorContent } from "@tiptap/vue-3";
import StarterKit from "@tiptap/starter-kit";
import TextStyle from "@tiptap/extension-text-style";
import { Color } from "@tiptap/extension-color";
import Image from "@tiptap/extension-image";
import Table from "@tiptap/extension-table";
import TableCell from "@tiptap/extension-table-cell";
import TableHeader from "@tiptap/extension-table-header";
import TableRow from "@tiptap/extension-table-row";
import Highlight from "@tiptap/extension-highlight";
import TextAlign from "@tiptap/extension-text-align";
import Link from "@tiptap/extension-link";

const props = defineProps({
  content: String,
  pid: Number | String,
});

const emit = defineEmits(["updateContent"]);

const editor = new Editor({
  extensions: [
    StarterKit,
    TextStyle,
    Color,
    Highlight.configure({
      multicolor: true,
    }),
    Table.configure({
      resizable: false,
    }),
    TextAlign.configure({
      types: ["heading", "paragraph"],
    }),
    TableRow,
    TableHeader,
    TableCell,
    Image.configure({
      inline: true,
      HTMLAttributes: {
        class: "my-custom-class",
      },
    }),
    Link.configure({
      autolink: true,
    }),
  ],
  content: props.content,
  onUpdate: () => {
    emit("updateContent", editor.getHTML());
  },
});

onBeforeUnmount(() => {
  editor.destroy();
});

const editorButtons = ref(null);
const { top: editorButtonsTop } = useElementBounding(editorButtons);

const setLink = () => {
  const selection = editor.state.selection;
  const selectedText = selection.empty
    ? ""
    : editor.state.doc.textBetween(selection.from, selection.to);

  const previousUrl = editor.getAttributes("link").href;
  const url = window.prompt("URL", selectedText || previousUrl);

  // cancelled
  if (url === null) {
    return;
  }

  // empty
  if (url === "") {
    editor.chain().focus().unsetLink().run();
    return;
  }

  // update link
  editor.chain().focus().setLink({ href: url }).run();
};
</script>

<style>
.editor .head button,
.table-slide-over button {
  padding: 1px 2px;
  border: 1px solid rgba(126, 126, 126, 0.069);
  border-radius: 0px;
  min-width: 30px;
  min-height: 30px;
  font-size: 17px;
  display: flex;
  justify-content: center;
  align-items: center;
  color: rgb(73, 73, 73);
  -webkit-filter: drop-shadow(1px 1px 2px rgba(0, 0, 0, 0.2));
  filter: drop-shadow(1px 1px 2px rgba(0, 0, 0, 0.2));
  cursor: pointer;
  border-radius: 5px;
  font-weight: normal;
}
.editor .head button:hover,
.table-slide-over button:hover {
  background: rgba(118, 118, 118, 0.155);
}
.dark .editor .head button,
.dark .table-slide-over button {
  color: rgb(200, 200, 200);
  -webkit-filter: drop-shadow(1px 1px 2px rgba(255, 255, 255, 0.2));
  filter: drop-shadow(1px 1px 2px rgba(255, 255, 255, 0.2));
}
.table-slide-over button {
  white-space: nowrap;
  width: 100%;
  text-align: left;
  display: block;
  padding: 2px 20px;
}
.editor .head button:disabled,
.table-slide-over button:disabled {
  opacity: 0.5;
}
.editor .head button.is-active,
.table-slide-over button.is-active {
  background: rgba(0, 0, 0, 0.664);
  color: white;
}
.dark .editor .head button.is-active,
.dark .table-slide-over button.is-active {
  background: rgba(252, 252, 252, 0.637);
  color: black;
}

.editor .tiptap {
  outline: none;
  width: 100%;
  min-height: 400px;
  max-height: 800px;
  overflow-y: auto;
}
/* width */
.editor .tiptap::-webkit-scrollbar {
  width: 3px;
}

/* Track */
.editor .tiptap::-webkit-scrollbar-track {
  background: #f1f1f1;
}

/* Handle */
.editor .tiptap::-webkit-scrollbar-thumb {
  background: #888;
}

/* Handle on hover */
.editor .tiptap::-webkit-scrollbar-thumb:hover {
  background: #555;
}
.prose th,
.prose td {
  border: 1px solid gray;
  padding: 5px;
  min-width: 120px;
}
.prose * {
  margin-top: 5px !important;
  margin-bottom: 5px !important;
}
.stickyButtons {
  position: sticky;
  top: 0;
  padding: 5px 0px;
  background-color: #f1f1f1;
  z-index: 5;
}
.dark .stickyButtons {
  background-color: #121928;
}
</style>
