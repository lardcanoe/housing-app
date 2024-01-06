import React from 'react';
import { useState } from 'react';
import { defaultValidator, QueryBuilder } from 'react-querybuilder';

export const QueryBuilderComponent = ({ initialQuery, fields, queryChange }) => {
    const [query, setQuery] = useState(initialQuery);

    return (
        <QueryBuilder
            fields={fields}
            query={query}
            validator={defaultValidator}
            controlClassnames={{ queryBuilder: 'queryBuilder-branches' }}
            onQueryChange={(q) => { setQuery(q); queryChange(q) }} />
    );
};
