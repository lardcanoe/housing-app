import React, { ChangeEvent, FocusEvent, FocusEventHandler, useCallback } from "react";
import { EnumOptionsType, WidgetProps } from "@rjsf/utils";
import Select, { MultiValue, SingleValue } from 'react-select';
import { selectStyles } from "../styles/select.styles";
import { Option } from "../../../interfaces/Option.interface";


/** The `SelectWidget` is a widget for rendering dropdowns.
 *  It is typically used with string properties constrained with enum options.
 *
 * @param props - The `WidgetProps` for this component
 */
function SelectWidget<T = any, F = any>({
  schema,
  id,
  options,
  value,
  disabled,
  readonly,
  multiple = false,
  autofocus = false,
  onBlur,
  onFocus,
  onChange
}: WidgetProps<T, F>) {
  const { enumOptions, enumDisabled } = options;
  const emptyValue = multiple ? [] : "";

  // TODO: Fix processSelectValue, see https://newreleases.io/project/github/rjsf-team/react-jsonschema-form/release/v5.0.0

  // const handleFocus:FocusEventHandler<HTMLInputElement> = useCallback(
  //   () => onFocus(id, processSelectValue(schema, value, options)),
  //   [onFocus, id, schema, multiple, options]
  // );

  // const handleBlur:FocusEventHandler<HTMLInputElement> = useCallback(
  //   () =>  onBlur(id, processSelectValue(schema, value, options)),
  //   [onBlur, id, schema, multiple, options]
  // );

  // const handleChange = useCallback(
  //   (event: MultiValue<EnumOptionsType> | SingleValue<EnumOptionsType>) => {
  //     let newValue: string | string[] | undefined;
  //     if (multiple && Array.isArray(event)) {
  //       newValue = event.map((option) => option.value);
  //     } else {
  //       const singleEvent = event as SingleValue<EnumOptionsType>
  //       newValue = singleEvent?.value;
  //     }
  //     return onChange(processSelectValue(schema, newValue, options));
  //   },
  //   [onChange, schema, multiple, options]
  // );

  const getEnumObjectFromVal = (val: string) => {
    return enumOptions?.find((option: Option) => option.value === val) || { label: "", value: "" }
  }
  const getSelectValue = () => {
    let selectValue: Option | Option[] | undefined = undefined;
    if (multiple && Array.isArray(value)) {
      selectValue = value.map(val => getEnumObjectFromVal(val.toString()));
    } else if (value) {
      selectValue = getEnumObjectFromVal(value.toString());
    }
    return selectValue;
  }

  return (
    <Select
      id={id}
      instanceId={id}
      isMulti={multiple}
      value={getSelectValue()}
      isDisabled={disabled || readonly}
      autoFocus={autofocus}
      options={enumOptions}
      // onChange={handleChange}
      // onBlur={handleBlur}
      // onFocus={handleFocus}
      styles={selectStyles}
    />
  );
}

export default SelectWidget;
