import agGrid from "../../vendor/ag-grid-community.min";

// https://www.ag-grid.com/javascript-data-grid/esm-packages/

export default {
    mounted() {
        this.pushEvent("load-data", {}, (reply, ref) => {

            reply.columns.forEach(c => {
                if (c.link) {
                    c.cellRenderer = function (params) {
                        // target="_blank"
                        return '<a href="' + params.value + '" rel="noopener">' + c.link + '</a>'
                    }
                } else if (c.email) {
                    c.cellRenderer = function (params) {
                        return '<a href="mailto:' + params.value + '" target="_blank" rel="noopener">' + params.value + '</a>'
                    }
                }
            });

            const gridOptions = {
                defaultColDef: {
                    wrapText: true,
                    autoHeight: true,
                    filter: true
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
