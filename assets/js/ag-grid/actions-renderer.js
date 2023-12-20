class ActionsValueRenderer {
    eGui;
    vButton;
    vListener;
    eButton;
    eventListener;

    // gets called once before the renderer is used
    init(params) {
        this.eGui = document.createElement('div');
        this.eGui.innerHTML = params.value.map((action) => {
            return '<a class="ml-2" style="cursor: pointer" name="' + action[0] + '">' + action[0] + '</a>'
        }).join('');

        this.eButton = this.eGui.querySelector('a[name=\'Edit\']');

        if (this.eButton) {
            this.eListener = () => {
                const event = new Event('edit:clicked');
                event.id = params.data.id
                window.dispatchEvent(event);
                return false;
            };

            this.eButton.addEventListener('click', this.eListener);
        }

        this.vButton = this.eGui.querySelector('a[name=\'View\']');

        if (this.vButton) {
            this.vListener = () => {
                const event = new Event('view:clicked');
                event.id = params.data.id
                window.dispatchEvent(event);

                let el = document.querySelector('#drawer-right-parent');
                if (el) {
                    el.classList.remove('hidden');
                }

                return false;
            };

            this.vButton.addEventListener('click', this.vListener);
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
        if (this.vButton) {
            this.vButton.removeEventListener('click', this.vListener);
        }
    }
}

export { ActionsValueRenderer }
