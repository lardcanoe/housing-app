import Sortable from "../../vendor/sortable.min.js"

export default {
    mounted() {
        // https://github.com/SortableJS/Sortable?tab=readme-ov-file#options
        this.sorter = new Sortable(this.el, {
            animation: 150,
            delay: 100,
            dragClass: "drag-item",
            ghostClass: "drag-ghost",
            draggable: ".draggable",
            forceFallback: true,
            handle: ".drag-handle",
            onEnd: e => {
                let params = { old: e.oldIndex, new: e.newIndex, ...e.item.dataset }
                this.pushEventTo(this.el, "reposition", params)
            }
        })
    },
    destroy() {
        if (this.sorter) {
            this.sorter.destroy()
        }
    }
}
