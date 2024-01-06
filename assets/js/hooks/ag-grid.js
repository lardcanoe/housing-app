import { ActionsValueRenderer } from '../ag-grid/actions-renderer';
import { BooleanCheckmarkValueRenderer } from '../ag-grid/boolean-renderer';
import { DraftStatusValueRenderer } from '../ag-grid/status-renderer';
import { LinkValueRenderer } from '../ag-grid/link-renderer';

// https://www.ag-grid.com/javascript-data-grid/esm-packages/

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

        this.gridOptions = {
            defaultColDef: {
                wrapText: true,
                autoHeight: true,
                filter: true,
                floatingFilter: true,
                minWidth: 160,
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
                booleanCheckmark: BooleanCheckmarkValueRenderer,
                draftStatus: DraftStatusValueRenderer,
                link: LinkValueRenderer
            },
            autoSizeStrategy: {
                type: 'fitGridWidth',
            },
            rowSelection: 'multiple',
            suppressRowClickSelection: true,
            columnDefs: [],
            rowData: []
        };

        this.handleViewClick = (e) => { this.pushEvent("view-row", { id: e.id }) };
        this.handleEditClick = (e) => { this.pushEvent("edit-row", { id: e.id }) };
        this.handleLinkClick = (e) => { this.pushEvent("redirect", { url: e.url }) };
        this.handleRefreshData = (e) => {
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
                this.addTableSettingListeners(this.gridInstance);

                // Ideally do this:
                // this.gridInstance.updateGridOptions({ columnDefs: reply.columns, rowData: reply.data });
            });
        };

        window.addEventListener("view:clicked", this.handleViewClick);
        window.addEventListener("edit:clicked", this.handleEditClick);
        window.addEventListener("link:clicked", this.handleLinkClick);
        window.addEventListener("phx:page-loading-stop", this.handleRefreshData)
    },

    // TODO: This is broken when switching page params
    addTableSettingListeners(gridInstance) {
        selectElements = document.querySelectorAll('[name="table-settings-show-ids"]');
        if (selectElements) {
            selectElements.forEach((s) => {
                // Trick to remove previous listeners
                var newButton = s.cloneNode(true);
                s.parentNode.replaceChild(newButton, s);

                newButton.addEventListener("change", (event) => {
                    gridInstance.applyColumnState({
                        state: [
                            { colId: 'id', hide: !event.target.checked }
                        ],
                    });
                })
            });
        }
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
        window.removeEventListener("link:clicked", this.handleLinkClick);
        window.removeEventListener("phx:page-loading-stop", this.handleRefreshData)

        if (this.gridInstance) {
            this.gridInstance.destroy();
        }
    }
};
