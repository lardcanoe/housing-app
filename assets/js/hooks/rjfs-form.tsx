import React from "react";
import { createRoot } from 'react-dom/client';
import { RJSFSchema } from '@rjsf/utils';
import validator from '@rjsf/validator-ajv8';
import { withTheme } from '@rjsf/core';
import { rjsfDaisyUiTheme } from '../forms/rjsf-daisyui-theme/rjsfDaisyUiTheme';

const ThemedForm = withTheme(rjsfDaisyUiTheme);

const schema: RJSFSchema = {
    "title": "A registration form",
    "description": "A simple form example.",
    "type": "object",
    "required": [
        "firstName",
        "lastName"
    ],
    "properties": {
        "firstName": {
            "type": "string",
            "title": "First name",
            "default": "Chuck"
        },
        "lastName": {
            "type": "string",
            "title": "Last name"
        },
        "age": {
            "type": "integer",
            "title": "Age"
        },
        "bio": {
            "type": "string",
            "title": "Bio"
        },
        "password": {
            "type": "string",
            "title": "Password",
            "minLength": 3
        },
        "telephone": {
            "type": "string",
            "title": "Telephone",
            "minLength": 10
        }
    }
};

const log = (type) => console.log.bind(console, type);

export function mount(id, opts) {
    const container = document.getElementById(id);
    const root = createRoot(container!);

    root.render(<ThemedForm schema={schema}
        validator={validator}
        formData={{}}
        onChange={(e) => console.info(e.formData)}
        onSubmit={log('submitted')}
        onError={log('errors')} />);

    return () => {
        root.unmount();
    };
}
