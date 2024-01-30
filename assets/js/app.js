// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import { Socket } from "phoenix"
import { LiveSocket } from "phoenix_live_view"
import topbar from "../vendor/topbar"
import "flowbite/dist/flowbite.phoenix.min.js"
import AgGrid from "./hooks/ag-grid"
import QueryBuilder from "./hooks/query-builder"
import JsonViewHook from "./hooks/json_view"
import JsonEditorHook from "./hooks/json_editor"
import JsonEditorSourceHook from "./hooks/json_editor_source"
import SortableHook from "./hooks/sortable_list"
import './darkmode'

window.json_editors = {};

// FUTURE: Load hooks dynamically, https://aswinmohan.me/pagewise-js-liveview
let Hooks = {}
Hooks.AgGrid = AgGrid
Hooks.QueryBuilder = QueryBuilder
Hooks.JsonEditor = JsonEditorHook
Hooks.JsonEditorSource = JsonEditorSourceHook
Hooks.JsonView = JsonViewHook
Hooks.SortableList = SortableHook

let localeCache = {
    locale: Intl.NumberFormat().resolvedOptions().locale,
    timezone: Intl.DateTimeFormat().resolvedOptions().timeZone,
    timezone_offset: -(new Date().getTimezoneOffset() / 60)
}

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {
    params: {
        _csrf_token: csrfToken,
        ...localeCache
    },
    hooks: Hooks
})

// Show progress bar on live navigation and form submits
topbar.config({ barColors: { 0: "#29d" }, shadowColor: "rgba(0, 0, 0, .3)" })
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())
window.addEventListener("phx:js-exec", ({ detail }) => {
    document.querySelectorAll(detail.to).forEach(el => {
        liveSocket.execJS(el, el.getAttribute(detail.attr))
    })
})

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

