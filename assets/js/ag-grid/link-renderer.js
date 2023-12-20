class LinkValueRenderer {
    eGui;
    eButton;
    eListener;

    // gets called once before the renderer is used
    init(params) {
        this.eGui = document.createElement('div');
        this.eGui.innerHTML = '<a style="cursor: pointer">' + params.value + '</a>';

        this.eButton = this.eGui.querySelector('a');
        const url = params.data[`${params.column.colId}_link`];

        if (this.eButton) {
            this.eListener = () => {
                const event = new Event('link:clicked');
                event.url = url
                window.dispatchEvent(event);
                return false;
            };

            this.eButton.addEventListener('click', this.eListener);
        }
    }

    getGui() {
        return this.eGui;
    }

    refresh(params) {
        return true;
    }

    // gets called when the cell is removed from the grid
    destroy() {
        if (this.eButton) {
            this.eButton.removeEventListener('click', this.eListener);
        }
    }
}

export { LinkValueRenderer }
