import React, { FocusEvent, useCallback } from "react";
import { WidgetProps } from "@rjsf/utils";

/** The `RadioWidget` is a widget for rendering a radio group.
 *  It is typically used with a string property constrained with enum options.
 *
 * @param props - The `WidgetProps` for this component
 */
function RadioWidget<T = any, F = any>({
  options,
  value,
  required,
  disabled,
  readonly,
  autofocus = false,
  onBlur,
  onFocus,
  onChange,
  id,
}: WidgetProps<T, F>) {
  // Generating a unique field name to identify this set of radio buttons
  const name = Math.random().toString();
  const { enumOptions, enumDisabled, inline } = options;
  // checked={checked} has been moved above name={name}, As mentioned in #349;
  // this is a temporary fix for radio button rendering bug in React, facebook/react#7630.

  const handleBlur = useCallback(
    (event: FocusEvent<HTMLInputElement>) => onBlur(id, event.target.value),
    [onBlur, id]
  );

  const handleFocus = useCallback(
    (event: FocusEvent<HTMLInputElement>) => onFocus(id, event.target.value),
    [onFocus, id]
  );

  return (
    <div className={`flex field-radio-group ${inline ? 'flex-row gap-2' : 'flex-col'}`} id={id}>
      {Array.isArray(enumOptions) &&
        enumOptions.map((option, i) => {
          const checked = option.value === value;
          const itemDisabled =
            enumDisabled && enumDisabled.indexOf(option.value) != -1;
          const disabledCls =
            disabled || itemDisabled || readonly ? "disabled" : "";

          const handleChange = () => onChange(option.value);

          const radio = (
            <>
              <input
                type="radio"
                className="radio radio-secondary"
                id={`${id}_${i}`}
                checked={checked}
                name={id}
                required={required}
                value={option.value}
                disabled={disabled || itemDisabled || readonly}
                autoFocus={autofocus && i === 0}
                onChange={handleChange}
                onBlur={handleBlur}
                onFocus={handleFocus}
              />
              <span className="label-text">{option.label}</span>
            </>
          );

          return (
            <label key={i} className={`label justify-start gap-2 ${disabledCls}`}>
              {radio}
            </label>
          )
        })}
    </div>
  );
}

export default RadioWidget;
