import React from 'react';
import { useState, StrictMode } from 'react';
import { createRoot } from "react-dom/client";
import { defaultValidator, QueryBuilder } from 'react-querybuilder';

export const QueryBuilderComponent = ({ initialQuery, fields, queryChange }) => {
    const [query, setQuery] = useState(initialQuery);

    // UNCOMMENT to see how noisy we are
    // console.log('Rendering QueryBuilderComponent with', query);

    // useEffect(() => {
    //     console.log('Query updated:', query);
    // }, [query]);

    return (
        <QueryBuilder
            debugMode={true}
            fields={fields}
            query={query}
            validator={defaultValidator}
            controlClassnames={{ queryBuilder: 'queryBuilder-branches' }}
            onQueryChange={(q) => { setQuery(q); queryChange(q) }} />
    );
};

export function mount(rootElement, opts) {
    const root = createRoot(rootElement)
    root.render(
        <StrictMode>
            <QueryBuilderComponent {...opts} />
        </StrictMode>
    )
    return root;
}
