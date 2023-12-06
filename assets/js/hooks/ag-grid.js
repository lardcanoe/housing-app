import agGrid from "../../vendor/ag-grid-community.min";

// https://www.ag-grid.com/javascript-data-grid/esm-packages/

export default {
    mounted() {
        this.pushEvent("load-data", {}, (reply, ref) => {
            const gridOptions = {
                defaultColDef: {
                    wrapText: true,
                    autoHeight: true,
                    filter: true
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
