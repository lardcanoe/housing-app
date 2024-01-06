import React from 'react';
import { createRoot } from 'react-dom/client';
import { QueryBuilder } from 'react-querybuilder';

const fields = [
    { name: 'firstName', label: 'First Name' },
    { name: 'lastName', label: 'Last Name' },
];

export default {
    mounted() {
        this.target = this.el.dataset.phoenixTarget;

        createRoot(this.el).render(
            React.createElement(
                QueryBuilder,
                {
                    fields: fields,
                    onQueryChange: (q) => this.queryChange(q)
                }
            )
        )
    },
    queryChange(q) {
        this.pushEventTo(this.target, 'query-changed', { q });
    },
};
