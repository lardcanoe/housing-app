class DraftStatusValueRenderer {
    eGui;

    init(params) {
        this.eGui = document.createElement('div');
        this.eGui.classList.add('w-full', 'inline-block', 'align-middle', 'text-center');
        switch (params.value) {
            case 'draft':
                this.eGui.innerHTML = `<span class="bg-yellow-100 text-yellow-800 text-xs font-medium rounded py-1.5 px-2 dark:bg-yellow-900 dark:text-yellow-300">Draft</span>`;
                break;
            case 'started':
                this.eGui.innerHTML = `<span class="bg-yellow-100 text-yellow-800 text-xs font-medium rounded py-1.5 px-2 dark:bg-yellow-900 dark:text-yellow-300">Started</span>`;
                break;
            case 'approved':
                this.eGui.innerHTML = `<span class="bg-green-100 text-green-800 text-xs font-medium rounded py-1.5 px-2 dark:bg-green-900 dark:text-green-300">Approved</span>`;
                break;
            case 'completed':
                this.eGui.innerHTML = `<span class="bg-green-100 text-green-800 text-xs font-medium rounded py-1.5 px-2 dark:bg-green-900 dark:text-green-300">Completed</span>`;
                break;
            case 'archived':
                this.eGui.innerHTML = `<span class="bg-gray-100 text-gray-800 text-xs font-medium rounded py-1.5 px-2 dark:bg-gray-700 dark:text-gray-300">Archived</span>`;
                break;
            case 'rejected':
                this.eGui.innerHTML = `<span class="bg-red-100 text-red-800 text-xs font-medium rounded py-1.5 px-2 dark:bg-red-700 dark:text-red-300">Rejected</span>`;
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
