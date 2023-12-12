import agGrid from "../../vendor/ag-grid-community.min";

// https://www.ag-grid.com/javascript-data-grid/esm-packages/

export default {
    mounted() {
        this.pushEvent("load-data", {}, (reply, ref) => {

            const selectElements = document.querySelectorAll('[name="table-settings-size"]');

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

            reply.columns.forEach(c => {
                if (c.field === 'actions') {
                    c.cellRenderer = function (params) {
                        return params.value.map((action) => {
                            return '<a href="' + action[1] + '" rel="noopener">' + action[0] + '</a>'
                        }).join('')
                    }
                    c.valueFormatter = (_) => ''
                } else if (c.field === 'email') {
                    c.cellRenderer = function (params) {
                        return '<a href="mailto:' + params.value + '" target="_blank" rel="noopener">' + params.value + '</a>'
                    }
                }
            });

            const gridOptions = {
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
                columnDefs: reply.columns,
                rowData: reply.data
            };

            // setup the grid after the page has finished loading
            const gridDiv = document.querySelector('#myGrid');
            const api = agGrid.createGrid(gridDiv, gridOptions);
        });
    },
};
