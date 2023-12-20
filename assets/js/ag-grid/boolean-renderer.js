class BooleanCheckmarkValueRenderer {
    eGui;

    init(params) {
        this.eGui = document.createElement('div');
        if (params.value === true || params.value === "true") {
            this.eGui.innerHTML = `<span class="hero-check-solid w-4 h-4 mr-2 text-gray-900 dark:text-white"></span>`;
        }
    }

    getGui() {
        return this.eGui;
    }

    refresh(params) {
        return true;
    }

    destroy() { }
}

export { BooleanCheckmarkValueRenderer }
