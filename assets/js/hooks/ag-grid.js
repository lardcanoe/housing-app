import { ActionsValueRenderer } from '../ag-grid/actions-renderer';
import { BooleanCheckmarkValueRenderer } from '../ag-grid/boolean-renderer';
import { DraftStatusValueRenderer } from '../ag-grid/status-renderer';
import { LinkValueRenderer } from '../ag-grid/link-renderer';

// https://www.ag-grid.com/javascript-data-grid/esm-packages/

export default {
    mounted() {
        let selectElements = document.querySelectorAll('[name="table-settings-size"]');
        this.selected_ids = [];

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

            // https://www.ag-grid.com/javascript-data-grid/filter-quick/#quick-filter-cache
            cacheQuickFilter: true,
            includeHiddenColumnsInQuickFilter: true,

            onFilterChanged: (e) => {
                if (this.el.dataset.filterChanges == "true") {
                    this.pushEventTo(this.el, "filter-changed", { filter: this.gridInstance.getFilterModel() })
                }
            },

            onSelectionChanged: (e) => {
                const ids = this.gridInstance.getSelectedRows().map(row => row.id)
                const arraysAreEqual = ids.length === this.selected_ids.length && ids.every((value, index) => value === this.selected_ids[index]);
                if (arraysAreEqual) {
                    return;
                }

                this.pushEventTo(this.el, "selection-changed", { ids: ids });
                this.selected_ids = ids;
            },

            // FUTURE:
            // sideBar: 'filters',
            // onGridReady: (params) => {
            //     params.api.getToolPanelInstance('filters').expandFilters();
            // },

            columnDefs: [],
            rowData: []
        };

        this.handleViewClick = (e) => { this.pushEventTo(this.el, "view-row", { id: e.id }) };
        this.handleEditClick = (e) => { this.pushEventTo(this.el, "edit-row", { id: e.id }) };
        this.handleCopyClick = (e) => { this.pushEventTo(this.el, "copy-row", { id: e.id }) };
        this.handleLinkClick = (e) => { this.pushEventTo(this.el, "redirect", { url: e.url }) };
        this.handleRefreshData = (_e) => {
            this.pushEventTo(this.el, "load-data", {}, (reply, ref) => {
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
                this.selected_ids = [];

                let quickfilter = document.getElementById('datagrid-quickfilter');
                if (quickfilter) {
                    quickfilter.oninput = () => {
                        this.gridInstance.setGridOption('quickFilterText', quickfilter.value);
                    }
                }

                if (reply.filter) {
                    this.gridInstance.setFilterModel(reply.filter);
                }

                // Ideally do this:
                // this.gridInstance.updateGridOptions({ columnDefs: reply.columns, rowData: reply.data });
            });
        };
        this.handleUnselect = (_e) => {
            this.gridInstance.deselectAll();
            this.selected_ids = [];
        };

        window.addEventListener("view:clicked", this.handleViewClick);
        window.addEventListener("edit:clicked", this.handleEditClick);
        window.addEventListener("copy:clicked", this.handleCopyClick);
        window.addEventListener("link:clicked", this.handleLinkClick);
        window.addEventListener("phx:page-loading-stop", this.handleRefreshData)
        window.addEventListener("phx:ag-grid:refresh", this.handleRefreshData)
        window.addEventListener("phx:ag-grid:unselect", this.handleUnselect)
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

    destroyed() {
        if (this.gridInstance) {
            this.gridInstance.destroy();
            this.gridInstance = null;
        }

        window.removeEventListener("view:clicked", this.handleViewClick);
        window.removeEventListener("edit:clicked", this.handleEditClick);
        window.removeEventListener("copy:clicked", this.handleCopyClick);
        window.removeEventListener("link:clicked", this.handleLinkClick);
        window.removeEventListener("phx:page-loading-stop", this.handleRefreshData)
        window.removeEventListener("phx:ag-grid:refresh", this.handleRefreshData)
        window.removeEventListener("phx:ag-grid:unselect", this.handleUnselect)
    }
};
