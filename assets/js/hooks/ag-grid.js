import agGrid from "../../vendor/ag-grid-community.min";

// https://www.ag-grid.com/javascript-data-grid/esm-packages/

export default {
    mounted() {
        this.pushEvent("load-data", {}, (reply, ref) => {
            const columnDefs = [
                { field: "make" },
                { field: "model" },
                { field: "price" }
            ];

            // specify the data
            const rowData = [
                { make: "Toyota", model: `Corolla`, price: 35000 },
                { make: "Ford", model: "Mondeo", price: 32000 },
                { make: "Porsche", model: "Boxter", price: 72000 }
            ];

            // let the grid know which columns and what data to use
            const gridOptions = {
                defaultColDef: {
                    wrapText: true,
                    autoHeight: true,
                    filter: true
                },
                columnDefs: columnDefs,
                rowData: rowData
            };

            // setup the grid after the page has finished loading
            const gridDiv = document.querySelector('#myGrid');
            const api = agGrid.createGrid(gridDiv, gridOptions);
        });
    },
};
