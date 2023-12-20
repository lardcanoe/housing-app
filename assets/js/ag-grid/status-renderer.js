class DraftStatusValueRenderer {
    eGui;

    init(params) {
        this.eGui = document.createElement('div');
        this.eGui.classList.add('w-full', 'inline-block', 'align-middle', 'text-center');
        switch (params.value) {
            case 'draft':
                this.eGui.innerHTML = `<span class="bg-yellow-100 text-yellow-800 text-xs font-medium rounded py-1.5 px-2 dark:bg-yellow-900 dark:text-yellow-300">Draft</span>`;
                break;
            case 'approved':
                this.eGui.innerHTML = `<span class="bg-green-100 text-green-800 text-xs font-medium rounded py-1.5 px-2 dark:bg-green-900 dark:text-green-300">Approved</span>`;
                break;
            case 'archived':
                this.eGui.innerHTML = `<span class="bg-gray-100 text-gray-800 text-xs font-medium rounded py-1.5 px-2 dark:bg-gray-700 dark:text-gray-300">Archived</span>`;
                break;
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

export { DraftStatusValueRenderer }
