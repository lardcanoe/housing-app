import Sortable from "../../vendor/sortable.min.js"

export default {
    mounted() {
        this.sorter = new Sortable(this.el, {
            animation: 150,
            delay: 100,
            dragClass: "drag-item",
            ghostClass: "drag-ghost",
            forceFallback: true,
            onEnd: e => {
                console.log(e)
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
