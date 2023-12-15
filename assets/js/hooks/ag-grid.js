import agGrid from "../../vendor/ag-grid-community.min";

// https://www.ag-grid.com/javascript-data-grid/esm-packages/

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
            return '<a class="ml-2" name="' + action[0] + '">' + action[0] + '</a>'
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

export default {
    mounted() {
        let selectElements = document.querySelectorAll('[name="table-settings-size"]');

        // https://www.ag-grid.com/javascript-data-grid/global-style-customisation-compactness/

        if (selectElements) {
            selectElements.forEach((s) => s.addEventListener("change", (event) => {
                const selectedOption = event.target.value;
                const sizes = ['large', 'normal', 'compact'];

                let el = document.querySelector('.ag-theme-quartz');
                if (el) {
                    sizes.forEach((size) => el.classList.toggle(size, size === selectedOption));
                }

                el = document.querySelector('.ag-theme-quartz-dark');
                if (el) {
                    sizes.forEach((size) => el.classList.toggle(size, size === selectedOption));
                }
            }));
        }

        selectElements = document.querySelectorAll('[name="table-settings-show-ids"]');
        if (selectElements) {
            selectElements.forEach((s) => s.addEventListener("change", (event) => {
                this.gridInstance.applyColumnState({
                    state: [
                        { colId: 'id', hide: !event.target.checked }
                    ],
                });
            }));
        }

        this.gridOptions = {
            defaultColDef: {
                wrapText: true,
                autoHeight: true,
                filter: true,
                floatingFilter: true
            },
            columnTypes: {
                numberColumn: { width: 130, filter: 'agNumberColumnFilter' },
                nonEditableColumn: { editable: false },
                dateColumn: {
                    // specify we want to use the date filter
                    filter: 'agDateColumnFilter'
                }
            },
            components: {
                booleanCheckmark: BooleanCheckmarkValueRenderer
            },
            autoSizeStrategy: {
                type: 'fitGridWidth',
            },
            rowSelection: 'multiple',
            suppressRowClickSelection: true,
            columnDefs: [],
            rowData: []
        };

        this.setColorTheme();

        this.gridInstance = agGrid.createGrid(this.el, this.gridOptions);

        this.handleViewClick = (e) => { this.pushEvent("view-row", { id: e.id }) };
        this.handleEditClick = (e) => { this.pushEvent("edit-row", { id: e.id }) };

        window.addEventListener("view:clicked", this.handleViewClick);
        window.addEventListener("edit:clicked", this.handleEditClick);

        this.pushEvent("load-data", {}, (reply, ref) => {
            reply.columns.forEach(c => {
                if (c.field === 'actions') {
                    c.cellRenderer = ActionsValueRenderer
                    c.valueFormatter = (_) => ''
                } else if (c.field === 'email') {
                    c.cellRenderer = function (params) {
                        return '<a href="mailto:' + params.value + '" target="_blank">' + params.value + '</a>'
                    }
                }
            });

            // FUTURE: There is some bug that forces us to recreate instead of just update
            this.setColorTheme();
            this.gridOptions.columnDefs = reply.columns
            this.gridOptions.rowData = reply.data
            this.gridInstance = agGrid.createGrid(this.el, this.gridOptions);

            // Ideally do this:
            // this.gridInstance.updateGridOptions({ columnDefs: reply.columns, rowData: reply.data });
        });
    },

    setColorTheme() {
        if (localStorage.getItem('color-theme')) {
            if (localStorage.getItem('color-theme') === 'light') {
                this.el.classList.add('ag-theme-quartz');
            } else {
                this.el.classList.add('ag-theme-quartz-dark');

            }
        } else if (document.documentElement.classList.contains('dark')) {
            this.el.classList.add('ag-theme-quartz-dark');
        } else {
            this.el.classList.add('ag-theme-quartz');
        }
    },

    destroy() {
        window.removeEventListener("view:clicked", this.handleViewClick);
        window.removeEventListener("edit:clicked", this.handleEditClick);

        if (this.gridInstance) {
            this.gridInstance.destroy();
        }
    }
};
