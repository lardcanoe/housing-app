import agGrid from "../../vendor/ag-grid-community.min";

// https://www.ag-grid.com/javascript-data-grid/esm-packages/

class ActionsValueRenderer {
    eGui;
    eButton;
    eventListener;

    // gets called once before the renderer is used
    init(params) {
        this.eGui = document.createElement('div');
        this.eGui.innerHTML = params.value.map((action) => {
            if (action[0] === 'View') {
                return '<a class="ml-2" name="' + action[0] + '">' + action[0] + '</a>'
            }
            return '<a class="ml-2" name="' + action[0] + '" href="' + action[1] + '">' + action[0] + '</a>'
        }).join('');

        this.eButton = this.eGui.querySelector('a[name=\'View\']');

        if (this.eButton) {
            this.eventListener = () => {

                const event = new Event('row:clicked');
                event.id = params.data.id
                window.dispatchEvent(event);

                let el = document.querySelector('#drawer-right-parent');
                if (el) {
                    el.classList.remove('hidden');
                }

                return false;
            };

            this.eButton.addEventListener('click', this.eventListener);
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
            this.eButton.removeEventListener('click', this.eventListener);
        }
    }
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
            autoSizeStrategy: {
                type: 'fitGridWidth',
            },
            rowSelection: 'multiple',
            suppressRowClickSelection: true,
            columnDefs: [],
            rowData: []
        };

        // setup the grid after the page has finished loading
        const gridDiv = document.querySelector('#ag-data-grid');
        this.gridInstance = agGrid.createGrid(gridDiv, this.gridOptions);

        window.addEventListener("row:clicked", (e) => {
            this.pushEvent("view-row", { id: e.id });
        });

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
            const gridDiv = document.querySelector('#ag-data-grid');
            this.gridOptions.columnDefs = reply.columns
            this.gridOptions.rowData = reply.data
            this.gridInstance = agGrid.createGrid(gridDiv, this.gridOptions);

            // Ideally do this:
            // this.gridInstance.updateGridOptions({ columnDefs: reply.columns, rowData: reply.data });
        });
    },

    destroy() {
        if (this.gridInstance) {
            this.gridInstance.destroy();
        }
    }
};
